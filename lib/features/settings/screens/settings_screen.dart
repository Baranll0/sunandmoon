import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/localization/locale_provider.dart';

/// Settings Screen
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _hapticsEnabled = true;
  bool _soundsEnabled = true;
  bool _autoCheckEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hapticsEnabled = prefs.getBool('haptics_enabled') ?? true;
      _soundsEnabled = prefs.getBool('sounds_enabled') ?? true;
      _autoCheckEnabled = prefs.getBool('auto_check_enabled') ?? true;
      _isLoading = false;
    });

    // Update services
    HapticService.setEnabled(_hapticsEnabled);
    SoundService.setEnabled(_soundsEnabled);
  }

  Future<void> _setHapticsEnabled(bool value) async {
    setState(() {
      _hapticsEnabled = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('haptics_enabled', value);
    HapticService.setEnabled(value);
    
    // Test haptic if enabling
    if (value) {
      HapticService.lightImpact();
    }
  }

  Future<void> _setSoundsEnabled(bool value) async {
    setState(() {
      _soundsEnabled = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sounds_enabled', value);
    SoundService.setEnabled(value);
    
    // Test sound if enabling
    if (value) {
      SoundService.playTap();
    }
  }

  Future<void> _setAutoCheckEnabled(bool value) async {
    setState(() {
      _autoCheckEnabled = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_check_enabled', value);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final strings = ref.watch(appStringsProvider);
    final currentLocale = ref.watch(localeNotifierProvider);
    final localeNotifier = ref.read(localeNotifierProvider.notifier);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      appBar: AppBar(
        title: Text(strings.settings),
        backgroundColor: AppTheme.backgroundCream,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Language Setting
          Card(
            child: ListTile(
              leading: Icon(Icons.language, color: AppTheme.sunOrange),
              title: Text(strings.language),
              subtitle: Text(currentLocale == 'en' ? strings.english : strings.turkish),
              trailing: DropdownButton<String>(
                value: currentLocale,
                items: [
                  DropdownMenuItem(
                    value: 'en',
                    child: Text(strings.english),
                  ),
                  DropdownMenuItem(
                    value: 'tr',
                    child: Text(strings.turkish),
                  ),
                ],
                onChanged: (String? newLocale) {
                  if (newLocale != null) {
                    localeNotifier.setLocale(newLocale);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Haptics Setting
          _SettingTile(
            title: strings.hapticFeedback,
            subtitle: strings.hapticFeedbackSubtitle,
            icon: Icons.vibration,
            value: _hapticsEnabled,
            onChanged: _setHapticsEnabled,
          ),
          const SizedBox(height: 8),
          // Sounds Setting (Mute/Unmute)
          _SettingTile(
            title: strings.soundEffects,
            subtitle: _soundsEnabled ? strings.soundEffectsEnabled : strings.soundEffectsDisabled,
            icon: _soundsEnabled ? Icons.volume_up : Icons.volume_off,
            value: _soundsEnabled,
            onChanged: _setSoundsEnabled,
          ),
          const SizedBox(height: 8),
          // Auto-Check Setting
          _SettingTile(
            title: strings.autoCheck,
            subtitle: strings.autoCheckSubtitle,
            icon: Icons.check_circle_outline,
            value: _autoCheckEnabled,
            onChanged: _setAutoCheckEnabled,
          ),
          const SizedBox(height: 24),
          // About Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.about,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.appName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${strings.version} 1.0.0',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.inkLight,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.appDescription,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Setting tile widget
class _SettingTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        secondary: Icon(icon, color: AppTheme.sunOrange),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
