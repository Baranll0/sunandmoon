/// Analytics events for tracking player behavior
enum AnalyticsEvent {
  /// Player started a level
  levelStart,
  
  /// Player completed a level
  levelComplete,
  
  /// Player abandoned a level (exited without completing)
  abandonLevel,
  
  /// Player used a free hint
  hintUsedFree,
  
  /// Player used a rewarded hint (e.g., from ad)
  hintUsedRewarded,
  
  /// Interstitial ad shown
  interstitialShown,
  
  /// Rewarded ad shown
  rewardedShown,
  
  /// Player opened settings
  settingsOpened,
  
  /// Player changed language
  languageChanged,
  
  /// Player opened "How to Play"
  howToPlayOpened,
}

/// Parameters for analytics events
class AnalyticsParams {
  final Map<String, dynamic> data;
  
  AnalyticsParams(this.data);
  
  /// Create params for level start
  factory AnalyticsParams.levelStart({
    required int chapter,
    required int level,
    required int gridSize,
    required double difficultyScore,
  }) {
    return AnalyticsParams({
      'chapter': chapter,
      'level': level,
      'gridSize': gridSize,
      'difficultyScore': difficultyScore,
    });
  }
  
  /// Create params for level complete
  factory AnalyticsParams.levelComplete({
    required int chapter,
    required int level,
    required int gridSize,
    required double difficultyScore,
    required int timeSpentSeconds,
    required int movesCount,
    required int hintsUsed,
  }) {
    return AnalyticsParams({
      'chapter': chapter,
      'level': level,
      'gridSize': gridSize,
      'difficultyScore': difficultyScore,
      'timeSpentSeconds': timeSpentSeconds,
      'movesCount': movesCount,
      'hintsUsed': hintsUsed,
    });
  }
  
  /// Create params for abandon level
  factory AnalyticsParams.abandonLevel({
    required int chapter,
    required int level,
    required int timeSpentSeconds,
    required int movesCount,
  }) {
    return AnalyticsParams({
      'chapter': chapter,
      'level': level,
      'timeSpentSeconds': timeSpentSeconds,
      'movesCount': movesCount,
    });
  }
  
  /// Create params for hint used
  factory AnalyticsParams.hintUsed({
    required String hintType, // 'free' or 'rewarded'
    required int chapter,
    required int level,
  }) {
    return AnalyticsParams({
      'hintType': hintType,
      'chapter': chapter,
      'level': level,
    });
  }
  
  /// Create params for language change
  factory AnalyticsParams.languageChanged({
    required String newLanguage, // 'en' or 'tr'
  }) {
    return AnalyticsParams({
      'language': newLanguage,
    });
  }
}

