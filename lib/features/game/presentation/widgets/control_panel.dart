import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/hint_service.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../settings/screens/settings_screen.dart';
import '../controllers/game_controller.dart';
import 'help_overlay.dart';

/// Control Panel - Bottom bar with game controls
class ControlPanel extends ConsumerWidget {
  const ControlPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the notifier provider directly to get the state
    final gameState = ref.watch(gameStateNotifierProvider);
    final gameNotifier = ref.read(gameStateNotifierProvider.notifier);
    final strings = ref.watch(appStringsProvider);
    final status = gameState.status;
    final canUndo = gameState.undoStack.isNotEmpty;
    final canRedo = gameState.redoStack.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // First row: Main controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Undo Button
                _ControlButton(
                  icon: Icons.undo,
                  label: strings.undo,
                  onPressed: canUndo ? () => gameNotifier.undo() : null,
                  isActive: canUndo,
                ),
                // Redo Button
                _ControlButton(
                  icon: Icons.redo,
                  label: strings.redo,
                  onPressed: canRedo ? () => gameNotifier.redo() : null,
                  isActive: canRedo,
                ),
                // Clear Board Button
                _ControlButton(
                  icon: Icons.clear_all,
                  label: strings.clear,
                  onPressed: () => gameNotifier.clearBoard(),
                  isActive: false,
                ),
                // Pencil Mode Button
                _ControlButton(
                  icon: Icons.edit,
                  label: strings.pencil,
                  onPressed: () {
                    final wasActive = status.pencilMode;
                    gameNotifier.togglePencilMode();
                    // Show tooltip/toast when toggling ON
                    if (!wasActive && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(strings.noteModeDescription),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppTheme.inkDark.withOpacity(0.9),
                        ),
                      );
                    }
                  },
                  isActive: status.pencilMode,
                ),
                // Hint Button
                _HintButton(
                  onPressed: () => gameNotifier.showHint(context),
                ),
                // Help Button
                _ControlButton(
                  icon: Icons.help_outline,
                  label: strings.help,
                  onPressed: () {
                      _showHelpOverlay(context);
                  },
                  isActive: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpOverlay(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent, // Helper handles dimming
      builder: (context) => HelpOverlay(
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  // Deprecated menu dialog - replaced by HelpOverlay
  /*
  void _showMenuDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      ...
    );
  }
  */

  void _showPencilModeExplanation(BuildContext context, WidgetRef ref) {
    final strings = ref.read(appStringsProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.pencilMode),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.pencilModeDescription,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              strings.howToUse,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(strings.pencilModeTip1),
            Text(strings.pencilModeTip2),
            Text(strings.pencilModeTip3),
            Text(strings.pencilModeTip4),
            const SizedBox(height: 16),
            Text(
              strings.pencilModeTip,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.gotIt),
          ),
        ],
      ),
    );
  }
}

/// Individual control button
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isActive;

  const _ControlButton({
    required this.icon,
    required this.label,
    this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? onPressed : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.sunOrange.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 24,
                    color: isEnabled
                        ? (isActive ? AppTheme.sunOrange : AppTheme.inkDark)
                        : AppTheme.inkLight.withOpacity(0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: isEnabled
                          ? (isActive ? AppTheme.sunOrange : AppTheme.inkDark)
                          : AppTheme.inkLight.withOpacity(0.5),
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Hint button with remaining hints display
class _HintButton extends ConsumerStatefulWidget {
  final VoidCallback onPressed;

  const _HintButton({required this.onPressed});

  @override
  ConsumerState<_HintButton> createState() => _HintButtonState();
}

class _HintButtonState extends ConsumerState<_HintButton> {
  int _remainingHints = 5;

  @override
  void initState() {
    super.initState();
    _loadRemainingHints();
  }

  Future<void> _loadRemainingHints() async {
    final remaining = await HintService.getRemainingHints();
    if (mounted) {
      setState(() {
        _remainingHints = remaining;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canUse = _remainingHints > 0;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: canUse ? () async {
              widget.onPressed();
              await _loadRemainingHints(); // Refresh after using hint
            } : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 24,
                    color: canUse
                        ? AppTheme.inkDark
                        : AppTheme.inkLight.withOpacity(0.5),
                  ),
                  const SizedBox(height: 4),
                  Consumer(
                    builder: (context, ref, child) {
                      final strings = ref.watch(appStringsProvider);
                      return Text(
                        '${strings.hint} ($_remainingHints)',
                        style: TextStyle(
                          fontSize: 10,
                          color: canUse
                              ? AppTheme.inkDark
                              : AppTheme.inkLight.withOpacity(0.5),
                          fontWeight: FontWeight.normal,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

