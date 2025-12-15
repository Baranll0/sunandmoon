import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../domain/game_progress_model.dart';
import '../../features/game/domain/models/level_model.dart';

/// Repository for game progress
class GameProgressRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get progress document reference
  DocumentReference<Map<String, dynamic>> _progressDoc(String uid) {
    return _firestore.collection('users').doc(uid).collection('game').doc('progress');
  }

  /// Load progress from Firestore
  Future<GameProgressModel?> loadProgress(String uid) async {
    try {
      final doc = await _progressDoc(uid).get();
      if (!doc.exists) return null;
      return GameProgressModel.fromJson(doc.data()!);
    } catch (e) {
      debugPrint('Error loading progress: $e');
      return null;
    }
  }

  /// Save progress to Firestore
  Future<void> saveProgress(String uid, GameProgressModel progress) async {
    try {
      final progressData = progress.toJson();
      progressData['updatedAt'] = FieldValue.serverTimestamp();

      await _progressDoc(uid).set(progressData, SetOptions(merge: true));
      debugPrint('Progress saved: $uid');
    } catch (e) {
      debugPrint('Error saving progress: $e');
      rethrow;
    }
  }

  /// Mark level as completed
  Future<void> completeLevel(String uid, LevelModel level) async {
    try {
      final chapterKey = level.chapter.toString();
      final progressDoc = _progressDoc(uid);

      // Get current progress
      final currentProgress = await loadProgress(uid);
      final completed = Map<String, List<int>>.from(
        currentProgress?.completed ?? {},
      );

      // Add level to completed list
      final chapterLevels = List<int>.from(completed[chapterKey] ?? []);
      if (!chapterLevels.contains(level.level)) {
        chapterLevels.add(level.level);
        chapterLevels.sort();
      }
      completed[chapterKey] = chapterLevels;

      // Update unlocked level if needed
      final unlockedChapter = currentProgress?.unlockedChapter ?? 1;
      final unlockedLevel = currentProgress?.unlockedLevel ?? 1;
      final currentLevelId = _getLevelId(level.chapter, level.level);
      final currentUnlockedId = _getLevelId(unlockedChapter, unlockedLevel);

      int newUnlockedChapter = unlockedChapter;
      int newUnlockedLevel = unlockedLevel;

      if (currentLevelId >= currentUnlockedId) {
        // Unlock next level
        final nextLevel = _getNextLevel(level);
        if (nextLevel != null) {
          newUnlockedChapter = nextLevel.chapter;
          newUnlockedLevel = nextLevel.level;
        }
      }

      // Update stats
      final stats = currentProgress?.stats ?? const GameStats();
      final newStats = stats.copyWith(
        totalSolved: stats.totalSolved + 1,
      );

      await progressDoc.set({
        'unlockedChapter': newUnlockedChapter,
        'unlockedLevel': newUnlockedLevel,
        'completed': completed,
        'stats': newStats.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('Level completed: ${level.chapter}-${level.level}');
    } catch (e) {
      debugPrint('Error completing level: $e');
      rethrow;
    }
  }

  /// Get next level
  LevelModel? _getNextLevel(LevelModel current) {
    // Simple implementation - can be enhanced
    if (current.level < 20) {
      return LevelModel(chapter: current.chapter, level: current.level + 1);
    } else {
      return LevelModel(chapter: current.chapter + 1, level: 1);
    }
  }

  /// Get level ID
  int _getLevelId(int chapter, int level) {
    // Simplified - should use LevelManager
    return (chapter - 1) * 20 + level;
  }
}

