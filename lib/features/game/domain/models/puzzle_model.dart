import 'package:freezed_annotation/freezed_annotation.dart';
import 'cell_model.dart';
import 'level_model.dart';

part 'puzzle_model.freezed.dart';
part 'puzzle_model.g.dart';

/// Represents a complete puzzle with solution and current state
@freezed
class PuzzleModel with _$PuzzleModel {
  const factory PuzzleModel({
    /// Unique puzzle ID
    required String id,
    
    /// Grid size (4, 6, or 8)
    required int size,
    
    /// The solution grid (complete, valid puzzle)
    required List<List<int>> solution,
    
    /// The current state of the puzzle (with empty cells)
    required List<List<CellModel>> currentState,
    
    /// Difficulty level (kept for backward compatibility)
    @Default(PuzzleDifficulty.easy) PuzzleDifficulty difficulty,
    
    /// Level information (chapter and level)
    LevelModel? level,
    
    /// Seed used to generate this puzzle
    required int seed,
    
    /// Whether this is a daily challenge
    @Default(false) bool isDailyChallenge,
    
    /// Date this puzzle was created (for daily challenges)
    DateTime? createdAt,
  }) = _PuzzleModel;

  factory PuzzleModel.fromJson(Map<String, dynamic> json) =>
      _$PuzzleModelFromJson(json);
}

/// Difficulty levels
enum PuzzleDifficulty {
  easy,
  medium,
  hard,
  expert,
}

extension PuzzleDifficultyExtension on PuzzleDifficulty {
  int get gridSize {
    switch (this) {
      case PuzzleDifficulty.easy:
        return 6;
      case PuzzleDifficulty.medium:
        return 8;
      case PuzzleDifficulty.hard:
        return 10;
      case PuzzleDifficulty.expert:
        return 12;
    }
  }

  String get displayName {
    switch (this) {
      case PuzzleDifficulty.easy:
        return 'Easy';
      case PuzzleDifficulty.medium:
        return 'Medium';
      case PuzzleDifficulty.hard:
        return 'Hard';
      case PuzzleDifficulty.expert:
        return 'Expert';
    }
  }
}

