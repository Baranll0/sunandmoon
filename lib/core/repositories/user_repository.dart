import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../domain/user_model.dart';

/// Repository for user data
class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get user document reference
  DocumentReference<Map<String, dynamic>> _userDoc(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  /// Create or update user document
  Future<void> upsertUser(String uid, UserModel user) async {
    try {
      final userData = user.toJson();
      // Convert DateTime to Timestamp for Firestore
      if (userData['createdAt'] != null && userData['createdAt'] is String) {
        userData['createdAt'] = FieldValue.serverTimestamp();
      }
      if (userData['lastSeenAt'] != null) {
        userData['lastSeenAt'] = FieldValue.serverTimestamp();
      }

      // Add device info if not present
      if (userData['device'] == null) {
        userData['device'] = {
          'platform': Platform.isAndroid ? 'android' : Platform.isIOS ? 'ios' : 'web',
          'osVersion': Platform.operatingSystemVersion,
        };
      }

      await _userDoc(uid).set(userData, SetOptions(merge: true));
      debugPrint('User upserted: $uid');
    } catch (e) {
      debugPrint('Error upserting user: $e');
      rethrow;
    }
  }

  /// Get user document
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _userDoc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromJson(doc.data()!);
    } catch (e) {
      debugPrint('Error getting user: $e');
      return null;
    }
  }

  /// Update last seen timestamp
  Future<void> updateLastSeen(String uid) async {
    try {
      await _userDoc(uid).update({
        'lastSeenAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating last seen: $e');
    }
  }
}

