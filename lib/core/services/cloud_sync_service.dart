import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/user_repository.dart';
import '../repositories/game_progress_repository.dart';
import '../repositories/current_run_repository.dart';
import '../repositories/user_settings_repository.dart';
import '../domain/game_progress_model.dart';
import '../domain/current_run_model.dart';
import '../domain/user_settings_model.dart';
import '../domain/user_model.dart';
import '../../features/game/domain/models/level_model.dart';

/// Service for syncing local and cloud data
class CloudSyncService {
  final UserRepository _userRepository = UserRepository();
  final GameProgressRepository _progressRepository = GameProgressRepository();
  final CurrentRunRepository _currentRunRepository = CurrentRunRepository();
  final UserSettingsRepository _settingsRepository = UserSettingsRepository();

  static const String _keyLastSyncTime = 'last_sync_time';
  static const String _keyLocalProgress = 'local_progress';
  static const String _keyLocalCurrentRun = 'local_current_run';
  static const String _keyLocalSettings = 'local_settings';

  /// Sync user data (local + remote merge)
  Future<void> syncUserData(String uid, UserModel user) async {
    try {
      // Update last seen
      await _userRepository.updateLastSeen(uid);

      // Upsert user document
      await _userRepository.upsertUser(uid, user);
      debugPrint('User data synced: $uid');
    } catch (e) {
      debugPrint('Error syncing user data: $e');
    }
  }

  /// Sync progress (merge local and remote, use latest)
  Future<GameProgressModel?> syncProgress(String uid) async {
    try {
      // Load from local cache
      final localProgress = await _loadLocalProgress();

      // Load from remote
      final remoteProgress = await _progressRepository.loadProgress(uid);

      // Merge: use remote if newer, otherwise keep local
      GameProgressModel? mergedProgress;
      if (remoteProgress != null && localProgress != null) {
        // Compare timestamps
        final remoteTime = remoteProgress.updatedAt ?? DateTime(1970);
        final localTime = localProgress.updatedAt ?? DateTime(1970);

        if (remoteTime.isAfter(localTime)) {
          mergedProgress = remoteProgress;
          await _saveLocalProgress(remoteProgress);
        } else {
          mergedProgress = localProgress;
          await _progressRepository.saveProgress(uid, localProgress);
        }
      } else if (remoteProgress != null) {
        mergedProgress = remoteProgress;
        await _saveLocalProgress(remoteProgress);
      } else if (localProgress != null) {
        mergedProgress = localProgress;
        await _progressRepository.saveProgress(uid, localProgress);
      }

      // Update last sync time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastSyncTime, DateTime.now().toIso8601String());

      return mergedProgress;
    } catch (e) {
      debugPrint('Error syncing progress: $e');
      // Return local cache if remote fails
      return await _loadLocalProgress();
    }
  }

  /// Sync current run (merge local and remote)
  Future<CurrentRunModel?> syncCurrentRun(String uid) async {
    try {
      // Load from local cache
      final localRun = await _loadLocalCurrentRun();

      // Load from remote
      final remoteRun = await _currentRunRepository.loadCurrentRun(uid);

      // Merge: use remote if newer
      CurrentRunModel? mergedRun;
      if (remoteRun != null && localRun != null) {
        final remoteTime = remoteRun.updatedAt ?? DateTime(1970);
        final localTime = localRun.updatedAt ?? DateTime(1970);

        if (remoteTime.isAfter(localTime)) {
          mergedRun = remoteRun;
          await _saveLocalCurrentRun(remoteRun);
        } else {
          mergedRun = localRun;
          await _currentRunRepository.saveCurrentRun(uid, localRun);
        }
      } else if (remoteRun != null) {
        mergedRun = remoteRun;
        await _saveLocalCurrentRun(remoteRun);
      } else if (localRun != null) {
        mergedRun = localRun;
        await _currentRunRepository.saveCurrentRun(uid, localRun);
      }

      return mergedRun;
    } catch (e) {
      debugPrint('Error syncing current run: $e');
      return await _loadLocalCurrentRun();
    }
  }

  /// Sync settings
  Future<UserSettingsModel?> syncSettings(String uid) async {
    try {
      final remoteSettings = await _settingsRepository.loadSettings(uid);
      if (remoteSettings != null) {
        await _saveLocalSettings(remoteSettings);
        return remoteSettings;
      }
      return await _loadLocalSettings();
    } catch (e) {
      debugPrint('Error syncing settings: $e');
      return await _loadLocalSettings();
    }
  }

  /// Save progress locally
  Future<void> _saveLocalProgress(GameProgressModel progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLocalProgress, progress.toJson().toString());
    } catch (e) {
      debugPrint('Error saving local progress: $e');
    }
  }

  /// Load progress from local cache
  Future<GameProgressModel?> _loadLocalProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyLocalProgress);
      if (jsonString == null) return null;
      // Parse JSON string to Map
      // Note: This is simplified - should use proper JSON parsing
      return null; // TODO: Implement proper JSON parsing
    } catch (e) {
      debugPrint('Error loading local progress: $e');
      return null;
    }
  }

  /// Save current run locally
  Future<void> _saveLocalCurrentRun(CurrentRunModel run) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLocalCurrentRun, run.toJson().toString());
    } catch (e) {
      debugPrint('Error saving local current run: $e');
    }
  }

  /// Load current run from local cache
  Future<CurrentRunModel?> _loadLocalCurrentRun() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyLocalCurrentRun);
      if (jsonString == null) return null;
      // TODO: Implement proper JSON parsing
      return null;
    } catch (e) {
      debugPrint('Error loading local current run: $e');
      return null;
    }
  }

  /// Save settings locally
  Future<void> _saveLocalSettings(UserSettingsModel settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLocalSettings, settings.toJson().toString());
    } catch (e) {
      debugPrint('Error saving local settings: $e');
    }
  }

  /// Load settings from local cache
  Future<UserSettingsModel?> _loadLocalSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyLocalSettings);
      if (jsonString == null) return null;
      // TODO: Implement proper JSON parsing
      return null;
    } catch (e) {
      debugPrint('Error loading local settings: $e');
      return null;
    }
  }
}

