import 'package:freezed_annotation/freezed_annotation.dart';
import 'puzzle_model.dart';
import 'game_status.dart';

part 'game_state.freezed.dart';
part 'game_state.g.dart';

/// Complete game state combining puzzle and status
@freezed
class GameState with _$GameState {
  const factory GameState({
    /// The current puzzle
    PuzzleModel? puzzle,
    
    /// The current game status
    @Default(const GameStatus()) GameStatus status,
    
    /// History for undo/redo (list of puzzle states)
    @Default([]) List<List<List<int>>> undoStack,
    
    /// Redo stack
    @Default([]) List<List<List<int>>> redoStack,
  }) = _GameState;

  factory GameState.fromJson(Map<String, dynamic> json) =>
      _$GameStateFromJson(json);
}

