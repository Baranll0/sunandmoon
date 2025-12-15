import 'dart:math';
import '../constants/debug_mode.dart';

import '../constants/game_constants.dart';
import '../domain/generation_report.dart';
import '../domain/generation_failure_reason.dart';
import '../domain/generation_exception.dart';
import 'puzzle_generator.dart';
import 'human_logic_solver.dart';
import 'grid_validator.dart';
import 'grid_helper.dart';
import '../domain/mechanic_flag.dart';
import '../services/mechanics_manager.dart';
import 'generation_result.dart';

/// Pattern analysis result
class _RowPattern {
  final bool hasThreeFilled;
  final bool hasTwoSameWithTwoEmpty;
  
  _RowPattern({
    required this.hasThreeFilled,
    required this.hasTwoSameWithTwoEmpty,
  });
}

/// Level Generator - Creates puzzles with specific difficulty scores
/// Maps to linear Chapter progression with controlled difficulty curves
class LevelGenerator {
  final Random _random;

  LevelGenerator({int? seed}) : _random = Random(seed ?? DateTime.now().millisecondsSinceEpoch);

  /// Generate a puzzle for a specific chapter and level
  /// Returns a puzzle with difficulty score matching the target
  /// Includes GenerationReport for quality gates
  /// 
  /// Throws [GenerationException] if unable to generate after all retry strategies
  GeneratedLevel generateLevel(int chapter, int level, {GenerationReport? outReport}) {
    final levelId = _calculateLevelId(chapter, level);
    final gridSize = _getGridSizeForLevelId(levelId);
    
    // Get mechanics plan (NEW: Master Spec)
    final mechanicsPlan = MechanicsManager.getMechanicsFor(chapter, level);
    
    var (targetMin, targetMax) = _getTargetDifficultyRange(chapter, levelId);
    
    // Adjust difficulty based on mechanics (Master Spec)
    if (mechanicsPlan.mechanics.contains(MechanicFlag.moveLimit)) {
      targetMin = (targetMin - 0.5).clamp(0.0, 10.0);
      targetMax = (targetMax - 0.5).clamp(0.0, 10.0);
    }
    
    // Progressive attempt budgets
    final attemptBudgets = [50, 100, 200];
    final List<GenerationFailureReason> allFailures = [];
    
    // Phase 1: Standard attempts with strict quality gates
    for (final budget in attemptBudgets) {
      final result = _tryGenerateWithBudget(
        chapter,
        level,
        levelId,
        gridSize,
        targetMin,
        targetMax,
        budget,
        strictQualityGates: true,
        mechanicsPlan: mechanicsPlan,
      );
      
      if (result.success) {
        if (kDebugMode) {
          print(result.report!.getSummary());
        }
        return result.level!;
      }
      
      allFailures.addAll(result.failures);
      
      // If we exhausted this budget, try next phase
      if (result.failures.length >= budget) {
        break;
      }
    }
    
    // Phase 2: Controlled degradation - relax targets progressively
    var relaxedEarlyForcedRatio = 0.80; // Start with original threshold
    var relaxedDifficultyRange = 0.5; // Original range width
    
    for (int degradationStep = 0; degradationStep < 3; degradationStep++) {
      // Relax difficulty range slightly
      final rangeWidth = targetMax - targetMin;
      final relaxedMin = (targetMin - relaxedDifficultyRange).clamp(0.0, 10.0);
      final relaxedMax = (targetMax + relaxedDifficultyRange).clamp(0.0, 10.0);
      
      // Relax earlyForcedRatio (but keep maxChain strict)
      relaxedEarlyForcedRatio += 0.05;
      
      final result = _tryGenerateWithBudget(
        chapter,
        level,
        levelId,
        gridSize,
        relaxedMin,
        relaxedMax,
        50, // Smaller budget for relaxed attempts
        strictQualityGates: false,
        relaxedEarlyForcedRatio: relaxedEarlyForcedRatio,
        mechanicsPlan: mechanicsPlan,
      );
      
      if (result.success) {
        if (kDebugMode) {
          print('⚠️  Generated with relaxed constraints (step $degradationStep)');
          print(result.report!.getSummary());
        }
        return result.level!;
      }
      
      allFailures.addAll(result.failures);
      relaxedDifficultyRange += 0.3; // Increase relaxation
    }
    
    // Phase 3: Generate new solution board and restart
    for (int restart = 0; restart < 3; restart++) {
      final result = _tryGenerateWithBudget(
        chapter,
        level,
        levelId,
        gridSize,
        targetMin,
        targetMax,
        50,
        strictQualityGates: false,
        relaxedEarlyForcedRatio: 0.90, // Very relaxed
        newSolutionSeed: _calculateSeed(chapter, level) + 9999 + restart,
        mechanicsPlan: mechanicsPlan,
      );
      
      if (result.success) {
        if (kDebugMode) {
          print('⚠️  Generated with new solution board (restart $restart)');
        }
        return result.level!;
      }
      
      allFailures.addAll(result.failures);
    }
    
    // Phase 4: Ultimate failure - throw error
    final failureSummary = GenerationFailureSummary.fromFailures(allFailures);
    if (kDebugMode) {
      print('❌ GENERATION FAILED for Chapter $chapter, Level $level');
      print(failureSummary.getSummary());
    }
    
    throw GenerationException(
      'Failed to generate puzzle for Chapter $chapter, Level $level after all retry strategies',
      reason: GenerationFailureReason.maxAttemptsExceeded,
      summary: failureSummary,
    );
  }
  
  /// Try to generate with a specific budget and constraints
  GenerationResult _tryGenerateWithBudget(
    int chapter,
    int level,
    int levelId,
    int gridSize,
    double targetMin,
    double targetMax,
    int budget,
    {
    required bool strictQualityGates,
    double relaxedEarlyForcedRatio = 0.80,
    int? newSolutionSeed,
    MechanicsPlan? mechanicsPlan,
  }) {
    final failures = <GenerationFailureReason>[];
    final baseSeed = newSolutionSeed ?? _calculateSeed(chapter, level);
    
    for (int attempt = 0; attempt < budget; attempt++) {
      // Generate full solution
      final bool useRegions = mechanicsPlan?.mechanics.contains(MechanicFlag.regions) ?? false;
      final generator = PuzzleGenerator(seed: baseSeed + attempt, useRegions: useRegions);
      final fullSolution = generator.generateCompleteBoard(gridSize);
      
      // Dig holes to create puzzle
      final puzzle = _digHolesWithDifficulty(
        fullSolution,
        gridSize,
        (targetMin + targetMax) / 2,
        chapter,
      );
      
      // CRITICAL: If digging failed to meet strict constraints (like no full line), retry
      if (puzzle == null) {
        failures.add(GenerationFailureReason.qualityGatesFailed);
        continue;
      }
      
      // CRITICAL MASTER SPEC GATES (Hard Verification)
      
      // Gate 1: Min 2 Empty Cells Per Line (Anti-Determinism)
      if (!generator.checkMinEmptyPerLine(puzzle, gridSize, 2)) {
        failures.add(GenerationFailureReason.qualityGatesFailed);
        continue;
      }
      
      // Gate 2: Chapter 1 Anti-Triviality
      if (chapter == 1 && !generator.checkChapter1AntiTrivial(puzzle, gridSize)) {
        failures.add(GenerationFailureReason.qualityGatesFailed);
        continue;
      }
      
      // Solve to get metrics
      final solver = HumanLogicSolver(gridSize);
      final solveReport = solver.solve(puzzle);
      
      // Check solvability and uniqueness
      if (!solveReport.isSolvable) {
        failures.add(GenerationFailureReason.notSolvable);
        continue;
      }
      
      if (!solveReport.isUnique) {
        failures.add(GenerationFailureReason.notUnique);
        continue;
      }
      
      // Create generation report
      final report = GenerationReport.fromMetrics(
        size: gridSize,
        chapter: chapter,
        level: level,
        targetDifficultyMin: targetMin,
        targetDifficultyMax: targetMax,
        metrics: solveReport.metrics,
        generationAttempts: attempt + 1,
        givensCount: _countGivens(puzzle),
        forcedMoveIndices: solveReport.forcedMoveIndices,
        branchingIndices: solveReport.branchingIndices,
        branchDepths: solveReport.branchDepths,
      );
      
      // Check difficulty range (with debug logging)
      // Chapter 1: Accept score=0.00 (tutorial levels can be very easy)
      final inRange = report.finalDifficultyScore >= targetMin && 
                      report.finalDifficultyScore <= targetMax;
      
      if (!inRange) {
        if (kDebugMode && failures.length < 3) {
          print('  [DEBUG] Difficulty out of range: score=${report.finalDifficultyScore.toStringAsFixed(2)}, target=[${targetMin.toStringAsFixed(2)}, ${targetMax.toStringAsFixed(2)}]');
        }
        failures.add(GenerationFailureReason.difficultyOutOfRange);
        continue;
      }
      
      // Check quality gates (strict or relaxed)
      bool meetsQuality;
      if (strictQualityGates) {
        meetsQuality = report.meetsQualityGates();
      } else {
        // Relaxed: only check maxChain (strict), relax earlyForcedRatio
        final maxChainThreshold = gridSize == 4 ? 6 : (gridSize == 6 ? 10 : 15);
        meetsQuality = report.maxForcedChainLength <= maxChainThreshold &&
                       report.earlyForcedRatio <= relaxedEarlyForcedRatio;
      }
      
      if (!meetsQuality) {
        failures.add(GenerationFailureReason.qualityGatesFailed);
        continue;
      }
      
      // Apply Mechanics Params (Locked Cells)
      final Map<String, dynamic> finalParams = Map.from(mechanicsPlan?.params ?? {});
      if (mechanicsPlan != null && mechanicsPlan.mechanics.contains(MechanicFlag.lockedCells)) {
        final lockedCount = finalParams['lockedCount'] as int? ?? 0;
        if (lockedCount > 0) {
           final givensIndices = <int>[];
           for (int r = 0; r < gridSize; r++) {
             for (int c = 0; c < gridSize; c++) {
               if (puzzle[r][c] != GameConstants.cellEmpty) {
                 givensIndices.add(r * gridSize + c);
               }
             }
           }
           
           // Shuffle deterministically based on seed + attempt
           final rng = Random(baseSeed + attempt + 12345);
           givensIndices.shuffle(rng);
           
           finalParams['lockedIndices'] = givensIndices.take(lockedCount).toList();
        }
      }
      
      // Success!
      return GenerationResult(
        success: true,
        level: GeneratedLevel(
          id: levelId,
          chapter: chapter,
          level: level,
          size: gridSize,
          givens: puzzle,
          solution: fullSolution,
          difficultyScore: report.finalDifficultyScore,
          metrics: report.metrics,
          mechanics: mechanicsPlan?.mechanics ?? [],
          params: finalParams,
        ),
        report: report,
        failures: failures,
      );
    }
    
    return GenerationResult(
      success: false,
      failures: failures,
    );
  }
  
  
  /// Get target difficulty range (wider range for better success rate)
  (double, double) _getTargetDifficultyRange(int chapter, int levelId) {
    final target = _getTargetDifficulty(chapter, levelId);
    // Use much wider range (±2.0) for better generation success
    // Difficulty score can vary significantly based on puzzle structure
    final range = chapter >= 3 ? 3.0 : 2.0; // Very wide range
    // Chapter 1: Allow 0.0 as minimum (tutorial levels can be very easy)
    // Other chapters: Ensure minimum is at least 0 and max is at most 10
    final min = chapter == 1 
        ? 0.0 // Chapter 1: Accept any difficulty (tutorial size)
        : (target - range).clamp(0.0, 10.0);
    final max = chapter == 1
        ? 10.0 // Chapter 1: Accept up to 10.0 (4x4 metrics run high)
        : (target + range).clamp(0.0, 10.0);
    return (min, max);
  }

  /// Dig holes in the solution to create a puzzle
  /// Ensures target difficulty and uniqueness
  /// Returns null if strict constraints cannot be met
  List<List<int>>? _digHolesWithDifficulty(
    List<List<int>> solution,
    int gridSize,
    double targetDifficulty,
    int chapter,
  ) {
    final puzzle = solution.map((row) => List<int>.from(row)).toList();
    final totalCells = gridSize * gridSize;
    
    // Calculate min/max givens based on grid size
    // Chapter 2+: Use lower minGivens for harder puzzles
    final (minGivens, maxGivens) = _getGivensRange(gridSize, chapter);
    
    // Generate list of all positions and shuffle
    final positions = List.generate(totalCells, (i) => i);
    positions.shuffle(_random);
    
    int removed = 0;
    int attempts = 0;
    final maxAttempts = totalCells * 20; // More attempts for better difficulty matching
    
    // Try to remove cells while maintaining difficulty and uniqueness
    for (int pos in positions) {
      if (attempts >= maxAttempts) break;
      
      final remainingGivens = totalCells - removed;
      // Allow removing more cells to reach target difficulty
      // Only stop if we're at absolute minimum
      if (remainingGivens <= minGivens) break; // Don't remove too many
      
      attempts++;
      final row = pos ~/ gridSize;
      final col = pos % gridSize;
      
      // Skip if already empty
      if (puzzle[row][col] == GameConstants.cellEmpty) continue;
      
      // Chapter-specific constraints
      if (!_canRemoveCell(puzzle, row, col, gridSize, chapter)) {
        continue;
      }
      
      // Save original value
      final originalValue = puzzle[row][col];
      puzzle[row][col] = GameConstants.cellEmpty;
      
      // Check uniqueness
      final solver = HumanLogicSolver(gridSize);
      final report = solver.solve(puzzle);
      
      if (!report.isUnique) {
        // Not unique - restore cell
        puzzle[row][col] = originalValue;
        continue;
      }
      
      // Check difficulty
      final currentScore = report.metrics.computeDifficultyScore(gridSize);
      
      // CRITICAL: If score is 0 or very low, we MUST remove more cells
      // This happens when puzzle is too easy (high forcedMoveRatio)
      // Keep removing until we get at least some difficulty
      if (currentScore < 1.0) {
        // Very easy - aggressively remove more cells
        removed++;
        // Don't stop until we get some difficulty
        // But check if we're at minimum givens
        if (remainingGivens - 1 <= minGivens) {
          // At minimum, accept what we have
          break;
        }
        continue;
      }
      
      // If we're below target, continue removing aggressively
      if (currentScore < targetDifficulty - 1.0) {
        // Too easy - continue removing
        removed++;
        // Don't stop early if we're still below target
        if (remainingGivens - 1 <= minGivens) {
          // At minimum, accept what we have
          break;
        }
        continue;
      } else if (currentScore > targetDifficulty + 2.5) {
        // Too hard - restore and try different cell
        puzzle[row][col] = originalValue;
        continue;
      } else {
        // Close to target - keep removal
        removed++;
        
        // Stop if we're in a good range
        if (currentScore >= targetDifficulty - 1.5 && 
            currentScore <= targetDifficulty + 2.0 &&
            remainingGivens - 1 >= minGivens) {
          
          // CRITICAL: Ensure min 2 empty cells (USER REQUEST)
          if (_checkMinEmptyPerLine(puzzle, gridSize, 2)) {
            // Good enough - can stop
            break;
          }
          // If full line exists, continue removing to break it
          removed++;
          continue;
        }
      }
    }
    
    // FINAL PASS: Strictly enforce min 2 empty cells (Master Spec)
    // If we finished the main loop but still violate constraints, force remove
    if (!_checkMinEmptyPerLine(puzzle, gridSize, 2)) {
      // Find all filled cells in violating lines
      final candidates = <int>[];
      
      // Identify violating rows
      for (int r = 0; r < gridSize; r++) {
        if (_countEmptyInRow(puzzle, r, gridSize) < 2) {
           for (int c = 0; c < gridSize; c++) candidates.add(r * gridSize + c);
        }
      }
      
      // Identify violating cols
      for (int c = 0; c < gridSize; c++) {
        if (_countEmptyInCol(puzzle, c, gridSize) < 2) {
           for (int r = 0; r < gridSize; r++) candidates.add(r * gridSize + c);
        }
      }
      
      candidates.shuffle(_random);
      
      for (int pos in candidates) {
        final remainingGivens = totalCells - removed;
        if (remainingGivens <= minGivens) break; // Cannot remove more
        
        final r = pos ~/ gridSize;
        final c = pos % gridSize;
        
        if (puzzle[r][c] == GameConstants.cellEmpty) continue;
        
        // Try to remove
        final original = puzzle[r][c];
        puzzle[r][c] = GameConstants.cellEmpty;
        
        // Check uniqueness
        final solver = HumanLogicSolver(gridSize);
        final report = solver.solve(puzzle);
        
        if (!report.isUnique) {
          puzzle[r][c] = original; // Restore
        } else {
          removed++;
          // If satisfied, we are done
          if (_checkMinEmptyPerLine(puzzle, gridSize, 2)) break;
        }
      }
    }
    
    // CRITICAL: If we STILL violate constraints, this generation is a FAILURE.
    if (!_checkMinEmptyPerLine(puzzle, gridSize, 2)) {
      return null;
    }

    return puzzle;
  }

  /// Check if a cell can be removed based on chapter constraints
  /// Prevents easy patterns that make puzzles trivial
  bool _canRemoveCell(
    List<List<int>> puzzle,
    int row,
    int col,
    int gridSize,
    int chapter,
  ) {
    // Chapter 1+: Apply pattern restrictions (Chapter 1'de de zorluk olsun)
    // Chapter 1 için daha az kısıtlama, Chapter 2+ için daha sıkı
    
    // Save original value
    final originalValue = puzzle[row][col];
    puzzle[row][col] = GameConstants.cellEmpty;
    
    // Check row patterns
    final rowPattern = _analyzeRowPattern(puzzle[row], gridSize, chapter);
    if (rowPattern.hasThreeFilled || rowPattern.hasTwoSameWithTwoEmpty) {
      puzzle[row][col] = originalValue;
      return false;
    }
    
    // Check column patterns
    final colPattern = _analyzeColumnPattern(puzzle, col, gridSize, chapter);
    if (colPattern.hasThreeFilled || colPattern.hasTwoSameWithTwoEmpty) {
      puzzle[row][col] = originalValue;
      return false;
    }
    
    // Restore and allow removal
    puzzle[row][col] = originalValue;
    return true;
  }

  int _countEmptyInRow(List<List<int>> puzzle, int row, int size) {
    int count = 0;
    for (int c = 0; c < size; c++) {
      if (puzzle[row][c] == GameConstants.cellEmpty) count++;
    }
    return count;
  }

  int _countEmptyInCol(List<List<int>> puzzle, int col, int size) {
    int count = 0;
    for (int r = 0; r < size; r++) {
      if (puzzle[r][col] == GameConstants.cellEmpty) count++;
    }
    return count;
  }

  /// Check if the puzzle has any fully filled row or column
  bool _checkMinEmptyPerLine(List<List<int>> puzzle, int size, int minEmpty) {
    // Check rows
    for (int r = 0; r < size; r++) {
      if (_countEmptyInRow(puzzle, r, size) < minEmpty) return false;
    }
    // Check cols
    for (int c = 0; c < size; c++) {
      if (_countEmptyInCol(puzzle, c, size) < minEmpty) return false;
    }
    return true;
  }

  /// Analyze row pattern to detect easy patterns
  /// Chapter 1: Daha az kısıtlama, Chapter 2+: Daha sıkı
  _RowPattern _analyzeRowPattern(List<int> row, int gridSize, int chapter) {
    int filledCount = 0;
    int sunCount = 0;
    int moonCount = 0;
    
    for (int c = 0; c < gridSize; c++) {
      if (row[c] != GameConstants.cellEmpty) {
        filledCount++;
        if (row[c] == GameConstants.cellSun) sunCount++;
        if (row[c] == GameConstants.cellMoon) moonCount++;
      }
    }
    
    final emptyCount = gridSize - filledCount;
    final targetCount = gridSize ~/ 2;
    
    // Chapter 1: Daha az kısıtlama (sadece en kolay pattern'ler)
    // Chapter 2+: Daha sıkı kısıtlama
    
    // Pattern 1: 3+ filled cells = too easy
    // Chapter 1: Sadece 4 dolu (tam dolu) engelle
    // Chapter 2+: 3+ dolu engelle
    final hasThreeFilled = chapter >= 2 
        ? filledCount >= 3 
        : filledCount >= 4; // Chapter 1: Sadece tam dolu engelle
    
    // Pattern 2: 2 same + 2 empty = trivial (remaining 2 must be opposite)
    final hasTwoSameWithTwoEmpty = (sunCount == 2 && emptyCount == 2) || 
                                    (moonCount == 2 && emptyCount == 2);
    
    // Pattern 3: For 6x6, if we have 3 same + 3 empty, it's also trivial
    final hasThreeSameWithThreeEmpty = (sunCount == 3 && emptyCount == 3) ||
                                       (moonCount == 3 && emptyCount == 3);
    
    // Pattern 4: If we're close to target (N/2), and only 1-2 empty, it's too easy
    // Chapter 1: Sadece 1 boş engelle (neredeyse tamamlanmış)
    // Chapter 2+: 1-2 boş engelle
    final isAlmostComplete = chapter >= 2
        ? (sunCount >= targetCount - 1 && emptyCount <= 2) ||
          (moonCount >= targetCount - 1 && emptyCount <= 2)
        : (sunCount >= targetCount && emptyCount <= 1) ||
          (moonCount >= targetCount && emptyCount <= 1); // Chapter 1: Sadece 1 boş
    
    return _RowPattern(
      hasThreeFilled: hasThreeFilled || isAlmostComplete,
      hasTwoSameWithTwoEmpty: hasTwoSameWithTwoEmpty || hasThreeSameWithThreeEmpty,
    );
  }

  /// Analyze column pattern to detect easy patterns
  /// Chapter 1: Daha az kısıtlama, Chapter 2+: Daha sıkı
  _RowPattern _analyzeColumnPattern(List<List<int>> puzzle, int col, int gridSize, int chapter) {
    int filledCount = 0;
    int sunCount = 0;
    int moonCount = 0;
    
    for (int r = 0; r < gridSize; r++) {
      if (puzzle[r][col] != GameConstants.cellEmpty) {
        filledCount++;
        if (puzzle[r][col] == GameConstants.cellSun) sunCount++;
        if (puzzle[r][col] == GameConstants.cellMoon) moonCount++;
      }
    }
    
    final emptyCount = gridSize - filledCount;
    final targetCount = gridSize ~/ 2;
    
    // Chapter 1: Daha az kısıtlama (sadece en kolay pattern'ler)
    // Chapter 2+: Daha sıkı kısıtlama
    
    // Pattern 1: 3+ filled cells = too easy
    // Chapter 1: Sadece 4 dolu (tam dolu) engelle
    // Chapter 2+: 3+ dolu engelle
    final hasThreeFilled = chapter >= 2 
        ? filledCount >= 3 
        : filledCount >= 4; // Chapter 1: Sadece tam dolu engelle
    
    // Pattern 2: 2 same + 2 empty = trivial (remaining 2 must be opposite)
    final hasTwoSameWithTwoEmpty = (sunCount == 2 && emptyCount == 2) || 
                                    (moonCount == 2 && emptyCount == 2);
    
    // Pattern 3: For 6x6, if we have 3 same + 3 empty, it's also trivial
    final hasThreeSameWithThreeEmpty = (sunCount == 3 && emptyCount == 3) ||
                                       (moonCount == 3 && emptyCount == 3);
    
    // Pattern 4: If we're close to target (N/2), and only 1-2 empty, it's too easy
    // Chapter 1: Sadece 1 boş engelle (neredeyse tamamlanmış)
    // Chapter 2+: 1-2 boş engelle
    final isAlmostComplete = chapter >= 2
        ? (sunCount >= targetCount - 1 && emptyCount <= 2) ||
          (moonCount >= targetCount - 1 && emptyCount <= 2)
        : (sunCount >= targetCount && emptyCount <= 1) ||
          (moonCount >= targetCount && emptyCount <= 1); // Chapter 1: Sadece 1 boş
    
    return _RowPattern(
      hasThreeFilled: hasThreeFilled || isAlmostComplete,
      hasTwoSameWithTwoEmpty: hasTwoSameWithTwoEmpty || hasThreeSameWithThreeEmpty,
    );
  }

  /// Get target difficulty for a chapter/level (NEW STRUCTURE)
  double _getTargetDifficulty(int chapter, int levelId) {
    // Chapter 1: 4x4, 10 levels, progressive difficulty 4-7/10 (USER REQUEST: Avg 5-6)
    if (chapter == 1) {
      // Level 1-3: 4.0 - 5.0 (Intro)
      // Level 4-7: 5.0 - 6.0 (Mid)
      // Level 8-10: 6.0 - 7.0 (Hard)
      if (levelId <= 3) {
        return 4.0 + (levelId % 2); // 4-5 range
      } else if (levelId <= 7) {
        return 5.0 + (levelId % 2); // 5-6 range
      } else {
        return 6.0 + (levelId % 2); // 6-7 range
      }
    }
    
    // Chapter 2: 6x6, 60 levels, progressive difficulty 5-7/10
    if (chapter == 2) {
      // Early (11-30): 5-6/10
      // Mid (31-50): 6-7/10
      // Late (51-70): 7-8/10
      if (levelId <= 30) {
        return 5.0 + (levelId % 2) * 0.5; // 5-5.5 range
      } else if (levelId <= 50) {
        return 6.0 + (levelId % 2) * 0.5; // 6-6.5 range
      } else {
        return 7.0 + (levelId % 2) * 0.5; // 7-7.5 range
      }
    }
    
    // Chapter 3: 8x8, 70 levels, progressive difficulty 6-8/10
    if (chapter == 3) {
      // Early (71-100): 6-7/10
      // Mid (101-120): 7-8/10
      // Late (121-140): 8-9/10
      if (levelId <= 100) {
        return 6.0 + (levelId % 2) * 0.5; // 6-6.5 range
      } else if (levelId <= 120) {
        return 7.0 + (levelId % 2) * 0.5; // 7-7.5 range
      } else {
        return 8.0 + (levelId % 2) * 0.5; // 8-8.5 range
      }
    }
    
    // Chapter 4: 8x8 mastery, 60 levels, difficulty 8-10/10
    if (chapter == 4) {
      // Early (141-160): 8-9/10
      // Mid (161-180): 9-10/10
      // Late (181-200): 9.5-10/10
      if (levelId <= 160) {
        return 8.0 + (levelId % 2) * 0.5; // 8-8.5 range
      } else if (levelId <= 180) {
        return 9.0 + (levelId % 2) * 0.5; // 9-9.5 range
      } else {
        return 9.5 + (levelId % 2) * 0.25; // 9.5-9.75 range
      }
    }
    
    // Chapter 5+: maintain high difficulty
    return 10.0;
  }

  /// Get grid size for level ID
  /// NEW STRUCTURE: Levels 1-10: 4x4, 11-70: 6x6, 71+: 8x8
  int _getGridSizeForLevelId(int levelId) {
    if (levelId <= 10) return 4; // Chapter 1: 4x4
    return 6; // Chapter 2+: 6x6 (Master Spec)
  }

  /// Get min/max givens range for grid size
  /// Chapter 1+: Progressive difficulty (daha az givens = daha zor)
  (int, int) _getGivensRange(int gridSize, int chapter) {
    switch (gridSize) {
      case 4:
        // Chapter 1: 4x4 needs fewer givens to be hard
        // Min possible is usually 4-5 for a unique solution
        if (chapter == 1) {
          return (4, 8); // Allow fewer givens (4-8) to reach higher difficulty
        }
        return (6, 10); // 4x4: 6-10 givens
      case 6:
        if (chapter >= 2) {
          return (10, 18); // 6x6 Chapter 2+: 10-18 givens (daha az = daha zor)
        }
        return (12, 20); // 6x6 Chapter 1: 12-20 givens
      case 8:
        if (chapter >= 4) {
          return (18, 30); // 8x8 Chapter 4+: 18-30 givens (daha az = daha zor)
        }
        return (22, 34); // 8x8: 22-34 givens
      default:
        return (gridSize, gridSize * 2);
    }
  }

  /// Calculate level ID from chapter and level
  /// Uses LevelManager's actual calculation (NEW STRUCTURE)
  int _calculateLevelId(int chapter, int level) {
    // NEW STRUCTURE: Use LevelManager to match actual progression
    // Chapter 1: 10 levels (1-10)
    // Chapter 2: 60 levels (11-70)
    // Chapter 3: 70 levels (71-140)
    // Chapter 4: 60 levels (141-200)
    // Chapter 5+: 20 levels each (procedural)
    int levelId = 0;
    for (int ch = 1; ch < chapter; ch++) {
      if (ch == 1) {
        levelId += 10; // Chapter 1: 10 levels
      } else if (ch == 2) {
        levelId += 60; // Chapter 2: 60 levels
      } else if (ch == 3) {
        levelId += 70; // Chapter 3: 70 levels
      } else if (ch == 4) {
        levelId += 60; // Chapter 4: 60 levels
      } else {
        levelId += 20; // Chapter 5+: 20 levels
      }
    }
    levelId += level;
    return levelId;
  }

  /// Calculate seed for deterministic generation
  /// Modified to include a SALT to refresh all levels and fix bad seeds
  int _calculateSeed(int chapter, int level) {
    // Salt added to refresh levels (User Request: "Randomness")
    return (chapter * 1000) + level + 12345;
  }
  
  /// Count non-empty cells (givens)
  int _countGivens(List<List<int>> puzzle) {
    int count = 0;
    for (final row in puzzle) {
      for (final cell in row) {
        if (cell != GameConstants.cellEmpty) count++;
      }
    }
    return count;
  }
}

/// Represents a generated level with all metadata
class GeneratedLevel {
  final int id;
  final int chapter;
  final int level;
  final int size;
  final List<List<int>> givens; // The puzzle (with empty cells)
  final List<List<int>> solution; // The complete solution
  final double difficultyScore;
  final DifficultyMetrics metrics;
  final List<MechanicFlag> mechanics;
  final Map<String, dynamic> params;

  GeneratedLevel({
    required this.id,
    required this.chapter,
    required this.level,
    required this.size,
    required this.givens,
    required this.solution,
    required this.difficultyScore,
    required this.metrics,
    this.mechanics = const [],
    this.params = const {},
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chapter': chapter,
      'level': level,
      'size': size,
      'givens': givens,
      'solution': solution,
      'difficultyScore': difficultyScore,
      'mechanics': mechanics.map((m) => m.name).toList(),
      'params': params,
      'metrics': {
        'forcedMovesCount': metrics.forcedMovesCount,
        'branchingEventsCount': metrics.branchingEventsCount,
        'maxBranchDepth': metrics.maxBranchDepth,
        'backtracksCount': metrics.backtracksCount,
        'totalAssignments': metrics.totalAssignments,
        'firstBranchStepIndex': metrics.firstBranchStepIndex,
        'forcedMoveRatio': metrics.forcedMoveRatio,
      },
    };
  }
}

