import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing app settings
class SettingsService {
  static const String _keyHapticsEnabled = 'haptics_enabled';
  static const String _keySoundsEnabled = 'sounds_enabled';
  static const String _keyAutoCheck = 'auto_check_enabled';

  /// Get haptics enabled state
  static Future<bool> getHapticsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHapticsEnabled) ?? true; // Default: enabled
  }

  /// Set haptics enabled state
  static Future<void> setHapticsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHapticsEnabled, enabled);
  }

  /// Get sounds enabled state
  static Future<bool> getSoundsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySoundsEnabled) ?? true; // Default: enabled
  }

  /// Set sounds enabled state
  static Future<void> setSoundsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySoundsEnabled, enabled);
  }

  /// Get auto-check enabled state
  static Future<bool> getAutoCheckEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAutoCheck) ?? true; // Default: enabled
  }

  /// Set auto-check enabled state
  static Future<void> setAutoCheckEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoCheck, enabled);
  }

  /// Initialize settings (load from preferences)
  static Future<void> initialize() async {
    final hapticsEnabled = await getHapticsEnabled();
    final soundsEnabled = await getSoundsEnabled();

    // Import and update services
    // Note: We'll need to import HapticService and SoundService here
    // but we'll do it in the main.dart or a settings provider
  }
}

