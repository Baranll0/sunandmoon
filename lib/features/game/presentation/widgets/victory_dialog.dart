import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../domain/models/game_status.dart';
import '../../domain/models/puzzle_model.dart';

/// Victory Dialog - Shown when puzzle is completed
/// New flow: Only "Next Level" button, no "Back to Map" or "Replay"
class VictoryDialog extends ConsumerWidget {
  final GameStatus status;
  final PuzzleModel puzzle;
  final VoidCallback onNextLevel;
  final VoidCallback? onClose; // Optional close button (X in corner)

  const VictoryDialog({
    super.key,
    required this.status,
    required this.puzzle,
    required this.onNextLevel,
    this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Close button (X) in top-right corner
            if (onClose != null)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.inkLight),
                  onPressed: onClose,
                  tooltip: strings.cancel,
                ),
              ),
            SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Celebration Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.sunOrange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.celebration,
                      size: 50,
                      color: AppTheme.sunOrange,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Title
                  Text(
                    strings.puzzleSolved,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.inkDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Statistics
                  _StatRow(
                    icon: Icons.timer,
                    label: strings.time,
                    value: _formatTime(status.elapsedSeconds),
                    color: AppTheme.moonBlue,
                  ),
                  const SizedBox(height: 12),
                  _StatRow(
                    icon: Icons.touch_app,
                    label: strings.stepsLabel,
                    value: '${status.moveCount}',
                    color: AppTheme.sunOrange,
                  ),
                  if (status.hintsUsed > 0) ...[
                    const SizedBox(height: 12),
                    _StatRow(
                      icon: Icons.lightbulb_outline,
                      label: strings.hints,
                      value: '${status.hintsUsed}',
                      color: AppTheme.hintYellow,
                    ),
                  ],
                  const SizedBox(height: 32),
                  // Primary Button: Next Level only
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onNextLevel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.sunOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        strings.nextLevel,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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

/// Stat row widget
class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 16,
            color: AppTheme.inkLight,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

