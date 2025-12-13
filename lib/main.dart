import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/services/haptic_service.dart';
import 'core/services/sound_service.dart';
import 'core/services/settings_service.dart';
import 'features/home/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register Hive adapters
  // TODO: Register adapters when models are ready
  
  // Initialize settings
  await _initializeSettings();
  
  runApp(
    const ProviderScope(
      child: SunMoonApp(),
    ),
  );
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
      home: const HomeScreen(),
    );
  }
}

