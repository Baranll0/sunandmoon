import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing game sounds
/// 
/// Audio files in assets/audio/ directory:
/// - mouseclick1.ogg (for cell taps)
/// - mouserelease1.ogg (for invalid moves)
/// - rollover6.ogg (for puzzle completion)
/// - switch1.ogg (for undo/redo actions)
/// - rollover1.ogg (for hint usage)
class SoundService {
  static bool _enabled = true;
  static final AudioPlayer _player = AudioPlayer();
  static final Map<String, AudioPlayer> _players = {}; // Separate players for web

  /// Enable or disable sound effects
  static void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// Check if sounds are enabled
  static bool get isEnabled => _enabled;

  /// Play a sound effect
  /// 
  /// [assetPath] should be relative to assets/audio/ directory
  /// Example: 'mouseclick1.ogg' will load from assets/audio/mouseclick1.ogg
  static Future<void> playSound(String assetPath, {double volume = 0.5}) async {
    if (!_enabled) return;
    
    // Also check settings service for sound enabled state
    try {
      final settingsService = await SharedPreferences.getInstance();
      final soundsEnabled = settingsService.getBool('sounds_enabled') ?? true;
      if (!soundsEnabled) return;
    } catch (e) {
      // If settings can't be loaded, continue with current _enabled state
    }

    try {
      final source = AssetSource('audio/$assetPath');
      
      if (kIsWeb) {
        // For web, use a separate player for each sound to avoid conflicts
        if (!_players.containsKey(assetPath)) {
          _players[assetPath] = AudioPlayer();
        }
        final player = _players[assetPath]!;
        await player.setVolume(volume);
        await player.play(source, volume: volume);
      } else {
        // For mobile/desktop, use the shared player
        await _player.stop();
        await _player.setVolume(volume);
        await _player.play(source, volume: volume);
      }
    } catch (e) {
      // Silently fail if sound file doesn't exist
      // This allows the app to work without audio files during development
      if (kDebugMode) {
        debugPrint('SoundService: Could not play $assetPath - $e');
      }
    }
  }

  /// Play tap sound (for normal cell tap)
  /// Uses: mouseclick1.ogg
  /// Volume: 1.0 (Make it audible)
  static Future<void> playTap() async {
    await playSound('mouseclick1.ogg', volume: 1.0);
  }

  /// Play error sound (for invalid moves)
  /// Uses: mouserelease1.ogg
  static Future<void> playError() async {
    await playSound('mouserelease1.ogg', volume: 0.5);
  }

  /// Play win sound (for puzzle completion)
  /// Uses: win.mp3
  /// CRITICAL: Stop playback after 4 seconds
  static Future<void> playWin() async {
    if (!_enabled) return;
    
    try {
      final settingsService = await SharedPreferences.getInstance();
      final soundsEnabled = settingsService.getBool('sounds_enabled') ?? true;
      if (!soundsEnabled) return;
    } catch (e) {
      // Continue if settings can't be loaded
    }

    try {
      final source = AssetSource('audio/win.mp3');
      AudioPlayer? player;
      
      if (kIsWeb) {
        if (!_players.containsKey('win.mp3')) {
          _players['win.mp3'] = AudioPlayer();
        }
        player = _players['win.mp3']!;
      } else {
        player = _player;
      }
      
      await player.setVolume(0.6);
      await player.play(source, volume: 0.6);
      
      // CRITICAL: Stop after 4 seconds
      Future.delayed(const Duration(milliseconds: 4000), () async {
        try {
          await player?.stop();
        } catch (e) {
          // Ignore errors when stopping
        }
      });
    } catch (e) {
      // Fallback to rollover6.ogg if win.mp3 not available
      await playSound('rollover6.ogg', volume: 0.6);
      // Also stop fallback after 4s
      Future.delayed(const Duration(milliseconds: 4000), () async {
        try {
          if (kIsWeb && _players.containsKey('rollover6.ogg')) {
            await _players['rollover6.ogg']!.stop();
          } else {
            await _player.stop();
          }
        } catch (e) {
          // Ignore
        }
      });
    }
  }

  /// Play undo sound (for undo/redo actions)
  /// Uses: switch1.ogg
  static Future<void> playUndo() async {
    await playSound('switch1.ogg', volume: 0.3);
  }

  /// Play hint sound (for hint usage)
  /// Uses: rollover1.ogg
  static Future<void> playHint() async {
    await playSound('rollover1.ogg', volume: 0.3);
  }

  /// Dispose the audio players
  static Future<void> dispose() async {
    await _player.dispose();
    for (final player in _players.values) {
      await player.dispose();
    }
    _players.clear();
  }
}

