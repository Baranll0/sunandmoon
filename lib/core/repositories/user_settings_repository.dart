import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../domain/user_settings_model.dart';

/// Repository for user settings
class UserSettingsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get settings document reference
  DocumentReference<Map<String, dynamic>> _settingsDoc(String uid) {
    return _firestore.collection('users').doc(uid).collection('game').doc('settings');
  }

  /// Load settings from Firestore
  Future<UserSettingsModel?> loadSettings(String uid) async {
    try {
      final doc = await _settingsDoc(uid).get();
      if (!doc.exists) return null;
      return UserSettingsModel.fromJson(doc.data()!);
    } catch (e) {
      debugPrint('Error loading settings: $e');
      return null;
    }
  }

  /// Save settings to Firestore
  Future<void> saveSettings(String uid, UserSettingsModel settings) async {
    try {
      final settingsData = settings.toJson();
      settingsData['updatedAt'] = FieldValue.serverTimestamp();

      await _settingsDoc(uid).set(settingsData, SetOptions(merge: true));
      debugPrint('Settings saved: $uid');
    } catch (e) {
      debugPrint('Error saving settings: $e');
      rethrow;
    }
  }
}

