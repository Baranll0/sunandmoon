import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_state_store.dart';
import 'remote_state_store.dart';
import '../domain/game_progress_model.dart';
import '../domain/current_run_model.dart';
import '../utils/device_id_service.dart';
import 'auth_service.dart';

/// State types for dirty flags
enum StateType {
  progress,
  currentRun,
  settings,
}

/// Sync manager for offline-first synchronization
class SyncManager extends WidgetsBindingObserver {
  final LocalStateStore _localStore = LocalStateStore();
  final RemoteStateStore _remoteStore = RemoteStateStore();
  final AuthService _authService = AuthService();

  Timer? _debounceTimer;
  final Map<StateType, bool> _dirtyFlags = {};
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnline = true;

  /// Initialize sync manager
  Future<void> initialize() async {
    await _localStore.initialize();
    
    // Listen to connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final wasOffline = !_isOnline;
        // Check if any connection is available
        _isOnline = results.any((result) => result != ConnectivityResult.none);
        
        debugPrint('[SYNC] Connectivity changed: ${_isOnline ? "ONLINE" : "OFFLINE"}');
        
        if (wasOffline && _isOnline) {
          // Just came online - flush immediately
          flushNow();
        }
      },
    );

    // Listen to app lifecycle
    WidgetsBinding.instance.addObserver(this);

    // Check initial connectivity
    final connectivity = await Connectivity().checkConnectivity();
    _isOnline = connectivity.any((result) => result != ConnectivityResult.none);

    debugPrint('[SYNC] SyncManager initialized (online: $_isOnline)');
  }

  /// Dispose resources
  void dispose() {
    _debounceTimer?.cancel();
    _connectivitySubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.inactive) {
      debugPrint('[SYNC] App paused/inactive - flushing');
      flushNow();
    }
  }

  /// Mark state as dirty (needs sync)
  void markDirty(StateType type) {
    _dirtyFlags[type] = true;
    _localStore.setDirty(type.name, true);
    debugPrint('[SYNC] Marked dirty: ${type.name}');
  }

  /// Clear dirty flag
  void clearDirty(StateType type) {
    _dirtyFlags[type] = false;
    _localStore.clearDirty(type.name);
  }

  /// Flush debounced (wait 2-3 seconds before sync)
  void flushDebounced() {
    if (!_isOnline) {
      debugPrint('[SYNC] Offline - skipping debounced flush');
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 2000), () {
      flushNow();
    });
  }

  /// Flush immediately (no debounce) with diff check
  Future<void> flushNow() async {
    final uid = _authService.currentUserId;
    if (uid == null) {
      debugPrint('[SYNC] No user ID - skipping flush');
      return;
    }

    if (!_isOnline) {
      debugPrint('[SYNC] Offline - cannot flush');
      return;
    }

    _debounceTimer?.cancel();

    try {
      // Flush progress if dirty
      if (_dirtyFlags[StateType.progress] == true) {
        final progress = _localStore.loadProgress();
        if (progress != null) {
          // Check if changed (skip duplicate writes)
          final currentHash = _computeProgressHash(progress);
          final lastHash = _localStore.getLastFlushedProgressHash();
          
          if (currentHash == lastHash) {
            debugPrint('[SYNC] Skipped write (no diff): Progress');
            clearDirty(StateType.progress);
          } else {
            await _remoteStore.saveProgress(uid, progress);
            await _localStore.setLastFlushedProgressHash(currentHash);
            clearDirty(StateType.progress);
            debugPrint('[SYNC] Progress flushed');
          }
        }
      }

      // Flush current run if dirty
      if (_dirtyFlags[StateType.currentRun] == true) {
        final currentRun = _localStore.loadCurrentRun();
        if (currentRun != null) {
          // Check if changed (skip duplicate writes)
          final currentHash = _computeCurrentRunHash(currentRun);
          final lastHash = _localStore.getLastFlushedRunHash();
          
          if (currentHash == lastHash) {
            debugPrint('[SYNC] Skipped write (no diff): CurrentRun');
            clearDirty(StateType.currentRun);
          } else {
            await _remoteStore.saveCurrentRun(uid, currentRun);
            await _localStore.setLastFlushedRunHash(currentHash);
            clearDirty(StateType.currentRun);
            debugPrint('[SYNC] Current run flushed');
          }
        }
      }

      // Flush settings if dirty
      if (_dirtyFlags[StateType.settings] == true) {
        final settings = await _loadLocalSettings();
        // Check if changed
        final currentHash = _computeSettingsHash(settings);
        final lastHash = _localStore.getLastFlushedSettingsHash();

        if (currentHash == lastHash) {
          debugPrint('[SYNC] Skipped write (no diff): Settings');
          clearDirty(StateType.settings);
        } else {
          await _remoteStore.saveSettings(uid, settings);
          await _localStore.setLastFlushedSettingsHash(currentHash);
          clearDirty(StateType.settings);
          debugPrint('[SYNC] Settings flushed');
        }
      }

      await _localStore.updateLastSyncAt();
    } catch (e) {
      debugPrint('[SYNC] Error flushing: $e');
    }
  }

  /// Load local settings (from SharedPreferences)
  Future<Map<String, dynamic>> _loadLocalSettings() async {
    // Import here to avoid cycle if possible, or assume it works
    // We'll use SharedPreferences directly to be safe
    // Ideally we should use SettingsService getters but they are static
    // Let's iterate known keys
    final prefs = await SharedPreferences.getInstance();
    return {
      'haptics_enabled': prefs.getBool('haptics_enabled') ?? true,
      'sounds_enabled': prefs.getBool('sounds_enabled') ?? true,
      'auto_check_enabled': prefs.getBool('auto_check_enabled') ?? true,
      'locale': prefs.getString('app_locale') ?? 'tr', // Default TR if not set, key must match LocaleProvider
    };
  }

  /// Save settings to local (SharedPreferences)
  Future<void> _saveLocalSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    if (settings.containsKey('haptics_enabled')) {
      await prefs.setBool('haptics_enabled', settings['haptics_enabled']);
    }
    if (settings.containsKey('sounds_enabled')) {
      await prefs.setBool('sounds_enabled', settings['sounds_enabled']);
    }
    if (settings.containsKey('auto_check_enabled')) {
      await prefs.setBool('auto_check_enabled', settings['auto_check_enabled']);
    }
    if (settings.containsKey('locale')) {
      // NOTE: This key 'app_locale' must match what LocaleNotifier uses!
      await prefs.setString('app_locale', settings['locale']);
    }
    
    // We should notify services/listeners to update runtime state
    // But since this runs on login, restarting app or simple state update might be needed.
    // For now, next App launch will pick it up.
    // TODO: Trigger runtime update if possible.
  }

  /// Compute hash for progress (for diff checking)
  String _computeProgressHash(GameProgressModel progress) {
    final data = progress.toJson();
    // Remove timestamps for comparison
    data.remove('updatedAt');
    data.remove('localUpdatedAtMs');
    final jsonString = jsonEncode(data);
    return jsonString.hashCode.toString();
  }

  /// Compute hash for current run (for diff checking)
  String _computeCurrentRunHash(CurrentRunModel run) {
    final data = run.toJson();
    // Remove timestamps for comparison
    data.remove('updatedAt');
    data.remove('lastActionAt');
    data.remove('localUpdatedAtMs');
    final jsonString = jsonEncode(data);
    return jsonString.hashCode.toString();
  }

  /// Compute hash for settings
  String _computeSettingsHash(Map<String, dynamic> settings) {
    final jsonString = jsonEncode(settings);
    return jsonString.hashCode.toString();
  }

  /// Sync on login (fetch remote, resolve conflicts, align local/remote)
  Future<void> syncOnLogin(String uid) async {
    debugPrint('[SYNC] Starting sync on login: $uid');

    try {
      // Load local state
      final localProgress = _localStore.loadProgress();
      final localCurrentRun = _localStore.loadCurrentRun();

      // Fetch remote state
      final remoteProgress = await _remoteStore.fetchProgress(uid);
      final remoteCurrentRun = await _remoteStore.fetchCurrentRun(uid);
      final remoteSettings = await _remoteStore.fetchSettings(uid);

      // Resolve conflicts and merge
      await _resolveAndMerge(
        localProgress,
        remoteProgress,
        localCurrentRun,
        remoteCurrentRun,
        remoteSettings,
        uid,
      );

      await _localStore.updateLastSyncAt();
      debugPrint('[SYNC] Sync on login completed');
    } catch (e) {
      debugPrint('[SYNC] Error syncing on login: $e');
    }
  }

  /// Resolve conflicts and merge local/remote
  Future<void> _resolveAndMerge(
    GameProgressModel? localProgress,
    GameProgressModel? remoteProgress,
    CurrentRunModel? localCurrentRun,
    CurrentRunModel? remoteCurrentRun,
    Map<String, dynamic>? remoteSettings,
    String uid,
  ) async {
    // Progress conflict resolution - use MERGE strategy
    if (localProgress != null && remoteProgress != null) {
      // Merge progress (don't use latest wins, merge intelligently)
      final merged = _mergeProgress(localProgress, remoteProgress);
      await _localStore.saveProgress(merged);
      await _remoteStore.saveProgress(uid, merged);
      debugPrint('[SYNC] mergeProgress applied');
    } else if (remoteProgress != null) {
      // Only remote exists
      await _localStore.saveProgress(remoteProgress);
      debugPrint('[SYNC] Progress: using remote (only)');
    } else if (localProgress != null) {
      // Only local exists - save to remote
      await _remoteStore.saveProgress(uid, localProgress);
      debugPrint('[SYNC] Progress: using local (only)');
    }

    // Current run conflict resolution - use LWW with deviceId check
    if (localCurrentRun != null && remoteCurrentRun != null) {
      final localTimeMs = localCurrentRun.localUpdatedAtMs;
      final remoteTimeMs = remoteCurrentRun.localUpdatedAtMs;
      final currentDeviceId = await DeviceIdService.getDeviceId();

      // Compare local timestamps (not server timestamps)
      if (remoteTimeMs > localTimeMs) {
        // Remote is newer
        if (remoteCurrentRun.deviceId != currentDeviceId) {
          // Different device - log warning but keep remote
          debugPrint('[SYNC] Current run: remote newer from different device (${remoteCurrentRun.deviceId} vs $currentDeviceId) - keeping remote');
        }
        await _localStore.saveCurrentRun(remoteCurrentRun);
        debugPrint('[SYNC] Current run: using remote (newer localUpdatedAtMs)');
      } else {
        // Local is newer - save to remote
        final updatedRun = localCurrentRun.copyWith(deviceId: currentDeviceId);
        await _localStore.saveCurrentRun(updatedRun);
        await _remoteStore.saveCurrentRun(uid, updatedRun);
        debugPrint('[SYNC] Current run: using local (newer localUpdatedAtMs)');
      }
    } else if (remoteCurrentRun != null) {
      // Only remote exists
      await _localStore.saveCurrentRun(remoteCurrentRun);
      debugPrint('[SYNC] Current run: using remote (only)');
    } else if (localCurrentRun != null) {
      // Only local exists - save to remote with deviceId
      final currentDeviceId = await DeviceIdService.getDeviceId();
      final updatedRun = localCurrentRun.copyWith(deviceId: currentDeviceId);
      await _localStore.saveCurrentRun(updatedRun);
      await _remoteStore.saveCurrentRun(uid, updatedRun);
      debugPrint('[SYNC] Current run: using local (only)');
    }

    // Settings resolution - Remote Wins (Simple strategy for now)
    // If remote has settings, overwrite local
    if (remoteSettings != null) {
      await _saveLocalSettings(remoteSettings);
      debugPrint('[SYNC] Settings: using remote');
      // Note: This won't update UI immediately unless we reload or notify
    } else {
      // Remote is empty, push local
      if (_isOnline) {
        // We act like it's dirty
        markDirty(StateType.settings);
      }
    }
  }

  /// Merge progress from local and remote (intelligent merge, not latest wins)
  GameProgressModel _mergeProgress(
    GameProgressModel local,
    GameProgressModel remote,
  ) {
    // unlockedChapter: max(local, remote)
    final mergedChapter = local.unlockedChapter > remote.unlockedChapter
        ? local.unlockedChapter
        : remote.unlockedChapter;

    // unlockedLevel: max(local, remote) for the merged chapter
    final mergedLevel = local.unlockedChapter == mergedChapter &&
            remote.unlockedChapter == mergedChapter
        ? (local.unlockedLevel > remote.unlockedLevel
            ? local.unlockedLevel
            : remote.unlockedLevel)
        : (local.unlockedChapter == mergedChapter
            ? local.unlockedLevel
            : remote.unlockedLevel);

    // completed: union (treat level lists as sets, remove duplicates)
    final mergedCompleted = <String, List<int>>{};
    final allChapters = {...local.completed.keys, ...remote.completed.keys};
    for (final chapterKey in allChapters) {
      final localLevels = local.completed[chapterKey] ?? [];
      final remoteLevels = remote.completed[chapterKey] ?? [];
      final union = {...localLevels, ...remoteLevels}.toList()..sort();
      mergedCompleted[chapterKey] = union;
    }

    // stats: SUM for cumulative values (totalSolved, totalMoves, totalPlaySeconds, totalHintsUsed)
    // Note: We use MAX to avoid double-counting if user plays same level on multiple devices
    // But if stats are truly cumulative, use SUM. For now, use MAX to be safe.
    final mergedStats = GameStats(
      totalSolved: local.stats.totalSolved > remote.stats.totalSolved
          ? local.stats.totalSolved
          : remote.stats.totalSolved, // MAX (avoid double-counting)
      totalHintsUsed: local.stats.totalHintsUsed > remote.stats.totalHintsUsed
          ? local.stats.totalHintsUsed
          : remote.stats.totalHintsUsed, // MAX
      totalPlaySeconds: local.stats.totalPlaySeconds > remote.stats.totalPlaySeconds
          ? local.stats.totalPlaySeconds
          : remote.stats.totalPlaySeconds, // MAX
      totalMoves: local.stats.totalMoves > remote.stats.totalMoves
          ? local.stats.totalMoves
          : remote.stats.totalMoves, // MAX
    );

    // Use the newer localUpdatedAtMs
    final mergedLocalUpdatedAtMs = local.localUpdatedAtMs > remote.localUpdatedAtMs
        ? local.localUpdatedAtMs
        : remote.localUpdatedAtMs;

    return GameProgressModel(
      unlockedChapter: mergedChapter,
      unlockedLevel: mergedLevel,
      completed: mergedCompleted,
      stats: mergedStats,
      localUpdatedAtMs: mergedLocalUpdatedAtMs,
      updatedAt: DateTime.now(), // Will be set to server timestamp on save
    );
  }

  /// Get local store (for direct access if needed)
  LocalStateStore get localStore => _localStore;

  /// Get remote store (for direct access if needed)
  RemoteStateStore get remoteStore => _remoteStore;

  /// Get auth service (for direct access if needed)
  AuthService get authService => _authService;

  /// Check if online
  bool get isOnline => _isOnline;
}

