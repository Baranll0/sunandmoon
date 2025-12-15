import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../domain/game_progress_model.dart';
import '../domain/current_run_model.dart';

/// Local state store using Hive for offline-first caching
class LocalStateStore {
  static const String _boxName = 'app_state';
  static const String _keyProgress = 'progress';
  static const String _keyCurrentRun = 'currentRun';
  static const String _keyDirtyFlags = 'dirtyFlags';
  static const String _keyLastSyncAt = 'lastSyncAt';
  static const String _keyLastFlushedProgressHash = 'lastFlushedProgressHash';
  static const String _keyLastFlushedRunHash = 'lastFlushedRunHash';

  Box? _box;

  /// Initialize Hive box
  Future<void> initialize() async {
    try {
      _box = await Hive.openBox(_boxName);
      debugPrint('[LOCAL] Hive box initialized: $_boxName');
    } catch (e) {
      debugPrint('[LOCAL] Error initializing Hive box: $e');
      rethrow;
    }
  }

  /// Get box (ensure initialized)
  Box get box {
    if (_box == null) {
      throw Exception('LocalStateStore not initialized. Call initialize() first.');
    }
    return _box!;
  }

  /// Load progress from local cache
  GameProgressModel? loadProgress() {
    try {
      final jsonString = box.get(_keyProgress) as String?;
      if (jsonString == null) return null;

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return GameProgressModel.fromJson(json);
    } catch (e) {
      debugPrint('[LOCAL] Error loading progress: $e');
      return null;
    }
  }

  /// Save progress to local cache
  Future<void> saveProgress(GameProgressModel progress) async {
    try {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final json = progress.toJson();
      // Set local timestamp for conflict resolution
      json['localUpdatedAtMs'] = nowMs;
      // Keep updatedAt if exists, otherwise set to local timestamp
      if (json['updatedAt'] == null) {
        json['updatedAt'] = nowMs;
      }
      final jsonString = jsonEncode(json);
      await box.put(_keyProgress, jsonString);
      debugPrint('[LOCAL] Progress saved (localUpdatedAtMs: $nowMs)');
    } catch (e) {
      debugPrint('[LOCAL] Error saving progress: $e');
    }
  }

  /// Load current run from local cache
  CurrentRunModel? loadCurrentRun() {
    try {
      final jsonString = box.get(_keyCurrentRun) as String?;
      if (jsonString == null) return null;

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return CurrentRunModel.fromJson(json);
    } catch (e) {
      debugPrint('[LOCAL] Error loading current run: $e');
      return null;
    }
  }

  /// Save current run to local cache
  Future<void> saveCurrentRun(CurrentRunModel run) async {
    try {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final json = run.toJson();
      // Set local timestamp for conflict resolution
      json['localUpdatedAtMs'] = nowMs;
      // Keep updatedAt if exists, otherwise set to local timestamp
      if (json['updatedAt'] == null) {
        json['updatedAt'] = nowMs;
      }
      final jsonString = jsonEncode(json);
      await box.put(_keyCurrentRun, jsonString);
      debugPrint('[LOCAL] Current run saved (localUpdatedAtMs: $nowMs)');
    } catch (e) {
      debugPrint('[LOCAL] Error saving current run: $e');
    }
  }

  /// Clear current run from local cache
  Future<void> clearCurrentRun() async {
    try {
      await box.delete(_keyCurrentRun);
      debugPrint('[LOCAL] Current run cleared');
    } catch (e) {
      debugPrint('[LOCAL] Error clearing current run: $e');
    }
  }

  /// Load dirty flags
  Map<String, bool> loadDirtyFlags() {
    try {
      final jsonString = box.get(_keyDirtyFlags) as String?;
      if (jsonString == null) return {};
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return json.map((key, value) => MapEntry(key, value as bool));
    } catch (e) {
      debugPrint('[LOCAL] Error loading dirty flags: $e');
      return {};
    }
  }

  /// Set dirty flag
  Future<void> setDirty(String flag, bool value) async {
    try {
      final flags = loadDirtyFlags();
      flags[flag] = value;
      await box.put(_keyDirtyFlags, jsonEncode(flags));
      debugPrint('[LOCAL] Dirty flag set: $flag = $value');
    } catch (e) {
      debugPrint('[LOCAL] Error setting dirty flag: $e');
    }
  }

  /// Clear dirty flag
  Future<void> clearDirty(String flag) async {
    await setDirty(flag, false);
  }

  /// Get last sync timestamp
  DateTime? getLastSyncAt() {
    try {
      final timestamp = box.get(_keyLastSyncAt) as int?;
      if (timestamp == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      debugPrint('[LOCAL] Error getting last sync: $e');
      return null;
    }
  }

  /// Update last sync timestamp
  Future<void> updateLastSyncAt() async {
    try {
      await box.put(_keyLastSyncAt, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('[LOCAL] Error updating last sync: $e');
    }
  }

  /// Get last flushed hash for progress (to skip duplicate writes)
  String? getLastFlushedProgressHash() {
    try {
      return box.get(_keyLastFlushedProgressHash) as String?;
    } catch (e) {
      debugPrint('[LOCAL] Error getting last flushed progress hash: $e');
      return null;
    }
  }

  /// Set last flushed hash for progress
  Future<void> setLastFlushedProgressHash(String hash) async {
    try {
      await box.put(_keyLastFlushedProgressHash, hash);
    } catch (e) {
      debugPrint('[LOCAL] Error setting last flushed progress hash: $e');
    }
  }

  /// Get last flushed hash for current run
  String? getLastFlushedRunHash() {
    try {
      return box.get(_keyLastFlushedRunHash) as String?;
    } catch (e) {
      debugPrint('[LOCAL] Error getting last flushed run hash: $e');
      return null;
    }
  }

  /// Set last flushed hash for current run
  Future<void> setLastFlushedRunHash(String hash) async {
    try {
      await box.put(_keyLastFlushedRunHash, hash);
    } catch (e) {
      debugPrint('[LOCAL] Error setting last flushed run hash: $e');
    }
  }

  /// Get last flushed hash for settings
  String? getLastFlushedSettingsHash() {
    try {
      return box.get('lastFlushedSettingsHash') as String?;
    } catch (e) {
      debugPrint('[LOCAL] Error getting last flushed settings hash: $e');
      return null;
    }
  }

  /// Set last flushed hash for settings
  Future<void> setLastFlushedSettingsHash(String hash) async {
    try {
      await box.put('lastFlushedSettingsHash', hash);
    } catch (e) {
      debugPrint('[LOCAL] Error setting last flushed settings hash: $e');
    }
  }

  /// Clear all local data (for testing/logout)
  Future<void> clearAll() async {
    try {
      await box.clear();
      debugPrint('[LOCAL] All local data cleared');
    } catch (e) {
      debugPrint('[LOCAL] Error clearing all data: $e');
    }
  }
}

