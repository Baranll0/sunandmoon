import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/game_controller.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/hint_service.dart';
import 'help_overlay.dart';
import '../../../../core/constants/game_constants.dart';

/// Control panel widget with toolbar and game actions
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
    final selectedTool = status.selectedTool; // Access selectedTool

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
            // Row 1: Tools (Sun, Moon, Eraser)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Sun Tool
                  _ToolButton(
                    icon: Icons.wb_sunny,
                    label: strings.sun,
                    color: AppTheme.sunOrange,
                    isSelected: selectedTool == GameConstants.cellSun,
                    onPressed: () => gameNotifier.selectTool(GameConstants.cellSun),
                  ),
                  const SizedBox(width: 8),
                  // Moon Tool
                  _ToolButton(
                    icon: Icons.nightlight_round,
                    label: strings.moon,
                    color: AppTheme.moonBlue,
                    isSelected: selectedTool == GameConstants.cellMoon,
                    onPressed: () => gameNotifier.selectTool(GameConstants.cellMoon),
                  ),
                  const SizedBox(width: 8),
                  // Eraser Tool
                  _ToolButton(
                    icon: Icons.cleaning_services_outlined, // or highlight_off
                    label: strings.erase, // Need string or hardcode for now
                    color: AppTheme.inkLight,
                    isSelected: selectedTool == GameConstants.cellEmpty,
                    onPressed: () => gameNotifier.selectTool(GameConstants.cellEmpty),
                  ),
                ],
              ),
            ),
            
            // Row 2: Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Undo
                _ControlButton(
                  icon: Icons.undo,
                  label: strings.undo,
                  onPressed: canUndo ? () => gameNotifier.undo() : null,
                  isActive: canUndo,
                ),
                // Redo
                _ControlButton(
                  icon: Icons.redo,
                  label: strings.redo,
                  onPressed: canRedo ? () => gameNotifier.redo() : null,
                  isActive: canRedo,
                ),
                // Pencil Mode
                _ControlButton(
                  icon: Icons.edit,
                  label: strings.pencil,
                  onPressed: () {
                    final wasActive = status.pencilMode;
                    gameNotifier.togglePencilMode();
                    if (!wasActive && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(strings.noteModeDescription),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  isActive: status.pencilMode,
                  activeColor: AppTheme.inkDark, // Distinct active color
                ),
                // Hint
                _HintButton(
                  onPressed: () => gameNotifier.showHint(context),
                ),
                // Menu/Help
                _ControlButton(
                  icon: Icons.menu,
                  label: strings.menu,
                  onPressed: () => _showHelpOverlay(context),
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
  final Color? activeColor; // Added optional active color

  const _ControlButton({
    required this.icon,
    required this.label,
    this.onPressed,
    this.isActive = false,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null;
    final effectiveActiveColor = activeColor ?? AppTheme.sunOrange;

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
                    ? effectiveActiveColor.withOpacity(0.1)
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
                        ? (isActive ? effectiveActiveColor : AppTheme.inkDark)
                        : AppTheme.inkLight.withOpacity(0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: isEnabled
                          ? (isActive ? effectiveActiveColor : AppTheme.inkDark)
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

/// Tool selection button (Sun, Moon, Eraser)
class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onPressed;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? color : color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : Colors.transparent,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 28,
                  color: isSelected ? Colors.white : color,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

