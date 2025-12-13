import 'package:freezed_annotation/freezed_annotation.dart';

part 'level_model.freezed.dart';
part 'level_model.g.dart';

/// Represents a game level with chapter and level number
@freezed
class LevelModel with _$LevelModel {
  const factory LevelModel({
    required int chapter,
    required int level,
  }) = _LevelModel;

  factory LevelModel.fromJson(Map<String, dynamic> json) =>
      _$LevelModelFromJson(json);
}

/// Level configuration - determines grid size and difficulty
class LevelConfig {
  final int chapter;
  final int level;
  final int gridSize;
  final double difficulty; // Percentage of cells to remove (0.0 - 1.0)

  const LevelConfig({
    required this.chapter,
    required this.level,
    required this.gridSize,
    required this.difficulty,
  });

  /// Get grid size based on chapter (DEPRECATED - use LevelManager instead)
  /// - Chapters 1-2: 4x4 grid
  /// - Chapters 3-12: 6x6 grid
  /// - Chapter 13+: 8x8 grid
  @Deprecated('Use LevelManager.getGridSizeForChapter instead')
  static int getGridSizeForChapter(int chapter) {
    if (chapter <= 2) {
      return 4;
    } else if (chapter <= 12) {
      return 6;
    } else {
      return 8;
    }
  }

  /// Calculate difficulty based on chapter and level
  /// Difficulty increases gradually:
  /// - More cells removed = harder puzzle
  /// - Formula: baseDifficulty + (chapter * 0.01) + (level * 0.001)
  static double calculateDifficulty(int chapter, int level) {
    // Base difficulty: 0.35 (35% cells removed)
    // Each chapter adds 0.01 (1%)
    // Each level adds 0.001 (0.1%)
    // Max difficulty: ~0.65 (65% cells removed) for very high chapters
    final baseDifficulty = 0.35;
    final chapterBonus = chapter * 0.01;
    final levelBonus = level * 0.001;
    
    // Cap at 0.65 to ensure puzzles remain solvable
    final difficulty = baseDifficulty + chapterBonus + levelBonus;
    return difficulty.clamp(0.35, 0.65);
  }

  /// Create LevelConfig from chapter and level
  factory LevelConfig.fromLevel(int chapter, int level) {
    return LevelConfig(
      chapter: chapter,
      level: level,
      gridSize: getGridSizeForChapter(chapter),
      difficulty: calculateDifficulty(chapter, level),
    );
  }

  /// Get total number of levels per chapter (DEPRECATED - use LevelManager instead)
  @Deprecated('Use LevelManager.getLevelsPerChapter instead')
  static int getLevelsPerChapter(int chapter) {
    if (chapter <= 2) {
      return 15;
    } else if (chapter <= 12) {
      return 20;
    } else {
      return 20;
    }
  }

  /// Get total number of chapters (DEPRECATED - use LevelManager instead)
  @Deprecated('Use LevelManager.getMaxChaptersForUI instead')
  static int getTotalChapters() {
    return 100;
  }

  /// Check if level exists (DEPRECATED - use LevelManager instead)
  @Deprecated('Use LevelManager.isValidLevel instead')
  static bool isValidLevel(int chapter, int level) {
    if (chapter < 1) return false;
    final maxLevel = getLevelsPerChapter(chapter);
    return level >= 1 && level <= maxLevel;
  }

  /// Get next level (DEPRECATED - use LevelManager instead)
  @Deprecated('Use LevelManager.getNextLevel instead')
  static LevelModel? getNextLevel(LevelModel current) {
    final maxLevel = getLevelsPerChapter(current.chapter);
    
    if (current.level < maxLevel) {
      return LevelModel(chapter: current.chapter, level: current.level + 1);
    } else {
      return LevelModel(chapter: current.chapter + 1, level: 1);
    }
  }

  /// Get display name for level
  String get displayName => 'Chapter $chapter - Level $level';
}

