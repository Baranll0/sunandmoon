import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../domain/current_run_model.dart';

/// Repository for current run (save state)
class CurrentRunRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _debounceTimer;
  final Map<String, CurrentRunModel> _pendingSaves = {};

  /// Get current run document reference
  DocumentReference<Map<String, dynamic>> _currentRunDoc(String uid) {
    return _firestore.collection('users').doc(uid).collection('game').doc('currentRun');
  }

  /// Load current run from Firestore
  Future<CurrentRunModel?> loadCurrentRun(String uid) async {
    try {
      final doc = await _currentRunDoc(uid).get();
      if (!doc.exists) return null;
      return CurrentRunModel.fromJson(doc.data()!);
    } catch (e) {
      debugPrint('Error loading current run: $e');
      return null;
    }
  }

  /// Save current run (debounced)
  Future<void> saveCurrentRun(String uid, CurrentRunModel run) async {
    // Cancel existing timer
    _debounceTimer?.cancel();

    // Store pending save
    _pendingSaves[uid] = run;

    // Debounce: wait 2-3 seconds before saving
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      _flushPendingSave(uid);
    });
  }

  /// Flush pending save immediately (for background/pause)
  Future<void> flushSave(String uid) async {
    _debounceTimer?.cancel();
    await _flushPendingSave(uid);
  }

  /// Internal: flush pending save to Firestore
  Future<void> _flushPendingSave(String uid) async {
    final run = _pendingSaves.remove(uid);
    if (run == null) return;

    try {
      final runData = run.toJson();
      runData['updatedAt'] = FieldValue.serverTimestamp();
      runData['lastActionAt'] = FieldValue.serverTimestamp();

      await _currentRunDoc(uid).set(runData, SetOptions(merge: true));
      debugPrint('Current run saved: $uid');
    } catch (e) {
      debugPrint('Error saving current run: $e');
      // Re-add to pending if save failed
      _pendingSaves[uid] = run;
    }
  }

  /// Clear current run (when level completed or restarted)
  Future<void> clearCurrentRun(String uid) async {
    try {
      _debounceTimer?.cancel();
      _pendingSaves.remove(uid);
      await _currentRunDoc(uid).delete();
      debugPrint('Current run cleared: $uid');
    } catch (e) {
      debugPrint('Error clearing current run: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _debounceTimer?.cancel();
    _pendingSaves.clear();
  }
}

