import 'dart:math';
import 'package:flutter/foundation.dart';
import '../constants/game_constants.dart';
import '../domain/generation_report.dart';
import '../domain/generation_failure_reason.dart';
import 'puzzle_generator.dart';
import 'human_logic_solver.dart';
import 'grid_validator.dart';
import 'grid_helper.dart';
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
    var (targetMin, targetMax) = _getTargetDifficultyRange(chapter, levelId);
    
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
  }) {
    final failures = <GenerationFailureReason>[];
    final baseSeed = newSolutionSeed ?? _calculateSeed(chapter, level);
    
    for (int attempt = 0; attempt < budget; attempt++) {
      // Generate full solution
      final generator = PuzzleGenerator(seed: baseSeed + attempt);
      final fullSolution = generator.generateCompleteBoard(gridSize);
      
      // Dig holes to create puzzle
      final puzzle = _digHolesWithDifficulty(
        fullSolution,
        gridSize,
        (targetMin + targetMax) / 2,
        chapter,
      );
      
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
      
      // Check difficulty range
      final inRange = report.finalDifficultyScore >= targetMin && 
                      report.finalDifficultyScore <= targetMax;
      
      if (!inRange) {
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
  
  
  /// Get target difficulty range
  (double, double) _getTargetDifficultyRange(int chapter, int levelId) {
    final target = _getTargetDifficulty(chapter, levelId);
    return (target - 0.5, target + 0.5);
  }

  /// Dig holes in the solution to create a puzzle
  /// Ensures target difficulty and uniqueness
  List<List<int>> _digHolesWithDifficulty(
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
    final maxAttempts = totalCells * 10;
    
    // Try to remove cells while maintaining difficulty and uniqueness
    for (int pos in positions) {
      if (attempts >= maxAttempts) break;
      
      final remainingGivens = totalCells - removed;
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
      
      // Chapter 1+: Be more aggressive - remove more cells
      // Chapter 1: Biraz daha toleranslı ama yine de agresif
      // Chapter 2+: Çok agresif
      final difficultyTolerance = chapter >= 2 ? 0.3 : 0.4;
      
      // If we're below target, continue removing aggressively
      if (currentScore < targetDifficulty - difficultyTolerance) {
        // Too easy - continue removing
        removed++;
      } else if (currentScore > targetDifficulty + 1.5) {
        // Too hard - restore and try different cell
        puzzle[row][col] = originalValue;
      } else {
        // Close to target - keep removal
        removed++;
        
        // Chapter 1+: Don't stop early, keep removing to reach target
        if (chapter >= 2) {
          // Continue removing until we're at or above target
          if (currentScore >= targetDifficulty - 0.2 && 
              currentScore <= targetDifficulty + 0.3 &&
              remainingGivens - 1 >= minGivens) {
            // Good enough - can stop
            break;
          }
        } else {
          // Chapter 1: Biraz daha toleranslı ama yine de hedefe ulaşana kadar devam
          if (currentScore >= targetDifficulty - 0.25 && 
              currentScore <= targetDifficulty + 0.4 &&
              remainingGivens - 1 >= minGivens) {
            break;
          }
        }
      }
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

  /// Get target difficulty for a chapter/level
  double _getTargetDifficulty(int chapter, int levelId) {
    // Chapter 1: 4x4, progressive difficulty 4-7/10 (level arttıkça zorlaşır)
    if (chapter == 1) {
      // Level 1-5: 4-5/10
      // Level 6-10: 5-6/10
      // Level 11-15: 6-7/10
      final levelInChapter = ((levelId - 1) % 15) + 1;
      if (levelInChapter <= 5) {
        return 4.0 + (levelInChapter % 2); // 4-5 range
      } else if (levelInChapter <= 10) {
        return 5.0 + (levelInChapter % 2); // 5-6 range
      } else {
        return 6.0 + (levelInChapter % 2); // 6-7 range
      }
    }
    
    // Chapter 2: 6x6, average 7-8/10 (Daha zor!)
    if (chapter == 2) {
      return 7.0 + (levelId % 2); // 7-8 range
    }
    
    // Chapter 3: 6x6, average 7-8/10
    if (chapter == 3) {
      return 7.0 + (levelId % 2); // 7-8 range
    }
    
    // Chapter 4-15: 7-10, generally increasing
    if (chapter >= 4 && chapter <= 15) {
      // Base difficulty increases with chapter
      double base = 7.0 + ((chapter - 4) / 11.0) * 3.0; // 7.0 to 10.0
      
      // Add some variation
      double variation = (levelId % 3) - 1.0; // -1, 0, +1
      
      double difficulty = base + variation * 0.3;
      
      // Chapter 6+: minimum 7
      if (chapter >= 6 && difficulty < 7.0) {
        difficulty = 7.0;
      }
      
      // Chapter 15: target 10
      if (chapter == 15) {
        difficulty = 10.0;
      }
      
      return difficulty.clamp(7.0, 10.0);
    }
    
    // Chapter 16+: maintain high difficulty
    return 10.0;
  }

  /// Get grid size for level ID
  /// Chapter 1: 4x4 (levels 1-15)
  /// Chapter 2+: 6x6 (levels 16+)
  int _getGridSizeForLevelId(int levelId) {
    if (levelId <= 15) return 4; // Chapter 1: 4x4
    if (levelId <= 100) return 6; // Chapter 2+: 6x6
    return 8; // Levels 101+: 8x8
  }

  /// Get min/max givens range for grid size
  /// Chapter 1+: Progressive difficulty (daha az givens = daha zor)
  (int, int) _getGivensRange(int gridSize, int chapter) {
    switch (gridSize) {
      case 4:
        // Chapter 1: Progressive difficulty
        // Level 1-5: 7-9 givens (kolay)
        // Level 6-10: 6-8 givens (orta)
        // Level 11-15: 5-7 givens (zor)
        if (chapter == 1) {
          return (5, 9); // 4x4 Chapter 1: 5-9 givens (önceden 6-10)
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
  /// Uses LevelManager's actual calculation
  int _calculateLevelId(int chapter, int level) {
    // Use LevelManager's getLevelId to match the actual progression
    // Chapter 1: 15 levels (1-15)
    // Chapter 2: 15 levels (16-30)
    // Chapter 3-12: 20 levels each
    // Chapter 13+: 20 levels each
    int levelId = 0;
    for (int ch = 1; ch < chapter; ch++) {
      if (ch <= 2) {
        levelId += 15; // Chapters 1-2: 15 levels
      } else {
        levelId += 20; // Chapters 3+: 20 levels
      }
    }
    levelId += level;
    return levelId;
  }

  /// Calculate seed for deterministic generation
  int _calculateSeed(int chapter, int level) {
    return (chapter * 1000) + level;
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

  GeneratedLevel({
    required this.id,
    required this.chapter,
    required this.level,
    required this.size,
    required this.givens,
    required this.solution,
    required this.difficultyScore,
    required this.metrics,
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

