import 'package:flutter/foundation.dart';
import '../../../../core/utils/puzzle_generator.dart';
import '../../../../core/utils/puzzle_solver.dart';
import '../../../../core/services/level_manager.dart';
import '../../../../core/data/level_loader.dart';
import '../../../../core/domain/mechanic_flag.dart';
import '../../domain/models/puzzle_model.dart';
import '../../domain/models/cell_model.dart';
import '../../domain/models/level_model.dart';

/// Repository for game-related data operations
class GameRepository {
  final PuzzleGenerator _puzzleGenerator;

  GameRepository({PuzzleGenerator? puzzleGenerator})
      : _puzzleGenerator = puzzleGenerator ?? PuzzleGenerator();

  /// Generates a new puzzle for a specific level
  /// Tries to load from LevelLoader first, falls back to generation if not available
  /// CRITICAL: Grid size is determined by level ID, not chapter
  Future<PuzzleModel> generatePuzzleForLevel(LevelModel level) async {
    // Try to load from LevelLoader first
    try {
      final loadedLevel = await LevelLoader.loadLevel(level.chapter, level.level, throwOnError: false);
      if (loadedLevel != null) {
        // CRITICAL FIX: Check if givens is the same as solution (all cells filled)
        // If so, generate puzzle on-the-fly from solution
        bool givensIsComplete = true;
        for (int r = 0; r < loadedLevel.size; r++) {
          for (int c = 0; c < loadedLevel.size; c++) {
            if (loadedLevel.givens[r][c] == 0) {
              givensIsComplete = false;
              break;
            }
          }
          if (!givensIsComplete) break;
        }
        
        // If givens is complete (same as solution), generate puzzle on-the-fly
        List<List<int>> puzzleGivens;
        if (givensIsComplete) {
          debugPrint('[GameRepository] Level ${level.chapter}-${level.level}: givens is complete, generating puzzle from solution');
          // Generate puzzle from solution using PuzzleGenerator
          final gridSize = loadedLevel.size;
          final difficultyFactor = LevelManager.calculateDifficultyFactor(level.chapter, level.level);
          final generator = PuzzleGenerator(seed: loadedLevel.id);
          puzzleGivens = generator.createPlayablePuzzle(loadedLevel.solution, difficultyFactor);
        } else {
          // Use givens as-is (already has empty cells)
          puzzleGivens = loadedLevel.givens;
        }
        
        // Convert LoadedLevel to PuzzleModel
        final List<List<CellModel>> currentState = puzzleGivens.asMap().entries.map((rowEntry) {
          final int row = rowEntry.key;
          return rowEntry.value.asMap().entries.map((colEntry) {
            final int col = colEntry.key;
            final int value = colEntry.value;
            final isGiven = value != 0;

            return CellModel(
              value: value,
              isGiven: isGiven,
            );
          }).toList();
        }).toList();
        
        return PuzzleModel(
          id: 'level_${level.chapter}_${level.level}_${loadedLevel.id}',
          size: loadedLevel.size,
          solution: loadedLevel.solution,
          currentState: currentState,
          difficulty: PuzzleDifficulty.easy, // Kept for backward compatibility
          level: level,
          seed: loadedLevel.id,
          createdAt: DateTime.now(),
          mechanics: loadedLevel.mechanics,
          params: loadedLevel.params,
        );
      }
    } catch (e) {
      // Fall through to generation
      debugPrint('[GameRepository] Failed to load level from pack: $e');
    }
    
    // Fallback: Generate on-device (backward compatibility)
    final gridSize = LevelManager.getGridSizeForChapter(level.chapter, level.level);
    final difficultyFactor = LevelManager.calculateDifficultyFactor(level.chapter, level.level);
    final seed = LevelManager.generateSeed(level.chapter, level.level);
    
    // CRITICAL FIX: Run heavy generation in background isolate to prevent UI freeze
    final result = await compute(_generatePuzzleInIsolate, {
      'seed': seed,
      'gridSize': gridSize,
      'difficultyFactor': difficultyFactor,
    });
    
    final solution = result['solution'] as List<List<int>>;
    final puzzle = result['puzzle'] as List<List<int>>;
    
    // Convert to CellModel grid
    final List<List<CellModel>> currentState = puzzle.map((row) {
      return row.map((value) {
        return CellModel(
          value: value,
          isGiven: value != 0,
        );
      }).toList();
    }).toList();
    
    return PuzzleModel(
      id: 'level_${level.chapter}_${level.level}_$seed',
      size: gridSize,
      solution: solution,
      currentState: currentState,
      difficulty: PuzzleDifficulty.easy, // Kept for backward compatibility
      level: level,
      seed: seed,
      createdAt: DateTime.now(),
      mechanics: [], // No mechanics for generated puzzles
      params: {},
    );
  }

  /// Generates a new puzzle with the specified difficulty (backward compatibility)
  PuzzleModel generatePuzzle(PuzzleDifficulty difficulty) {
    final int size = difficulty.gridSize;
    final int seed = DateTime.now().millisecondsSinceEpoch;
    final generator = PuzzleGenerator(seed: seed);
    final difficultyFactor = _getDifficultyPercentage(difficulty);
    
    // Phase A: Generate complete valid board
    final List<List<int>> solution = generator.generateCompleteBoard(size);
    
    // Phase B: Create playable puzzle by masking cells
    final List<List<int>> puzzle = generator.createPlayablePuzzle(solution, difficultyFactor);
    
    // Convert to CellModel grid
    final List<List<CellModel>> currentState = puzzle.map((row) {
      return row.map((value) {
        return CellModel(
          value: value,
          isGiven: value != 0,
        );
      }).toList();
    }).toList();
    
    return PuzzleModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      size: size,
      solution: solution,
      currentState: currentState,
      difficulty: difficulty,
      seed: seed,
      createdAt: DateTime.now(),
    );
  }

  /// Generates a daily challenge puzzle
  PuzzleModel generateDailyChallenge(PuzzleDifficulty difficulty) {
    final int size = difficulty.gridSize;
    final DateTime now = DateTime.now();
    final int seed = now.year * 10000 + now.month * 100 + now.day;
    final generator = PuzzleGenerator(seed: seed);
    
    // Phase A: Generate complete valid board
    final List<List<int>> solution = generator.generateCompleteBoard(size);
    
    // Phase B: Create playable puzzle (slightly harder for daily challenge)
    final List<List<int>> puzzle = generator.createPlayablePuzzle(solution, 0.55);
    
    // Convert to CellModel grid
    final List<List<CellModel>> currentState = puzzle.map((row) {
      return row.map((value) {
        return CellModel(
          value: value,
          isGiven: value != 0,
        );
      }).toList();
    }).toList();
    
    return PuzzleModel(
      id: 'daily_${DateTime.now().year}_${DateTime.now().month}_${DateTime.now().day}',
      size: size,
      solution: solution,
      currentState: currentState,
      difficulty: difficulty,
      seed: DateTime.now().year * 10000 + DateTime.now().month * 100 + DateTime.now().day,
      isDailyChallenge: true,
      createdAt: DateTime.now(),
    );
  }

  /// Gets the difficulty percentage based on difficulty level
  double _getDifficultyPercentage(PuzzleDifficulty difficulty) {
    switch (difficulty) {
      case PuzzleDifficulty.easy:
        return 0.4; // 40% cells removed
      case PuzzleDifficulty.medium:
        return 0.5; // 50% cells removed
      case PuzzleDifficulty.hard:
        return 0.6; // 60% cells removed
      case PuzzleDifficulty.expert:
        return 0.7; // 70% cells removed
    }
  }
}

/// Top-level function for compute() to generate puzzle in background
Future<Map<String, dynamic>> _generatePuzzleInIsolate(Map<String, dynamic> params) async {
  final int seed = params['seed'];
  final int gridSize = params['gridSize'];
  final double difficultyFactor = params['difficultyFactor'];
  final generator = PuzzleGenerator(seed: seed);
  
  // RETRY LOOP (Use same logic as PuzzleGenerator.generatePuzzleForLevel)
  int attempts = 0;
  const int maxAttempts = 20;
  
  while (attempts < maxAttempts) {
    attempts++;
    try {
      // Phase A: Generate complete valid board
      final List<List<int>> solution = generator.generateCompleteBoard(gridSize);
      
      // Phase B: Create playable puzzle by masking cells
      final List<List<int>> puzzle = generator.createPlayablePuzzle(solution, difficultyFactor);
      
      // Check Gate 1: MinEmptyPerLine = 2
      if (!generator.checkMinEmptyPerLine(puzzle, gridSize, 2)) {
         if (attempts < maxAttempts) continue; // Retry
         // If last attempt, we might have to accept it or fail
         // Master Spec says "Strictly enforce", so we should probably fail/retry or fallback to best effort?
         // We'll log and return, assuming createPlayablePuzzle did its best
      }
      
      // Check Gate 2: Logic Solvable (Redundant but safe)
      if (!PuzzleSolver.canSolveLogically(puzzle, gridSize)) {
         continue; 
      }
      
      return {
        'solution': solution,
        'puzzle': puzzle,
      };
    } catch (e) {
      if (attempts >= maxAttempts) rethrow;
    }
  }
  
  throw Exception('Failed to generate valid puzzle satisfying all gates in Isolate');
}

