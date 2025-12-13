import '../../../../core/utils/puzzle_generator.dart';
import '../../../../core/services/level_manager.dart';
import '../../domain/models/puzzle_model.dart';
import '../../domain/models/cell_model.dart';
import '../../domain/models/level_model.dart';

/// Repository for game-related data operations
class GameRepository {
  final PuzzleGenerator _puzzleGenerator;

  GameRepository({PuzzleGenerator? puzzleGenerator})
      : _puzzleGenerator = puzzleGenerator ?? PuzzleGenerator();

  /// Generates a new puzzle for a specific level
  /// Uses two-phase system: Generation (Backtracking) + Masking (Difficulty)
  /// CRITICAL: Grid size is determined by level ID, not chapter
  PuzzleModel generatePuzzleForLevel(LevelModel level) {
    // Get configuration from LevelManager
    final gridSize = LevelManager.getGridSizeForChapter(level.chapter, level.level);
    final difficultyFactor = LevelManager.calculateDifficultyFactor(level.chapter, level.level);
    final seed = LevelManager.generateSeed(level.chapter, level.level);
    
    // Use new two-phase generation system
    final generator = PuzzleGenerator(seed: seed);
    
    // Phase A: Generate complete valid board
    final List<List<int>> solution = generator.generateCompleteBoard(gridSize);
    
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
      id: 'level_${level.chapter}_${level.level}_$seed',
      size: gridSize,
      solution: solution,
      currentState: currentState,
      difficulty: PuzzleDifficulty.easy, // Kept for backward compatibility
      level: level,
      seed: seed,
      createdAt: DateTime.now(),
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

