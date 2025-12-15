import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

/// Service for managing device ID
class DeviceIdService {
  static const String _keyDeviceId = 'device_id';
  static final Uuid _uuid = const Uuid();

  /// Get or create device ID
  static Future<String> getDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? deviceId = prefs.getString(_keyDeviceId);
      
      if (deviceId == null || deviceId.isEmpty) {
        deviceId = _uuid.v4();
        await prefs.setString(_keyDeviceId, deviceId);
        debugPrint('[DEVICE] Generated new device ID: $deviceId');
      }
      
      return deviceId;
    } catch (e) {
      debugPrint('[DEVICE] Error getting device ID: $e');
      // Fallback to a simple UUID
      return _uuid.v4();
    }
  }
}

