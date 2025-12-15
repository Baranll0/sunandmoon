import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/level_manager.dart';
import '../../../../core/services/progress_service.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../domain/models/puzzle_model.dart';
import '../controllers/game_controller.dart';
import '../widgets/grid_board.dart';
import '../widgets/control_panel.dart';
import '../widgets/game_top_bar.dart';
import '../widgets/victory_dialog.dart';
import '../../../home/screens/saga_map_screen.dart' show JourneyScreen;

/// Main Game Screen
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late ConfettiController _confettiController;
  bool _hasShownVictoryDialog = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the notifier provider directly to get the state
    final gameState = ref.watch(gameStateNotifierProvider);
    final puzzle = gameState.puzzle;
    final status = gameState.status;

    // Show victory dialog when puzzle is completed
    if (status.isCompleted && puzzle != null && !_hasShownVictoryDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showVictoryDialog(context, ref, puzzle, status);
        _hasShownVictoryDialog = true;
      });
    }

    // Reset flag when new game starts
    if (!status.isCompleted && _hasShownVictoryDialog) {
      _hasShownVictoryDialog = false;
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundCream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.grid_view_rounded),
          onPressed: () => _showPauseMenu(context, ref),
        ),
        title: puzzle?.level != null
            ? Builder(
                builder: (context) {
                  final strings = ref.watch(appStringsProvider);
                  return Text(
                    '${strings.chapter} ${puzzle!.level!.chapter} - ${strings.level} ${puzzle!.level!.level}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.inkDark,
                    ),
                  );
                },
              )
            : null,
      ),
      body: Stack(
        children: [
          // Main content
          puzzle == null
              ? _buildEmptyState(context, ref)
              : _buildGameContent(context),
          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 3.14 / 2, // Downward
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
              shouldLoop: false,
              colors: const [
                AppTheme.sunOrange,
                AppTheme.moonBlue,
                AppTheme.hintYellow,
                Colors.white,
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showVictoryDialog(
    BuildContext context,
    WidgetRef ref,
    puzzle,
    status,
  ) {
    // Trigger confetti
    _confettiController.play();

    // Show victory dialog after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => VictoryDialog(
          status: status,
          puzzle: puzzle,
          onNextLevel: () async {
            Navigator.of(context).pop();
            final gameNotifier = ref.read(gameStateNotifierProvider.notifier);
            
            // New flow: Always go to Journey map, focus next node
            if (puzzle.level != null) {
              // Mark current level as completed
              await ProgressService.completeLevel(puzzle.level!);
              
              // Get next level
              final nextLevel = LevelManager.getNextLevel(puzzle.level!);
              
              if (nextLevel != null) {
                // Unlock next level
                await ProgressService.saveMaxUnlockedLevel(nextLevel);
              }
              
              // Clear game and navigate to Journey
              gameNotifier.clearGame();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => JourneyScreen(
                      focusLevel: nextLevel, // Pass next level to focus
                    ),
                  ),
                  (route) => false,
                );
              }
              _hasShownVictoryDialog = false;
            } else {
              // Fallback for old puzzles without level info
              gameNotifier.clearGame();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const JourneyScreen(),
                  ),
                  (route) => false,
                );
              }
              _hasShownVictoryDialog = false;
            }
          },
          onClose: () {
            // Optional: Close dialog without action (user can tap outside or X)
            Navigator.of(context).pop();
          },
        ),
      );
    });
  }

  PuzzleDifficulty _getNextDifficulty(PuzzleDifficulty current) {
    switch (current) {
      case PuzzleDifficulty.easy:
        return PuzzleDifficulty.medium;
      case PuzzleDifficulty.medium:
        return PuzzleDifficulty.hard;
      case PuzzleDifficulty.hard:
        return PuzzleDifficulty.expert;
      case PuzzleDifficulty.expert:
        return PuzzleDifficulty.expert; // Stay at expert
    }
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.grid_on,
            size: 64,
            color: AppTheme.inkLight,
          ),
          const SizedBox(height: 16),
          Consumer(
            builder: (context, ref, child) {
              final strings = ref.watch(appStringsProvider);
              return Column(
                children: [
          Text(
                    strings.noPuzzleLoaded,
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 8),
          Text(
                    strings.startNewGame,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate back or show difficulty selector
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.play_arrow),
                    label: Text(strings.newGame),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.sunOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGameContent(BuildContext context) {
    return Column(
      children: [
        // Top Bar
        const GameTopBar(),
        // Grid Board (expanded to fill available space)
        Expanded(
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate max size for grid to be square
                final double maxSize = constraints.maxWidth < constraints.maxHeight
                    ? constraints.maxWidth
                    : constraints.maxHeight;
                return SizedBox(
                  width: maxSize,
                  height: maxSize,
                  child: const GridBoard(),
                );
              },
            ),
          ),
        ),
        // Control Panel
        const ControlPanel(),
      ],
    );
  }

  /// Show pause menu dialog
  void _showPauseMenu(BuildContext context, WidgetRef ref) {
    final gameNotifier = ref.read(gameStateNotifierProvider.notifier);
    final strings = ref.watch(appStringsProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.menu),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: Text(strings.resume),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: Text(strings.restart),
              onTap: () {
                Navigator.of(context).pop();
                // Restart current level
                final gameState = ref.read(gameStateNotifierProvider);
                if (gameState.puzzle?.level != null) {
                  gameNotifier.startLevel(gameState.puzzle!.level!);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: Text(strings.exitToMap),
              onTap: () {
                Navigator.of(context).pop();
                // Clear game state and navigate to journey
                gameNotifier.clearGame();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const JourneyScreen()),
                  (route) => false, // Remove all previous routes
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
