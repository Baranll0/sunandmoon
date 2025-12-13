import 'package:flutter/material.dart';
import '../../domain/models/cell_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/game_constants.dart';

/// Widget representing a single cell in the puzzle grid
class CellWidget extends StatefulWidget {
  final CellModel cell;
  final VoidCallback onTap;
  final double size;

  const CellWidget({
    super.key,
    required this.cell,
    required this.onTap,
    required this.size,
  });

  @override
  State<CellWidget> createState() => _CellWidgetState();
}

class _CellWidgetState extends State<CellWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: GameConstants.animationFast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void didUpdateWidget(CellWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Animate when cell value changes
    if (oldWidget.cell.value != widget.cell.value && widget.cell.value != 0) {
      _animationController.forward(from: 0.0).then((_) {
        _animationController.reverse();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          border: Border.all(
            color: _getBorderColor(),
            width: 1.5,
          ),
        ),
        child: Stack(
          children: [
            // Main content
            Center(
              child: _buildCellContent(),
            ),
            // Pencil marks (small corner indicators)
            if (widget.cell.pencilMarks.isNotEmpty)
              _buildPencilMarks(),
            // Error overlay
            if (widget.cell.hasError)
              _buildErrorOverlay(),
            // Highlight overlay
            if (widget.cell.isHighlighted)
              _buildHighlightOverlay(),
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (widget.cell.isGiven) {
      // Given cells have a slightly different background
      return Colors.white.withOpacity(0.7);
    }
    return Colors.white;
  }

  Color _getBorderColor() {
    if (widget.cell.hasError) {
      return AppTheme.errorRed;
    }
    if (widget.cell.isHighlighted) {
      return AppTheme.hintYellow;
    }
    return AppTheme.gridLine;
  }

  Widget _buildCellContent() {
    if (widget.cell.value == GameConstants.cellEmpty) {
      return const SizedBox.shrink();
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: _buildSymbol(),
    );
  }

  Widget _buildSymbol() {
    if (widget.cell.value == GameConstants.cellSun) {
      return Icon(
        Icons.wb_sunny,
        size: widget.size * 0.5,
        color: AppTheme.sunOrange,
      );
    } else if (widget.cell.value == GameConstants.cellMoon) {
      return Icon(
        Icons.nightlight_round,
        size: widget.size * 0.5,
        color: AppTheme.moonBlue,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildPencilMarks() {
    // Enhanced pencil marks - more visible distinction
    // Show as small, subtle icons in corners to indicate hypothetical placements
    return Positioned.fill(
      child: Padding(
        padding: EdgeInsets.all(widget.size * 0.1),
        child: Wrap(
          spacing: widget.size * 0.05,
          runSpacing: widget.size * 0.05,
          alignment: WrapAlignment.start,
          children: widget.cell.pencilMarks.map((mark) {
            return Container(
              width: widget.size * 0.2,
              height: widget.size * 0.2,
              decoration: BoxDecoration(
                color: mark == GameConstants.cellSun
                    ? AppTheme.sunOrange.withOpacity(0.3)
                    : AppTheme.moonBlue.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Center(
                child: Text(
                  mark == GameConstants.cellSun ? 'S' : 'M',
                  style: TextStyle(
                    fontSize: widget.size * 0.1,
                    color: mark == GameConstants.cellSun
                        ? AppTheme.sunOrange
                        : AppTheme.moonBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.errorRed.withOpacity(0.2),
        border: Border.all(
          color: AppTheme.errorRed,
          width: 2,
        ),
      ),
    );
  }

  Widget _buildHighlightOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.hintYellow.withOpacity(0.3),
        border: Border.all(
          color: AppTheme.hintYellow,
          width: 2,
        ),
      ),
    );
  }
}
