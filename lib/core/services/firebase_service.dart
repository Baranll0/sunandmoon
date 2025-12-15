import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Firebase initialization service
class FirebaseService {
  static bool _initialized = false;

  /// Initialize Firebase
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (kIsWeb) {
        // Manually initialize for Web using extracted config
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: 'AIzaSyCBYrIz1is39fOJTJpvRRgR46W2QRS607Q',
            appId: '1:867283777340:android:e3418584c49e87f40d5039', // Fallback to Android ID
            messagingSenderId: '867283777340',
            projectId: 'tango-logic',
            storageBucket: 'tango-logic.firebasestorage.app',
            authDomain: 'tango-logic.firebaseapp.com',
          ),
        );
      } else {
        // For mobile platforms, Firebase auto-loads from google-services.json
        await Firebase.initializeApp();
      }
      _initialized = true;
      debugPrint('Firebase initialized successfully');
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
      // Continue without Firebase (offline mode)
      debugPrint('Continuing in offline mode');
    }
  }

  static bool get isInitialized => _initialized;
}

