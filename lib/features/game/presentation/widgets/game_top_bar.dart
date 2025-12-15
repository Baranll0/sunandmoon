import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/domain/mechanic_flag.dart';
import '../../domain/models/game_status.dart';
import '../controllers/game_controller.dart';

/// Top Bar - Displays timer and move count
class GameTopBar extends ConsumerWidget {
  const GameTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the notifier provider directly to get the status
    final gameState = ref.watch(gameStateNotifierProvider);
    final status = gameState.status;
    final puzzle = gameState.puzzle;
    final gameNotifier = ref.read(gameStateNotifierProvider.notifier);
    final strings = ref.watch(appStringsProvider);

    // Check for mechanics
    final hasMoveLimit = puzzle?.mechanics.contains(MechanicFlag.moveLimit) ?? false;
    final hasMistakeLimit = puzzle?.mechanics.contains(MechanicFlag.mistakeLimit) ?? false;
    final maxMoves = hasMoveLimit ? (puzzle?.params['maxMoves'] as int? ?? 50) : null;
    final maxMistakes = hasMistakeLimit ? (puzzle?.params['maxMistakes'] as int? ?? 5) : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left side: Timer (if active)
            if (status.mode == GameMode.speedRun || status.mode == GameMode.daily)
              _StatItem(
                icon: Icons.timer,
                value: _formatTime(status.elapsedSeconds),
                label: strings.time,
              ),
            // Center: Mechanics HUD (moveLimit, mistakeLimit)
            if (hasMoveLimit || hasMistakeLimit)
              Row(
                children: [
                  if (hasMoveLimit) ...[
                    _MechanicStatItem(
                      icon: Icons.touch_app,
                      value: '${status.moveCount}',
                      max: maxMoves!,
                      label: strings.stepsLabel,
                      color: status.moveCount >= maxMoves * 0.8 
                          ? AppTheme.errorRed 
                          : AppTheme.inkDark,
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (hasMistakeLimit) ...[
                    _MechanicStatItem(
                      icon: Icons.error_outline,
                      value: '${status.mistakeCount}',
                      max: maxMistakes!,
                      label: strings.mistakes,
                      color: status.mistakeCount >= maxMistakes * 0.8 
                          ? AppTheme.errorRed 
                          : AppTheme.inkDark,
                    ),
                    const SizedBox(width: 16),
                  ],
                ],
              ),
            // Right side: Steps Count (if no mechanics) or Pause button
            if (!hasMoveLimit && !hasMistakeLimit)
              _StatItem(
                icon: Icons.touch_app,
                value: '${status.moveCount}',
                label: strings.stepsLabel,
              ),
            // Pause/Resume Button
            if (status.mode == GameMode.speedRun || status.mode == GameMode.daily)
              IconButton(
                icon: Icon(
                  status.isPaused ? Icons.play_arrow : Icons.pause,
                  color: AppTheme.inkDark,
                ),
                onPressed: () => gameNotifier.togglePause(),
                tooltip: status.isPaused ? strings.resume : strings.pause,
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final int minutes = seconds ~/ 60;
    final int secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

/// Individual stat item
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.inkLight),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.inkDark,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.inkLight,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Mechanic stat item with max value (e.g., "5/10 moves")
class _MechanicStatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final int max;
  final String label;
  final Color color;

  const _MechanicStatItem({
    required this.icon,
    required this.value,
    required this.max,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$value/$max',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: AppTheme.inkLight,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

