import 'package:flutter/foundation.dart';
import '../services/sync_manager.dart';
import '../services/local_state_store.dart';
import '../services/level_manager.dart';
import '../utils/device_id_service.dart';
import '../domain/game_progress_model.dart';
import '../domain/current_run_model.dart';
import '../../features/game/domain/models/level_model.dart';

/// Repository for game state operations (UI/Controller integration)
class GameStateRepository {
  final SyncManager _syncManager;

  GameStateRepository(this._syncManager);

  LocalStateStore get _localStore => _syncManager.localStore;

  /// Update move (called on every user move)
  Future<void> updateMove({
    required int chapter,
    required int level,
    required int gridSize,
    required List<List<int>> givens,
    required List<List<int>> currentGrid,
    List<List<int>>? notes,
    required int steps,
    required int elapsedSeconds,
    required int hintsUsedToday,
    int? freeHintsRemaining,
    int? rewardedHintsEarned,
    bool? mistakesEnabled,
    bool? autoCheckEnabled,
    bool? pencilMode,
  }) async {
    try {
      final deviceId = await DeviceIdService.getDeviceId();
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      
      final currentRun = CurrentRunModel(
        chapter: chapter,
        level: level,
        gridSize: gridSize,
        givens: givens,
        currentGrid: currentGrid,
        notes: notes ?? [],
        movesCount: steps,
        elapsedSeconds: elapsedSeconds,
        hintsUsedThisLevel: hintsUsedToday,
        freeHintsRemaining: freeHintsRemaining ?? 0,
        rewardedHintsEarned: rewardedHintsEarned ?? 0,
        mistakesEnabled: mistakesEnabled ?? true,
        autoCheckEnabled: autoCheckEnabled ?? true,
        pencilMode: pencilMode ?? false,
        localUpdatedAtMs: nowMs,
        deviceId: deviceId,
        updatedAt: DateTime.now(),
      );

      // Save to local cache immediately
      await _localStore.saveCurrentRun(currentRun);

      // Mark as dirty and debounce flush
      _syncManager.markDirty(StateType.currentRun);
      _syncManager.flushDebounced();

      debugPrint('[REPO] Move updated (steps: $steps)');
    } catch (e) {
      debugPrint('[REPO] Error updating move: $e');
    }
  }

  /// Update progress on level complete
  Future<void> updateProgress({
    required LevelModel level,
    required int totalSolved,
    int? totalHintsUsed,
    int? totalPlaySeconds,
    int? totalMoves,
  }) async {
    try {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      
      // Load existing progress or create new
      final existing = _localStore.loadProgress();
      
      // CRITICAL FIX: unlockedLevel should be the NEXT level (newly unlocked), not the completed level
      // Get next level after completing this one
      final nextLevel = LevelManager.getNextLevel(level);
      final unlockedChapter = nextLevel?.chapter ?? level.chapter;
      final unlockedLevel = nextLevel?.level ?? level.level;
      
      // Update completed levels first
      final completed = Map<String, List<int>>.from(existing?.completed ?? {});
      final chapterKey = level.chapter.toString();
      final chapterLevels = List<int>.from(completed[chapterKey] ?? []);
      if (!chapterLevels.contains(level.level)) {
        chapterLevels.add(level.level);
        chapterLevels.sort();
      }
      completed[chapterKey] = chapterLevels;
      
      final progress = existing?.copyWith(
        unlockedChapter: unlockedChapter,
        unlockedLevel: unlockedLevel,
        completed: completed,
        stats: existing.stats.copyWith(
          totalSolved: totalSolved,
          totalHintsUsed: totalHintsUsed ?? existing.stats.totalHintsUsed,
          totalPlaySeconds: totalPlaySeconds ?? existing.stats.totalPlaySeconds,
          totalMoves: totalMoves ?? existing.stats.totalMoves,
        ),
        localUpdatedAtMs: nowMs,
        updatedAt: DateTime.now(),
      ) ?? GameProgressModel(
        unlockedChapter: unlockedChapter,
        unlockedLevel: unlockedLevel,
        completed: completed,
        stats: GameStats(
          totalSolved: totalSolved,
          totalHintsUsed: totalHintsUsed ?? 0,
          totalPlaySeconds: totalPlaySeconds ?? 0,
          totalMoves: totalMoves ?? 0,
        ),
        localUpdatedAtMs: nowMs,
        updatedAt: DateTime.now(),
      );

      final updatedProgress = progress;

      // Save to local cache
      await _localStore.saveProgress(updatedProgress);

      // Mark as dirty and flush immediately (level complete is important)
      _syncManager.markDirty(StateType.progress);
      await _syncManager.flushNow();

      debugPrint('[REPO] Progress updated (chapter: ${level.chapter}, level: ${level.level})');
    } catch (e) {
      debugPrint('[REPO] Error updating progress: $e');
    }
  }

  /// Clear current run (on level complete or restart)
  /// - Local: delete key currentRun + clear dirty flag
  /// - Remote: delete Firestore doc users/{uid}/state/currentRun
  Future<void> clearCurrentRun(String uid) async {
    try {
      // Clear local
      await _localStore.clearCurrentRun();
      _syncManager.clearDirty(StateType.currentRun);
      
      // Clear remote (with retry)
      await _syncManager.remoteStore.clearCurrentRun(uid);
      
      // Clear last flushed hash
      await _localStore.setLastFlushedRunHash('');

      debugPrint('[REPO] Current run cleared (local + remote)');
    } catch (e) {
      debugPrint('[REPO] Error clearing current run: $e');
    }
  }

  /// Resume game (load current run if exists)
  CurrentRunModel? resumeGame() {
    try {
      final currentRun = _localStore.loadCurrentRun();
      if (currentRun != null) {
        debugPrint('[REPO] Resuming game: Chapter ${currentRun.chapter}, Level ${currentRun.level}');
      }
      return currentRun;
    } catch (e) {
      debugPrint('[REPO] Error resuming game: $e');
      return null;
    }
  }

  /// Get current progress
  GameProgressModel? getCurrentProgress() {
    return _localStore.loadProgress();
  }

  /// Flush now (called on exit to map/home)
  Future<void> flushNow() async {
    await _syncManager.flushNow();
  }
}

