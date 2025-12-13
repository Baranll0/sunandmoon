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

  /// Get grid size based on LEVEL ID (CRITICAL FIX)
  /// - Levels 1-15 (Chapter 1): MUST be 4x4
  /// - Levels 16+ (Chapter 2+): MUST be 6x6 (Chapter 2 artık 6x6!)
  /// - Levels 101+: MUST be 8x8
  /// NEVER generate 10x10 or 12x12 grids
  static int getGridSizeForLevelId(int levelId) {
    if (levelId <= 15) {
      return 4; // Levels 1-15 (Chapter 1): 4x4
    } else if (levelId <= 100) {
      return 6; // Levels 16-100 (Chapter 2+): 6x6
    } else {
      return 8; // Levels 101+: 8x8 (NEVER go above 8x8)
    }
  }

  /// Get grid size for a specific chapter and level
  /// Uses level ID to determine grid size
  /// Strict Rules: 1-20=4x4, 21-100=6x6, 101+=8x8
  static int getGridSizeForChapter(int chapter, int level) {
    final levelId = getLevelId(chapter, level);
    return getGridSizeForLevelId(levelId);
  }

  /// Get grid size directly from level ID
  /// Strict formula: levelId <= 20 ? 4 : (levelId <= 100 ? 6 : 8)
  static int getGridSize(int levelId) {
    return levelId <= 20 ? 4 : (levelId <= 100 ? 6 : 8);
  }

  /// DEPRECATED: Use getGridSizeForChapter(chapter, level) instead
  @Deprecated('Use getGridSizeForChapter(chapter, level) with level parameter')
  static int getGridSizeForChapterOnly(int chapter) {
    // Fallback: assume level 1 for backward compatibility
    return getGridSizeForChapter(chapter, 1);
  }

  /// Get number of levels per chapter
  static int getLevelsPerChapter(int chapter) {
    if (chapter <= 2) {
      return 15; // Chapters 1-2: 15 levels
    } else if (chapter <= 12) {
      return 20; // Chapters 3-12: 20 levels
    } else {
      return 20; // Chapter 13+: 20 levels
    }
  }

  /// Calculate difficulty factor based on level ID
  /// Difficulty Factor = percentage of cells to KEEP (lower = harder)
  /// 
  /// NEW Density-Based Masking System:
  /// - Levels 1-5 (Tutorial): Keep 60% filled (40% empty)
  /// - Levels 6-15 (Easy): Keep 45% filled (55% empty) - CRITICAL: Level 13 must be ~7-8 cells
  /// - Levels 16-30 (Medium): Keep 35% filled (65% empty)
  /// - Levels 31+ (Hard): Keep 30% filled (70% empty)
  static double calculateDifficultyFactor(int chapter, int level) {
    final levelId = getLevelId(chapter, level);
    
    if (levelId <= 5) {
      return 0.40; // Tutorial: Keep 60% filled (remove 40%)
    } else if (levelId <= 15) {
      return 0.55; // Easy: Keep 45% filled (remove 55%) - Level 13: 16 * 0.45 = ~7 cells
    } else if (levelId <= 30) {
      return 0.65; // Medium: Keep 35% filled (remove 65%)
    } else {
      return 0.70; // Hard: Keep 30% filled (remove 70%)
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

