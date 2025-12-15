import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/services/haptic_service.dart';
import 'core/services/sound_service.dart';
import 'core/services/settings_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/sync_manager.dart';
import 'core/services/sync_provider.dart';
import 'core/data/level_loader.dart';
import 'features/home/screens/home_screen.dart';
import 'features/auth/screens/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await FirebaseService.initialize();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    // Continue without Firebase (offline mode)
  }
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register Hive adapters
  // TODO: Register adapters when models are ready
  
  // Initialize SyncManager
  SyncManager? syncManager;
  if (FirebaseService.isInitialized || !kIsWeb) {
    try {
      syncManager = SyncManager();
      await syncManager!.initialize();
    } catch (e) {
      debugPrint('SyncManager initialization failed: $e');
    }
  }

  // Initialize settings
  await _initializeSettings();
  
  // Verify level packs (non-blocking)
  _verifyLevelPacks();
  
  runApp(
    ProviderScope(
      overrides: [
        if (syncManager != null)
          syncManagerProvider.overrideWithValue(syncManager),
      ],
      child: const SunMoonApp(),
    ),
  );
}

/// Verify level packs at startup (non-blocking)
Future<void> _verifyLevelPacks() async {
  try {
    final result = await LevelLoader.verifyLevelPacks();
    if (kDebugMode) {
      if (result.success) {
        debugPrint('[LEVELS] ✅ ${result.message}');
      } else {
        debugPrint('[LEVELS] ❌ ${result.message}');
      }
    }
  } catch (e) {
    debugPrint('[LEVELS] Verification error: $e');
    // Don't block app startup on verification failure
  }
}

Future<void> _initializeSettings() async {
  // Load settings and update services
  final hapticsEnabled = await SettingsService.getHapticsEnabled();
  final soundsEnabled = await SettingsService.getSoundsEnabled();
  
  HapticService.setEnabled(hapticsEnabled);
  SoundService.setEnabled(soundsEnabled);
}

class SunMoonApp extends StatelessWidget {
  const SunMoonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tango Logic – A Sun & Moon Puzzle',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}

