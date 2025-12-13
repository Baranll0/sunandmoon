import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing daily hint limits
class HintService {
  static const String _keyHintsUsed = 'hints_used_today';
  static const String _keyLastHintDate = 'last_hint_date';
  static const int _dailyHintLimit = 5;

  /// Get remaining hints for today
  static Future<int> getRemainingHints() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_keyLastHintDate);
    final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD

    // If last hint date is not today, reset
    if (lastDate != today) {
      await prefs.setString(_keyLastHintDate, today);
      await prefs.setInt(_keyHintsUsed, 0);
      return _dailyHintLimit;
    }

    final hintsUsed = prefs.getInt(_keyHintsUsed) ?? 0;
    return (_dailyHintLimit - hintsUsed).clamp(0, _dailyHintLimit);
  }

  /// Check if user can use a hint
  static Future<bool> canUseHint() async {
    final remaining = await getRemainingHints();
    return remaining > 0;
  }

  /// Use a hint (decrement counter)
  static Future<bool> useHint() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_keyLastHintDate);
    final today = DateTime.now().toIso8601String().split('T')[0];

    // Reset if new day
    if (lastDate != today) {
      await prefs.setString(_keyLastHintDate, today);
      await prefs.setInt(_keyHintsUsed, 0);
    }

    final hintsUsed = prefs.getInt(_keyHintsUsed) ?? 0;
    
    if (hintsUsed >= _dailyHintLimit) {
      return false; // No hints remaining
    }

    await prefs.setInt(_keyHintsUsed, hintsUsed + 1);
    return true;
  }

  /// Watch ad to get more hints (placeholder - returns false for now)
  /// In the future, this will integrate with ad service
  static Future<bool> watchAdForHints() async {
    // TODO: Integrate with ad service when available
    // For now, just return false (ads not implemented)
    return false;
  }

  /// Get hints used today
  static Future<int> getHintsUsedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_keyLastHintDate);
    final today = DateTime.now().toIso8601String().split('T')[0];

    if (lastDate != today) {
      return 0;
    }

    return prefs.getInt(_keyHintsUsed) ?? 0;
  }
}

