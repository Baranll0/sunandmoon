import '../../features/game/domain/models/level_model.dart';

/// Level Manager - Manages journey progression with correct grid sizes
/// CRITICAL: Grid size is determined by LEVEL ID, not chapter
class LevelManager {
  /// Calculate total level ID from chapter and level
  /// Level ID = cumulative level number across all chapters
  static int getLevelId(int chapter, int level) {
    int levelId = 0;
    for (int ch = 1; ch < chapter; ch++) {
      levelId += getLevelsPerChapter(ch);
    }
    levelId += level;
    return levelId;
  }

  /// Get grid size based on LEVEL ID (NEW STRUCTURE: Master Spec)
  /// - Levels 1-10 (Chapter 1): 4x4
  /// - Levels 11+ (Chapter 2+): 6x6
  /// Note: 8x8 reserved for future expansion or special modes
  static int getGridSizeForLevelId(int levelId) {
    if (levelId <= 10) {
      return 4; // Levels 1-10 (Chapter 1): 4x4
    } else {
      return 6; // Levels 11+ (Chapter 2-5+): 6x6
    }
  }

  /// Get grid size for a specific chapter and level
  /// Uses level ID to determine grid size
  static int getGridSizeForChapter(int chapter, int level) {
    final levelId = getLevelId(chapter, level);
    return getGridSizeForLevelId(levelId);
  }

  /// Get grid size directly from level ID
  static int getGridSize(int levelId) {
    return levelId <= 10 ? 4 : 6;
  }

  /// DEPRECATED: Use getGridSizeForChapter(chapter, level) instead
  @Deprecated('Use getGridSizeForChapter(chapter, level) with level parameter')
  static int getGridSizeForChapterOnly(int chapter) {
    // Fallback: assume level 1 for backward compatibility
    return getGridSizeForChapter(chapter, 1);
  }

  /// Get number of levels per chapter (NEW STRUCTURE: Master Spec)
  /// - Chapter 1: 10 levels
  /// - Chapter 2-5: 20 levels each
  /// - Chapter 6+: 20 levels (procedural)
  static int getLevelsPerChapter(int chapter) {
    if (chapter == 1) {
      return 10;
    } else {
      return 20; // Chapter 2+: 20 levels each
    }
  }

  /// Calculate difficulty factor based on level ID
  /// Difficulty Factor = percentage of cells to REMOVE (higher = harder)
  /// 
  /// REVISED Density-Based Masking System (Master Spec):
  /// - Level 1 (First Puzzle): Remove 50% (Keep 50% filled)
  /// - Levels 2-3 (Tutorial): Remove 45% (Keep 55% filled)
  /// - Levels 4-10 (Chapter 1): Remove 50% (Keep 50% filled)
  /// - Levels 11-30 (Chapter 2): Remove 55% (Keep 45% filled)
  /// - Levels 31-50 (Chapter 3): Remove 60% (Keep 40% filled)
  /// - Levels 51-70 (Chapter 4): Remove 65% (Keep 35% filled)
  /// - Levels 71+ (Chapter 5+): Remove 70% (Keep 30% filled)
  static double calculateDifficultyFactor(int chapter, int level) {
    final levelId = getLevelId(chapter, level);
    
    if (levelId <= 3) {
      return 0.55; // Levels 1-3: Remove 55% (Keep 45% -> ~7/16) - Satisfies Min 2 Empty
    } else if (levelId <= 10) {
      return 0.60; // Chapter 1: Remove 60% (Keep 40% -> ~6/16)
    } else if (levelId <= 30) {
      return 0.55; // Chapter 2: Medium
    } else if (levelId <= 50) {
      return 0.60; // Chapter 3: Harder
    } else if (levelId <= 70) {
      return 0.65; // Chapter 4: Very Hard
    } else {
      return 0.70; // Chapter 5+: Expert
    }
  }

  /// DEPRECATED: Use calculateDifficultyFactor instead
  @Deprecated('Use calculateDifficultyFactor instead')
  static double calculateDifficulty(int chapter, int level) {
    return calculateDifficultyFactor(chapter, level);
  }

  /// Generate seed for procedural level generation
  /// Uses: (ChapterID * 1000) + LevelID
  /// This ensures Level 5 is always the same puzzle for every user
  static int generateSeed(int chapter, int level) {
    final levelId = getLevelId(chapter, level);
    return chapter * 1000 + levelId;
  }

  /// Get next level after completing current level
  static LevelModel? getNextLevel(LevelModel current) {
    final maxLevel = getLevelsPerChapter(current.chapter);
    
    if (current.level < maxLevel) {
      // Next level in same chapter
      return LevelModel(chapter: current.chapter, level: current.level + 1);
    } else {
      // First level of next chapter
      return LevelModel(chapter: current.chapter + 1, level: 1);
    }
  }

  /// Get previous level (for completion animation)
  static LevelModel? getPreviousLevel(LevelModel current) {
    if (current.level > 1) {
      // Previous level in same chapter
      return LevelModel(chapter: current.chapter, level: current.level - 1);
    } else if (current.chapter > 1) {
      // Last level of previous chapter
      final prevChapter = current.chapter - 1;
      final maxLevel = getLevelsPerChapter(prevChapter);
      return LevelModel(chapter: prevChapter, level: maxLevel);
    } else {
      // Already at first level
      return null;
    }
  }

  /// Check if level is valid
  static bool isValidLevel(int chapter, int level) {
    if (chapter < 1) return false;
    final maxLevel = getLevelsPerChapter(chapter);
    return level >= 1 && level <= maxLevel;
  }

  /// Get total number of chapters (infinite play - procedural)
  /// For UI purposes, we'll show up to chapter 100
  static int getMaxChaptersForUI() {
    return 100;
  }
}

