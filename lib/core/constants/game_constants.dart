/// Game Constants
class GameConstants {
  // Grid Sizes (updated to support 4x4, 6x6, 8x8)
  static const int sizeEasy = 4; // Updated for chapter system
  static const int sizeMedium = 6;
  static const int sizeHard = 8;
  static const int sizeExpert = 12; // Kept for backward compatibility

  // Cell Values
  static const int cellEmpty = 0;
  static const int cellSun = 1; // Orange
  static const int cellMoon = 2; // Blue

  // Constraint Markers (for advanced levels)
  static const String constraintDifferent = 'x'; // Must be different
  static const String constraintSame = '='; // Must be same

  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Haptic Feedback Types
  static const String hapticLight = 'light';
  static const String hapticMedium = 'medium';
  static const String hapticHeavy = 'heavy';

  // Storage Keys
  static const String hiveBoxName = 'sun_moon_puzzle';
  static const String prefsBestTimes = 'best_times';
  static const String prefsSettings = 'settings';
  static const String prefsStatistics = 'statistics';
}

