import 'package:shared_preferences/shared_preferences.dart';
import '../../features/game/domain/models/level_model.dart';
import 'level_manager.dart';

/// Service for managing game progress (current chapter/level)
class ProgressService {
  static const String _keyCurrentChapter = 'current_chapter';
  static const String _keyCurrentLevel = 'current_level';
  static const String _keyMaxUnlockedChapter = 'max_unlocked_chapter';
  static const String _keyMaxUnlockedLevel = 'max_unlocked_level';
  static const String _keyCompletedLevels = 'completed_levels';
  static const String _keyLastPlayedDate = 'last_played_date';

  /// Get current progress (chapter and level)
  /// CRITICAL FIX: Handle type mismatch (bool/int) gracefully
  static Future<LevelModel> getCurrentProgress() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Safely get chapter
    int chapter = 1;
    try {
      final chapterValue = prefs.get(_keyCurrentChapter);
      if (chapterValue is int) {
        chapter = chapterValue;
      } else if (chapterValue != null) {
        // Corrupted data - remove and use default
        await prefs.remove(_keyCurrentChapter);
      }
    } catch (e) {
      await prefs.remove(_keyCurrentChapter);
    }
    
    // Safely get level
    int level = 1;
    try {
      final levelValue = prefs.get(_keyCurrentLevel);
      if (levelValue is int) {
        level = levelValue;
      } else if (levelValue != null) {
        // Corrupted data - remove and use default
        await prefs.remove(_keyCurrentLevel);
      }
    } catch (e) {
      await prefs.remove(_keyCurrentLevel);
    }
    
    return LevelModel(chapter: chapter, level: level);
  }

  /// Save current progress
  static Future<void> saveProgress(LevelModel level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCurrentChapter, level.chapter);
    await prefs.setInt(_keyCurrentLevel, level.level);
  }

  /// Mark level as completed and advance to next level
  static Future<LevelModel?> completeLevel(LevelModel level) async {
    // Save completed level
    final prefs = await SharedPreferences.getInstance();
    final completedKey = '${level.chapter}_${level.level}';
    await prefs.setBool(completedKey, true);

    // Get next level using LevelManager
    final nextLevel = LevelManager.getNextLevel(level);
    
    if (nextLevel != null) {
      await saveProgress(nextLevel);
    }
    
    return nextLevel;
  }

  /// Check if a level is completed
  /// CRITICAL FIX: Handle int/bool type mismatch gracefully
  static Future<bool> isLevelCompleted(LevelModel level) async {
    final prefs = await SharedPreferences.getInstance();
    final completedKey = '${level.chapter}_${level.level}';
    
    try {
      final value = prefs.get(completedKey);
      if (value is bool) {
        return value;
      } else if (value is int) {
        // Handle legacy int values (1 = true, 0 = false)
        final isCompleted = value == 1;
        // Fix the corrupted data by converting to bool
        await prefs.setBool(completedKey, isCompleted);
        return isCompleted;
      }
      return false;
    } catch (e) {
      // If there's any error, remove the corrupted key and return false
      await prefs.remove(completedKey);
      return false;
    }
  }

  /// Get all completed levels (for statistics)
  /// CRITICAL FIX: Handle int/bool type mismatch gracefully
  static Future<List<LevelModel>> getCompletedLevels() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();
    final completedLevels = <LevelModel>[];

    for (final key in allKeys) {
      if (key.contains('_')) {
        try {
          // Try to get as bool first
          final value = prefs.get(key);
          bool isCompleted = false;
          
          if (value is bool) {
            isCompleted = value;
          } else if (value is int) {
            // Handle legacy int values (1 = true, 0 = false)
            isCompleted = value == 1;
            // Fix the corrupted data by converting to bool
            await prefs.setBool(key, isCompleted);
          } else if (value != null) {
            // Unknown type - delete corrupted key
            await prefs.remove(key);
            continue;
          }
          
          if (isCompleted) {
            final parts = key.split('_');
            if (parts.length == 2) {
              final chapter = int.tryParse(parts[0]);
              final level = int.tryParse(parts[1]);
              if (chapter != null && level != null) {
                completedLevels.add(LevelModel(chapter: chapter, level: level));
              }
            }
          }
        } catch (e) {
          // If there's any error, remove the corrupted key
          await prefs.remove(key);
        }
      }
    }

    return completedLevels;
  }

  /// Get max unlocked level (highest reached, not necessarily last played)
  static Future<LevelModel> getMaxUnlockedLevel() async {
    final prefs = await SharedPreferences.getInstance();
    
    int chapter = 1;
    int level = 1;
    
    try {
      final chapterValue = prefs.get(_keyMaxUnlockedChapter);
      if (chapterValue is int) {
        chapter = chapterValue;
      }
    } catch (e) {
      await prefs.remove(_keyMaxUnlockedChapter);
    }
    
    try {
      final levelValue = prefs.get(_keyMaxUnlockedLevel);
      if (levelValue is int) {
        level = levelValue;
      }
    } catch (e) {
      await prefs.remove(_keyMaxUnlockedLevel);
    }
    
    // If not set, use current progress
    if (chapter == 1 && level == 1) {
      final current = await getCurrentProgress();
      return current;
    }
    
    return LevelModel(chapter: chapter, level: level);
  }

  /// Save max unlocked level (when user reaches a new level)
  static Future<void> saveMaxUnlockedLevel(LevelModel level) async {
    final prefs = await SharedPreferences.getInstance();
    final currentMax = await getMaxUnlockedLevel();
    
    // Only update if new level is higher
    final currentMaxId = LevelManager.getLevelId(currentMax.chapter, currentMax.level);
    final newLevelId = LevelManager.getLevelId(level.chapter, level.level);
    
    if (newLevelId > currentMaxId) {
      await prefs.setInt(_keyMaxUnlockedChapter, level.chapter);
      await prefs.setInt(_keyMaxUnlockedLevel, level.level);
    }
  }

  /// Reset progress (for testing or new game)
  static Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCurrentChapter);
    await prefs.remove(_keyCurrentLevel);
    await prefs.remove(_keyMaxUnlockedChapter);
    await prefs.remove(_keyMaxUnlockedLevel);
    // Note: We don't clear completed levels to preserve statistics
  }
}

