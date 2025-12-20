import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/puzzle_model.dart';
import '../../domain/models/game_status.dart';
import '../../domain/models/level_model.dart';
import '../../../../core/constants/game_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/services/hint_service.dart';
import '../../../../core/services/progress_service.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/domain/hint_result.dart';
import '../../../../core/domain/mechanic_flag.dart';
import '../../../../core/repositories/game_state_repository.dart';
import '../../../../core/providers/sync_providers.dart';
import '../../../../core/services/sync_manager.dart';
import '../../../../core/services/ad_service.dart';
import '../../data/repositories/game_repository.dart';
import '../utils/game_utils.dart';

part 'game_controller.g.dart';

/// Repository provider
@riverpod
GameRepository gameRepository(GameRepositoryRef ref) {
  return GameRepository();
}

/// Game state provider - manages the complete game state
/// keepAlive: true ensures the provider persists across navigation
@Riverpod(keepAlive: true)
class GameStateNotifier extends _$GameStateNotifier {
  Timer? _timer;
  bool _timerActive = false;
  GameStateRepository? _gameStateRepo;

  @override
  GameState build() {
    // Get game state repository (async, will be set when ready)
    ref.read(gameStateRepositoryProvider.future).then((repo) {
      _gameStateRepo = repo;
    });
    
    // Cleanup timer when provider is disposed
    ref.onDispose(() {
      _timer?.cancel();
      _timerActive = false;
    });

    return const GameState();
  }

  /// Starts a new game for a specific level
  Future<void> startLevel(LevelModel level) async {
    final repository = ref.read(gameRepositoryProvider);
    
    // Cancel existing timer
    _timer?.cancel();
    
    try {
      // Save current progress and update max unlocked
      await ProgressService.saveProgress(level);
      await ProgressService.saveMaxUnlockedLevel(level);
      
      // Generate new puzzle for level (now async, loads from LevelLoader)
      final puzzle = await repository.generatePuzzleForLevel(level);
      
      // Load auto-check setting from preferences
      final autoCheckEnabled = await SettingsService.getAutoCheckEnabled();
      
      // Initialize game state
      state = GameState(
        puzzle: puzzle,
        status: GameStatus(
          isPlaying: true,
          isPaused: false,
          isCompleted: false,
          mode: GameMode.zen,
          elapsedSeconds: 0,
          moveCount: 0,
          hintsUsed: 0,
          mistakeCount: 0,
          autoCheck: autoCheckEnabled, // Load from settings
        ),
        undoStack: [],
        redoStack: [],
      );

      // Save initial state to undo stack
      _saveToUndoStack();

      // CRITICAL FIX: Start timer for all game modes (not just speedRun)
      _startTimer();
    } catch (e) {
      // Reset state on error
      state = const GameState();
      rethrow; // Re-throw to let caller handle it
    }
  }

  /// Starts a new game with the specified difficulty (backward compatibility)
  Future<void> startNewGame(PuzzleDifficulty difficulty) async {
    final repository = ref.read(gameRepositoryProvider);
    
    // Cancel existing timer
    _timer?.cancel();
    
    try {
      // Generate new puzzle
      final puzzle = repository.generatePuzzle(difficulty);
      
      // Load auto-check setting from preferences
      final autoCheckEnabled = await SettingsService.getAutoCheckEnabled();
      
      // Initialize game state
      state = GameState(
        puzzle: puzzle,
        status: GameStatus(
          isPlaying: true,
          isPaused: false,
          isCompleted: false,
          mode: GameMode.zen,
          elapsedSeconds: 0,
          moveCount: 0,
          hintsUsed: 0,
          autoCheck: autoCheckEnabled, // Load from settings
        ),
        undoStack: [],
        redoStack: [],
      );

      // Save initial state to undo stack
      _saveToUndoStack();

      // CRITICAL FIX: Start timer for all game modes (not just speedRun)
      _startTimer();
    } catch (e) {
      // Reset state on error
      state = const GameState();
      rethrow; // Re-throw to let caller handle it
    }
  }

  /// Starts a daily challenge
  Future<void> startDailyChallenge(PuzzleDifficulty difficulty) async {
    final repository = ref.read(gameRepositoryProvider);
    
    // Cancel existing timer
    _timer?.cancel();
    
    try {
      // Generate daily challenge
      final puzzle = repository.generateDailyChallenge(difficulty);
      
      // Initialize game state
      state = GameState(
        puzzle: puzzle,
        status: const GameStatus(
          isPlaying: true,
          isPaused: false,
          isCompleted: false,
          mode: GameMode.daily,
          elapsedSeconds: 0,
          moveCount: 0,
          hintsUsed: 0,
        ),
        undoStack: [],
        redoStack: [],
      );

      // Save initial state to undo stack
      _saveToUndoStack();

      // Start timer for daily challenge
      _startTimer();
    } catch (e) {
      // Reset state on error
      state = const GameState();
      rethrow; // Re-throw to let caller handle it
    }
  }

  /// Handles cell tap
  void onCellTap(int row, int col, {int? value, BuildContext? context}) {
    if (state.puzzle == null) return;
    if (state.status.isCompleted || state.status.isPaused) return;

    final puzzle = state.puzzle!;
    
    // Don't allow editing given cells or locked cells
    final cell = puzzle.currentState[row][col];
    if (cell.isGiven) {
      HapticService.heavyImpact();
      SoundService.playError();
      return;
    }

    // MECHANICS ENFORCEMENT: Check moveLimit
    if (puzzle.mechanics.contains(MechanicFlag.moveLimit)) {
      final maxMoves = puzzle.params['maxMoves'] as int? ?? 50;
      if (state.status.moveCount >= maxMoves) {
        // Out of moves - show dialog
        _showOutOfMovesDialog(context);
        return;
      }
    }

    // Get the value to place from the selected tool
    final toolValue = state.status.selectedTool;
    final currentValue = puzzle.currentState[row][col].value;
    
    int finalValue;
    if (toolValue == GameConstants.cellEmpty) {
      // Eraser always erases
      finalValue = GameConstants.cellEmpty;
    } else {
      // If tapping with same tool on same value -> Toggle off (Clear)
      if (currentValue == toolValue) {
        finalValue = GameConstants.cellEmpty;
      } else {
        // Else paint the tool value
        finalValue = toolValue;
      }
    }
    
    // If value didn't change, do nothing
    if (currentValue == finalValue) return;

    // If pencil mode is active, handle pencil marks
    if (state.status.pencilMode) {
      // For pencil mode, we toggle the specific mark corresponding to the tool
      // Eraser clears all marks? Or specific?
      // Let's say Eraser (0) clears all marks.
      // Sun/Moon toggles that specific mark.
      if (toolValue == GameConstants.cellEmpty) {
         _handlePencilMark(row, col, 0); // Special case for clear all?
      } else {
         _handlePencilMark(row, col, toolValue);
      }
      return;
    }
    
    // The rest of the logic uses finalValue
    final cellValue = finalValue; // Re-assign for compatibility with existing code below

    // If pencil mode is active, handle pencil marks
    if (state.status.pencilMode) {
      _handlePencilMark(row, col, cellValue);
      return;
    }

    // Update the cell
    final newState = GameUtils.copyCellGrid(puzzle.currentState);
    newState[row][col] = newState[row][col].copyWith(
      value: cellValue,
      pencilMarks: [], // Clear pencil marks when placing a value
    );

    // CRITICAL: Always validate to check for errors and completion
    // IMPORTANT: Replace entire state, not just one cell, so row/column errors are shown
    bool hasError = false;
    final validatedState = GameUtils.validateAndMarkErrors(newState);
    
    // ALWAYS show errors - auto-check just controls when to validate
    // But we always validate and show errors for user feedback
    for (int r = 0; r < validatedState.length; r++) {
      for (int c = 0; c < validatedState[r].length; c++) {
        newState[r][c] = validatedState[r][c];
      }
    }
    hasError = validatedState[row][col].hasError;

    // Haptic and sound feedback - ALWAYS provide feedback
    if (hasError) {
      HapticService.heavyImpact();
      SoundService.playError();
      
      // MECHANICS ENFORCEMENT: Increment mistake count
      final newMistakeCount = state.status.mistakeCount + 1;
      
      // Check mistakeLimit
      if (puzzle.mechanics.contains(MechanicFlag.mistakeLimit)) {
        final maxMistakes = puzzle.params['maxMistakes'] as int? ?? 5;
        if (newMistakeCount >= maxMistakes) {
          // Out of mistakes - fail level
          _failLevel(context, reason: 'mistakeLimit');
          return;
        }
      }
      
      // Update mistake count
      state = state.copyWith(
        status: state.status.copyWith(mistakeCount: newMistakeCount),
      );
    } else {
      HapticService.lightImpact();
      SoundService.playTap();
    }

    // Update puzzle
    final updatedPuzzle = puzzle.copyWith(currentState: newState);

    // Save to undo stack
    _saveToUndoStack();

    // Update state
    state = state.copyWith(
      puzzle: updatedPuzzle,
      status: state.status.copyWith(
        moveCount: state.status.moveCount + 1,
      ),
      redoStack: [], // Clear redo stack on new move
    );

    // MECHANICS ENFORCEMENT: Check moveLimit after incrementing
    if (updatedPuzzle.mechanics.contains(MechanicFlag.moveLimit)) {
      final maxMoves = updatedPuzzle.params['maxMoves'] as int? ?? 50;
      if (state.status.moveCount >= maxMoves) {
        // Out of moves - show dialog
        _showOutOfMovesDialog(context);
        // Don't allow further moves
        state = state.copyWith(
          status: state.status.copyWith(isPaused: true),
        );
        return;
      }
    }

    // CRITICAL: Always check if puzzle is completed (regardless of auto-check)
    _checkCompletion(); // Fire and forget - async operation
  }

  /// Handles pencil mark placement
  void _handlePencilMark(int row, int col, int value) {
    if (state.puzzle == null) return;

    final puzzle = state.puzzle!;
    final cell = puzzle.currentState[row][col];
    
    // Don't allow pencil marks on given cells or filled cells
    if (cell.isGiven || cell.value != GameConstants.cellEmpty) return;

    final newState = GameUtils.copyCellGrid(puzzle.currentState);
    final currentMarks = List<int>.from(cell.pencilMarks);

    // Toggle pencil mark
    final bool isRemoving = currentMarks.contains(value);
    if (isRemoving) {
      currentMarks.remove(value);
      HapticService.heavyImpact(); // Heavy for removal
    } else {
      currentMarks.add(value);
      currentMarks.sort();
      HapticService.lightImpact();
    }
    SoundService.playTap();

    newState[row][col] = cell.copyWith(pencilMarks: currentMarks);

    final updatedPuzzle = puzzle.copyWith(currentState: newState);

    state = state.copyWith(puzzle: updatedPuzzle);
  }

  /// Undo last move
  void undo() {
    if (state.undoStack.isEmpty || state.puzzle == null) return;
    
    HapticService.mediumImpact();
    SoundService.playUndo();

    // Save current state to redo stack
    final currentGrid = GameUtils.cellGridToIntGrid(state.puzzle!.currentState);
    final newRedoStack = [currentGrid, ...state.redoStack];

    // Restore from undo stack
    final previousGrid = state.undoStack.last;
    final newUndoStack = state.undoStack.sublist(0, state.undoStack.length - 1);

    final newState = GameUtils.intGridToCellGrid(
      previousGrid,
      state.puzzle!.currentState,
    );

    final updatedPuzzle = state.puzzle!.copyWith(currentState: newState);

    state = state.copyWith(
      puzzle: updatedPuzzle,
      undoStack: newUndoStack,
      redoStack: newRedoStack,
      status: state.status.copyWith(
        moveCount: state.status.moveCount > 0 ? state.status.moveCount - 1 : 0,
      ),
    );

    // Re-validate if auto-check is enabled
    if (state.status.autoCheck) {
      final validatedState = GameUtils.validateAndMarkErrors(newState);
      final validatedPuzzle = updatedPuzzle.copyWith(currentState: validatedState);
      state = state.copyWith(puzzle: validatedPuzzle);
    }
  }

  /// Redo last undone move
  void redo() {
    if (state.redoStack.isEmpty || state.puzzle == null) return;
    
    HapticService.mediumImpact();
    SoundService.playUndo();

    // Save current state to undo stack
    final currentGrid = GameUtils.cellGridToIntGrid(state.puzzle!.currentState);
    final newUndoStack = [...state.undoStack, currentGrid];

    // Restore from redo stack
    final nextGrid = state.redoStack.first;
    final newRedoStack = state.redoStack.sublist(1);

    final newState = GameUtils.intGridToCellGrid(
      nextGrid,
      state.puzzle!.currentState,
    );

    final updatedPuzzle = state.puzzle!.copyWith(currentState: newState);

    state = state.copyWith(
      puzzle: updatedPuzzle,
      undoStack: newUndoStack,
      redoStack: newRedoStack,
      status: state.status.copyWith(
        moveCount: state.status.moveCount + 1,
      ),
    );

    // Re-validate if auto-check is enabled
    if (state.status.autoCheck) {
      final validatedState = GameUtils.validateAndMarkErrors(newState);
      final validatedPuzzle = updatedPuzzle.copyWith(currentState: validatedState);
      state = state.copyWith(puzzle: validatedPuzzle);
    }

    // Check if puzzle is completed
    _checkCompletion(); // Fire and forget - async operation
  }

  /// Shows a hint - ACTUALLY SOLVES one cell based on the Solution Grid
  /// CRITICAL: Hint must fill/correct a specific cell from the solution
  Future<void> showHint(BuildContext? context) async {
    if (state.puzzle == null) return;

    // Check if user can use a hint
    final canUse = await HintService.canUseHint();
    if (!canUse) {
      // Show dialog: "Come back tomorrow!"
      if (context != null && context.mounted) {
        final strings = ref.read(appStringsProvider);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(strings.hintsWillRefresh),
            content: Text(
              '${strings.hintsWillRefresh}\n\n${strings.hintExplanation}',
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(strings.cancel),
              ),
            ],
          ),
        );
      }
      return;
    }

    // Use a hint
    final hintUsed = await HintService.useHint();
    if (!hintUsed) {
      return;
    }

    // Use new structured Hint API
    final puzzle = state.puzzle!;
    final newState = GameUtils.copyCellGrid(puzzle.currentState);
    
    // Convert to int grid for hint API
    final List<List<int>> intGrid = GameUtils.cellGridToIntGrid(newState);
    
    // Build given locks matrix
    final List<List<bool>> givenLocks = newState.map((row) {
      return row.map((cell) => cell.isGiven).toList();
    }).toList();
    
    // Get hint using new API
    final hintResult = HintAPI.getHint(intGrid, givenLocks: givenLocks);
    
    if (hintResult.hasHint && hintResult.move != null) {
      final move = hintResult.move!;
      
      // Fill the cell with the hint value
      newState[move.row][move.col] = newState[move.row][move.col].copyWith(
        value: move.value,
        isHighlighted: true, // Highlight to show it was a hint
      );

      // Show hint explanation
      if (context != null && context.mounted) {
        final strings = ref.read(appStringsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${strings.hintExplanation} ${hintResult.explanation}',
              style: const TextStyle(fontSize: 13),
            ),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.inkDark.withOpacity(0.9),
          ),
        );
      }

      // Clear highlight after 4 seconds
      Future.delayed(const Duration(seconds: 4), () {
        if (state.puzzle != null) {
          final clearedState = newState.map((row) {
            return row.map((cell) => cell.copyWith(isHighlighted: false)).toList();
          }).toList();

          final updatedPuzzle = state.puzzle!.copyWith(currentState: clearedState);
          state = state.copyWith(puzzle: updatedPuzzle);
        }
      });

      // Save to undo stack
      _saveToUndoStack();

      final updatedPuzzle = puzzle.copyWith(currentState: newState);

      state = state.copyWith(
        puzzle: updatedPuzzle,
        status: state.status.copyWith(
          hintsUsed: state.status.hintsUsed + 1,
          moveCount: state.status.moveCount + 1,
        ),
        redoStack: [], // Clear redo stack
      );

      HapticService.lightImpact();
      SoundService.playHint();

      // Re-validate if auto-check is enabled
      if (state.status.autoCheck) {
        final validatedState = GameUtils.validateAndMarkErrors(newState);
        final validatedPuzzle = updatedPuzzle.copyWith(currentState: validatedState);
        state = state.copyWith(puzzle: validatedPuzzle);
      }

      // Check if puzzle is completed
      _checkCompletion();
    } else {
      // No forced moves found - show suggestion
      if (context != null && context.mounted) {
        final strings = ref.read(appStringsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              hintResult.suggestion ?? hintResult.explanation,
              style: const TextStyle(fontSize: 13),
            ),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.inkDark.withOpacity(0.9),
          ),
        );
      }
    }
  }

  /// Toggles pencil mode
  void togglePencilMode() {
    state = state.copyWith(
      status: state.status.copyWith(
        pencilMode: !state.status.pencilMode,
      ),
    );
  }

  /// Toggles auto-check
  void toggleAutoCheck() {
    final newAutoCheck = !state.status.autoCheck;
    state = state.copyWith(
      status: state.status.copyWith(autoCheck: newAutoCheck),
    );

    // Re-validate if enabling auto-check
    if (newAutoCheck && state.puzzle != null) {
      final validatedState = GameUtils.validateAndMarkErrors(state.puzzle!.currentState);
      final updatedPuzzle = state.puzzle!.copyWith(currentState: validatedState);
      state = state.copyWith(puzzle: updatedPuzzle);
    } else if (!newAutoCheck && state.puzzle != null) {
      // Clear error flags if disabling auto-check
      final clearedState = state.puzzle!.currentState.map((row) {
        return row.map((cell) => cell.copyWith(hasError: false)).toList();
      }).toList();
      final updatedPuzzle = state.puzzle!.copyWith(currentState: clearedState);
      state = state.copyWith(puzzle: updatedPuzzle);
    }
  }

  /// Pauses/resumes the game
  void togglePause() {
    final isPaused = !state.status.isPaused;
    
    if (isPaused) {
      _timer?.cancel();
      _timerActive = false;
    } else if (state.status.mode == GameMode.speedRun || state.status.mode == GameMode.daily) {
      _startTimer();
    }

    state = state.copyWith(
      status: state.status.copyWith(isPaused: isPaused),
    );
  }

  /// Changes game mode
  void setGameMode(GameMode mode) {
    final wasTimerRunning = _timerActive;
    
    _timer?.cancel();
    _timerActive = false;

    if (mode == GameMode.speedRun || mode == GameMode.daily) {
      if (!state.status.isPaused && wasTimerRunning) {
        _startTimer();
      }
    }

    state = state.copyWith(
      status: state.status.copyWith(mode: mode),
    );
  }

  /// Selects a tool (Sun, Moon, Erase)
  void selectTool(int toolId) {
    if (state.status.selectedTool == toolId) return;
    
    state = state.copyWith(
      status: state.status.copyWith(selectedTool: toolId),
    );
    HapticService.lightImpact();
  }

  /// Saves current state to undo stack
  void _saveToUndoStack() {
    if (state.puzzle == null) return;

    final currentGrid = GameUtils.cellGridToIntGrid(state.puzzle!.currentState);
    final newUndoStack = [...state.undoStack, currentGrid];

    // Limit undo stack size to prevent memory issues (keep last 100 moves)
    final limitedStack = newUndoStack.length > 100
        ? newUndoStack.sublist(newUndoStack.length - 100)
        : newUndoStack;

    state = state.copyWith(undoStack: limitedStack);
  }

  /// Checks if puzzle is completed
  Future<void> _checkCompletion() async {
    if (state.puzzle == null) return;
    if (state.status.isCompleted) return; // Already completed

    // CRITICAL: Check if puzzle is completed
    final isCompleted = GameUtils.isPuzzleCompleted(state.puzzle!);
    
    if (isCompleted) {
      _timer?.cancel();
      _timerActive = false;
      
      // Celebration feedback
      HapticService.successVibration();
      SoundService.playWin();
      
      // If this is a level-based puzzle, mark it as completed and advance
      if (state.puzzle!.level != null) {
        final level = state.puzzle!.level!;
        
        // Update progress via repository
        if (_gameStateRepo != null) {
          // Get existing progress to calculate totalSolved correctly
          final existingProgress = _gameStateRepo!.getCurrentProgress();
          final currentTotalSolved = existingProgress?.stats.totalSolved ?? 0;
          
          await _gameStateRepo!.updateProgress(
            level: level,
            totalSolved: 1, // Pass 1 to increment the count
            totalHintsUsed: state.status.hintsUsed,
            totalPlaySeconds: state.status.elapsedSeconds,
            totalMoves: state.status.moveCount,
          );
          
          // Clear current run
          final syncManager = await ref.read(syncManagerProvider.future);
          final uid = syncManager.authService.currentUserId;
          if (uid != null) {
            await _gameStateRepo!.clearCurrentRun(uid);
          }
        }
        
        // Legacy progress service (keep for backward compatibility)
        final nextLevel = await ProgressService.completeLevel(level);
        if (nextLevel != null) {
          await ProgressService.saveMaxUnlockedLevel(nextLevel);
        }
        
        // Trigger Ad Logic (Every 3 levels)
        AdService.instance.onLevelComplete();
      }
      
      // CRITICAL: Update state to mark as completed
      // This will trigger the victory dialog in GameScreen
      state = state.copyWith(
        status: state.status.copyWith(
          isCompleted: true,
          isPlaying: false,
        ),
      );
    }
  }

  /// Clears all user moves, keeping only pre-filled cells
  void clearBoard() {
    if (state.puzzle == null) return;

    final puzzle = state.puzzle!;
    final newState = GameUtils.copyCellGrid(puzzle.currentState);

    // Clear all non-given cells
    for (int row = 0; row < newState.length; row++) {
      for (int col = 0; col < newState[row].length; col++) {
        final cell = newState[row][col];
        if (!cell.isGiven) {
          newState[row][col] = cell.copyWith(
            value: GameConstants.cellEmpty,
            hasError: false,
            isHighlighted: false,
            pencilMarks: [],
          );
        }
      }
    }

    final updatedPuzzle = puzzle.copyWith(currentState: newState);

    // Save to undo stack
    _saveToUndoStack();

    state = state.copyWith(
      puzzle: updatedPuzzle,
      status: state.status.copyWith(
        moveCount: 0,
      ),
      redoStack: [], // Clear redo stack
    );

    HapticService.mediumImpact();
    SoundService.playUndo();
  }

  /// Starts the game timer
  void _startTimer() {
    _timer?.cancel();
    _timerActive = false;
    
    if (kIsWeb) {
      // Web platform: Use recursive Future.delayed instead of Timer.periodic
      _timerActive = true;
      _timerWeb();
    } else {
      // Mobile/Desktop: Use Timer.periodic
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!state.status.isPaused && !state.status.isCompleted && _timerActive) {
          state = state.copyWith(
            status: state.status.copyWith(
              elapsedSeconds: state.status.elapsedSeconds + 1,
            ),
          );
        }
      });
      _timerActive = true;
    }
  }
  
  /// Web-compatible timer using Future.delayed
  Future<void> _timerWeb() async {
    while (_timerActive && !state.status.isPaused && !state.status.isCompleted) {
      await Future.delayed(const Duration(seconds: 1));
      if (_timerActive && !state.status.isPaused && !state.status.isCompleted) {
        state = state.copyWith(
          status: state.status.copyWith(
            elapsedSeconds: state.status.elapsedSeconds + 1,
          ),
        );
      }
    }
  }

  /// Clears the current game
  void clearGame() {
    _timer?.cancel();
    _timerActive = false;
    
    // Flush current run before clearing
    _gameStateRepo?.flushNow();
    
    state = const GameState();
  }

  /// Shows "Out of Moves" dialog when moveLimit is reached
  Future<void> _showOutOfMovesDialog(BuildContext? context) async {
    if (context == null || !context.mounted) return;
    
    final strings = ref.read(appStringsProvider);
    final puzzle = state.puzzle!;
    final maxMoves = puzzle.params['maxMoves'] as int? ?? 50;
    
    // Stop timer
    _timer?.cancel();
    _timerActive = false;
    
    // Pause game
    state = state.copyWith(
      status: state.status.copyWith(isPaused: true),
    );
    
    // Show dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(strings.outOfMoves),
        content: Text(
          strings.outOfMovesMessage.replaceAll('{maxMoves}', maxMoves.toString()),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Retry level
              if (state.puzzle?.level != null) {
                startLevel(state.puzzle!.level!);
              }
            },
            child: Text(strings.retry),
          ),
          // TODO: Add "Watch Ad for +X Moves" button (hook only, no ad logic)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate back to Journey Map
              Navigator.of(context).pop();
            },
            child: Text(strings.backToMap),
          ),
        ],
      ),
    );
  }

  /// Fails the level (e.g., mistakeLimit exceeded)
  Future<void> _failLevel(BuildContext? context, {required String reason}) async {
    if (state.puzzle == null) return;
    
    // Stop timer
    _timer?.cancel();
    _timerActive = false;
    
    // Mark as failed
    state = state.copyWith(
      status: state.status.copyWith(
        isCompleted: false,
        isPlaying: false,
        isPaused: true,
      ),
    );
    
    HapticService.heavyImpact();
    SoundService.playError();
    
    if (context != null && context.mounted) {
      final strings = ref.read(appStringsProvider);
      final puzzle = state.puzzle!;
      final maxMistakes = puzzle.params['maxMistakes'] as int? ?? 5;
      
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(strings.levelFailed),
          content: Text(
            reason == 'mistakeLimit'
                ? strings.mistakeLimitExceeded.replaceAll('{maxMistakes}', maxMistakes.toString())
                : strings.levelFailedMessage,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Retry level
                if (state.puzzle?.level != null) {
                  startLevel(state.puzzle!.level!);
                }
              },
              child: Text(strings.retry),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate back to Journey Map
                Navigator.of(context).pop();
              },
              child: Text(strings.backToMap),
            ),
          ],
        ),
      );
    }
  }

}

/// Convenience provider for accessing game state
@riverpod
GameState gameState(GameStateRef ref) {
  return ref.watch(gameStateNotifierProvider);
}

/// Convenience provider for accessing puzzle
@riverpod
PuzzleModel? currentPuzzle(CurrentPuzzleRef ref) {
  return ref.watch(gameStateNotifierProvider).puzzle;
}

/// Convenience provider for accessing game status
@riverpod
GameStatus gameStatus(GameStatusRef ref) {
  return ref.watch(gameStateNotifierProvider).status;
}
