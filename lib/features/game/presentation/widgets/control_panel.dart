import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/hint_service.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../settings/screens/settings_screen.dart';
import '../controllers/game_controller.dart';

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
                // Menu Button
                _ControlButton(
                  icon: Icons.menu,
                  label: strings.menu,
                  onPressed: () {
                    _showMenuDialog(context, ref);
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

  void _showMenuDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.settings, color: AppTheme.inkDark),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.home, color: AppTheme.inkDark),
                title: const Text('Home'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPencilModeExplanation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pencil Mode'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pencil Mode allows you to mark possible values in empty cells without committing to them.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'How to use:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text('1. Tap the Pencil button to activate Pencil Mode'),
            Text('2. Tap an empty cell to add/remove pencil marks'),
            Text('3. Pencil marks help you track possible values'),
            Text('4. Tap the Pencil button again to deactivate'),
            SizedBox(height: 16),
            Text(
              'Tip: Use pencil marks to work through logic without making permanent moves.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
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

