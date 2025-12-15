import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../domain/game_progress_model.dart';
import '../domain/current_run_model.dart';

/// Remote state store for Firestore operations
class RemoteStateStore {
  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('[REMOTE] Firestore not available: $e');
      return null;
    }
  }

  /// Get progress document reference
  DocumentReference<Map<String, dynamic>>? _progressDoc(String uid) {
    final firestore = _firestore;
    if (firestore == null) return null;
    return firestore.collection('users').doc(uid).collection('state').doc('progress');
  }

  /// Get current run document reference
  DocumentReference<Map<String, dynamic>>? _currentRunDoc(String uid) {
    final firestore = _firestore;
    if (firestore == null) return null;
    return firestore.collection('users').doc(uid).collection('state').doc('currentRun');
  }

  /// Fetch progress from Firestore
  Future<GameProgressModel?> fetchProgress(String uid) async {
    try {
      final docRef = _progressDoc(uid);
      if (docRef == null) return null;
      final doc = await docRef.get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      return GameProgressModel.fromJson(data);
    } catch (e) {
      debugPrint('[REMOTE] Error fetching progress: $e');
      return null;
    }
  }

  /// Save progress to Firestore (merge) with retry
  Future<void> saveProgress(String uid, GameProgressModel progress) async {
    final docRef = _progressDoc(uid);
    if (docRef == null) {
      debugPrint('[REMOTE] Firestore not available, skipping save');
      return;
    }
    
    final data = progress.toJson();

    // CRITICAL FIX: Ensure 'stats' is a Map (nested object serialization issue)
    // Freezed/JsonSerializable might return the object instance if explicitToJson is not set
    if (data['stats'] is! Map) {
      data['stats'] = progress.stats.toJson();
    }

    // Keep localUpdatedAtMs from progress
    data['updatedAt'] = FieldValue.serverTimestamp();
    
    await _saveWithRetry(
      () => docRef.set(data, SetOptions(merge: true)),
      'Progress',
    );
    debugPrint('[REMOTE] Progress saved: $uid');
  }

  /// Fetch current run from Firestore
  Future<CurrentRunModel?> fetchCurrentRun(String uid) async {
    try {
      final docRef = _currentRunDoc(uid);
      if (docRef == null) return null;
      final doc = await docRef.get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      return CurrentRunModel.fromJson(data);
    } catch (e) {
      debugPrint('[REMOTE] Error fetching current run: $e');
      return null;
    }
  }

  /// Save current run to Firestore (merge) with retry
  Future<void> saveCurrentRun(String uid, CurrentRunModel run) async {
    final docRef = _currentRunDoc(uid);
    if (docRef == null) {
      debugPrint('[REMOTE] Firestore not available, skipping save');
      return;
    }
    
    final data = run.toJson();
    // Keep localUpdatedAtMs and deviceId from run
    data['updatedAt'] = FieldValue.serverTimestamp();
    data['lastActionAt'] = FieldValue.serverTimestamp();
    
    await _saveWithRetry(
      () => docRef.set(data, SetOptions(merge: true)),
      'CurrentRun',
    );
    debugPrint('[REMOTE] Current run saved: $uid');
  }

  /// Clear current run from Firestore with retry
  Future<void> clearCurrentRun(String uid) async {
    final docRef = _currentRunDoc(uid);
    if (docRef == null) {
      debugPrint('[REMOTE] Firestore not available, skipping delete');
      return;
    }
    
    await _saveWithRetry(
      () => docRef.delete(),
      'ClearCurrentRun',
    );
    debugPrint('[SYNC] remote delete currentRun: $uid');
  }

  /// Save with retry and backoff (for network errors)
  Future<void> _saveWithRetry(
    Future<void> Function() operation,
    String operationName,
  ) async {
    final delays = [300, 800, 1500]; // milliseconds
    Exception? lastError;

    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        await operation();
        return; // Success
      } on FirebaseException catch (e) {
        lastError = e;
        // Only retry on network/unavailable errors
        if (e.code == 'unavailable' || 
            e.code == 'deadline-exceeded' ||
            e.code == 'internal' ||
            e.message?.contains('network') == true) {
          if (attempt < delays.length - 1) {
            debugPrint('[REMOTE] $operationName failed (attempt ${attempt + 1}/3), retrying in ${delays[attempt]}ms: ${e.code}');
            await Future.delayed(Duration(milliseconds: delays[attempt]));
            continue;
          }
        }
        // Non-retryable error or last attempt
        debugPrint('[REMOTE] $operationName failed (non-retryable or max attempts): ${e.code}');
        rethrow;
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        if (attempt < delays.length - 1) {
          debugPrint('[REMOTE] $operationName failed (attempt ${attempt + 1}/3), retrying in ${delays[attempt]}ms: $e');
          await Future.delayed(Duration(milliseconds: delays[attempt]));
          continue;
        }
        debugPrint('[REMOTE] $operationName failed (max attempts): $e');
        rethrow;
      }
    }

    if (lastError != null) {
      throw lastError;
    }
  }

  /// Compute hash for diff checking
  String _computeHash(Map<String, dynamic> data) {
    // Remove timestamps for comparison
    final cleanData = Map<String, dynamic>.from(data);
    cleanData.remove('updatedAt');
    cleanData.remove('lastActionAt');
    final jsonString = jsonEncode(cleanData);
    return jsonString.hashCode.toString();
  }

  /// Check if progress has changed (for skip-on-no-change)
  bool hasProgressChanged(String uid, GameProgressModel progress) {
    // This will be called from SyncManager with last hash
    final data = progress.toJson();
    final currentHash = _computeHash(data);
    // Hash comparison will be done in SyncManager
    return true; // Always return true, hash check in SyncManager
  }

  /// Get settings document reference
  DocumentReference<Map<String, dynamic>>? _settingsDoc(String uid) {
    final firestore = _firestore;
    if (firestore == null) return null;
    return firestore.collection('users').doc(uid).collection('game').doc('settings');
  }

  /// Fetch settings from Firestore
  Future<Map<String, dynamic>?> fetchSettings(String uid) async {
    try {
      final docRef = _settingsDoc(uid);
      if (docRef == null) return null;
      final doc = await docRef.get();
      if (!doc.exists) return null;

      return doc.data();
    } catch (e) {
      debugPrint('[REMOTE] Error fetching settings: $e');
      return null;
    }
  }

  /// Save settings to Firestore (merge) with retry
  Future<void> saveSettings(String uid, Map<String, dynamic> settings) async {
    final docRef = _settingsDoc(uid);
    if (docRef == null) {
      debugPrint('[REMOTE] Firestore not available, skipping save');
      return;
    }
    
    final data = Map<String, dynamic>.from(settings);
    data['updatedAt'] = FieldValue.serverTimestamp();
    
    await _saveWithRetry(
      () => docRef.set(data, SetOptions(merge: true)),
      'Settings',
    );
    debugPrint('[REMOTE] Settings saved: $uid');
  }

  /// Check if current run has changed
  bool hasCurrentRunChanged(String uid, CurrentRunModel run) {
    final data = run.toJson();
    final currentHash = _computeHash(data);
    return true; // Always return true, hash check in SyncManager
  }
}

