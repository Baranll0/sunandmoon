import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

/// Service for managing haptic feedback
/// Uses Flutter's built-in HapticFeedback for web compatibility
class HapticService {
  static bool _enabled = true;
  
  /// Check if platform supports haptics
  static bool get _isSupported {
    if (kIsWeb) return false; // Web doesn't support haptics
    return true;
  }

  /// Enable or disable haptic feedback
  static void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// Check if haptics are enabled
  static bool get isEnabled => _enabled;

  /// Light impact haptic (for normal cell tap)
  static Future<void> lightImpact() async {
    if (!_enabled || !_isSupported) return;
    HapticFeedback.lightImpact();
  }

  /// Medium impact haptic (for undo/redo)
  static Future<void> mediumImpact() async {
    if (!_enabled || !_isSupported) return;
    HapticFeedback.mediumImpact();
  }

  /// Heavy impact haptic (for error/invalid move)
  static Future<void> heavyImpact() async {
    if (!_enabled || !_isSupported) return;
    HapticFeedback.heavyImpact();
  }

  /// Success vibration (when puzzle is solved)
  static Future<void> successVibration() async {
    if (!_enabled || !_isSupported) return;
    // Play a pattern: medium -> light -> medium
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.mediumImpact();
  }

  /// Selection haptic (for UI interactions)
  static Future<void> selectionClick() async {
    if (!_enabled || !_isSupported) return;
    HapticFeedback.selectionClick();
  }
}

