import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_status.freezed.dart';
part 'game_status.g.dart';

/// Represents the current status of a game
@freezed
class GameStatus with _$GameStatus {
  const factory GameStatus({
    /// Whether the game is in progress
    @Default(true) bool isPlaying,
    
    /// Whether the game is paused
    @Default(false) bool isPaused,
    
    /// Whether the game is completed
    @Default(false) bool isCompleted,
    
    /// Whether auto-check is enabled (highlights errors)
    @Default(true) bool autoCheck,
    
    /// Whether pencil mode is active
    @Default(false) bool pencilMode,
    
    /// Current game mode
    @Default(GameMode.zen) GameMode mode,
    
    /// Elapsed time in seconds
    @Default(0) int elapsedSeconds,
    
    /// Number of moves made
    @Default(0) int moveCount,
    
    /// Number of hints used
    @Default(0) int hintsUsed,
    
    /// Number of mistakes made (invalid placements)
    @Default(0) int mistakeCount,
  }) = _GameStatus;

  factory GameStatus.fromJson(Map<String, dynamic> json) =>
      _$GameStatusFromJson(json);
}

/// Game modes
enum GameMode {
  zen,        // No timer, relaxed play
  speedRun,   // Timer-based, competitive
  daily,      // Daily challenge
}

extension GameModeExtension on GameMode {
  String get displayName {
    switch (this) {
      case GameMode.zen:
        return 'Zen Mode';
      case GameMode.speedRun:
        return 'Speed Run';
      case GameMode.daily:
        return 'Daily Challenge';
    }
  }
}

