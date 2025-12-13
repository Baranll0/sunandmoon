import 'package:flutter/foundation.dart';
import 'analytics_event.dart';

/// Analytics service interface
/// Implementations can plug in Firebase, Mixpanel, etc.
abstract class AnalyticsService {
  /// Log an event with optional parameters
  void logEvent(AnalyticsEvent event, [AnalyticsParams? params]);
  
  /// Set user property
  void setUserProperty(String key, dynamic value);
  
  /// Track screen view
  void trackScreen(String screenName);
}

/// Default implementation (no-op, logs to console in debug mode)
class DefaultAnalyticsService implements AnalyticsService {
  @override
  void logEvent(AnalyticsEvent event, [AnalyticsParams? params]) {
    if (kDebugMode) {
      print('📊 Analytics: ${event.name}${params != null ? ' (${params.data})' : ''}');
    }
    // In production, this would send to Firebase/Mixpanel/etc.
  }
  
  @override
  void setUserProperty(String key, dynamic value) {
    if (kDebugMode) {
      print('📊 Analytics Property: $key = $value');
    }
  }
  
  @override
  void trackScreen(String screenName) {
    if (kDebugMode) {
      print('📊 Analytics Screen: $screenName');
    }
  }
}

/// No-op implementation (for testing or when analytics is disabled)
class NoOpAnalyticsService implements AnalyticsService {
  @override
  void logEvent(AnalyticsEvent event, [AnalyticsParams? params]) {
    // Do nothing
  }
  
  @override
  void setUserProperty(String key, dynamic value) {
    // Do nothing
  }
  
  @override
  void trackScreen(String screenName) {
    // Do nothing
  }
}

