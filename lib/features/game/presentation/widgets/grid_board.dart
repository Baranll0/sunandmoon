import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/domain/mechanic_flag.dart';
import '../../../../core/utils/region_layout_helper.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/cell_model.dart';
import '../../domain/models/puzzle_model.dart';
import '../controllers/game_controller.dart';
import 'cell_widget.dart';

/// Grid Board Widget - Displays the puzzle grid
class GridBoard extends ConsumerWidget {
  const GridBoard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the notifier provider directly to get the puzzle
    final gameState = ref.watch(gameStateNotifierProvider);
    final puzzle = gameState.puzzle;

    if (puzzle == null) {
      return const Center(
        child: Text(
          'No puzzle loaded',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate cell size to make grid perfectly square
        final double availableWidth = constraints.maxWidth;
        final double availableHeight = constraints.maxHeight;
        final double cellSize = (availableWidth / puzzle.size).clamp(0.0, availableHeight / puzzle.size);

        final hasRegions = puzzle.mechanics.contains(MechanicFlag.regions);
        final regionBoundaries = hasRegions 
            ? RegionLayoutHelper.getRegionBoundaries(puzzle.size)
            : <(int, int, bool)>[];

        return Container(
          padding: const EdgeInsets.all(8),
          child: Stack(
            children: [
              // Grid cells
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: puzzle.size,
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 2,
                  childAspectRatio: 1.0,
                ),
                itemCount: puzzle.size * puzzle.size,
                itemBuilder: (context, index) {
                  final int row = index ~/ puzzle.size;
                  final int col = index % puzzle.size;
                  final CellModel cell = puzzle.currentState[row][col];

                  return CellWidget(
                    cell: cell,
                    size: cellSize - 4, // Account for spacing
                    onTap: () {
                      final gameNotifier = ref.read(gameStateNotifierProvider.notifier);
                      gameNotifier.onCellTap(row, col, context: context);
                    },
                  );
                },
              ),
              // Region boundaries overlay
              if (hasRegions)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RegionBoundariesPainter(
                      gridSize: puzzle.size,
                      cellSize: cellSize,
                      boundaries: regionBoundaries,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Custom Painter for region boundaries
class _RegionBoundariesPainter extends CustomPainter {
  final int gridSize;
  final double cellSize;
  final List<(int row, int col, bool isVertical)> boundaries;

  _RegionBoundariesPainter({
    required this.gridSize,
    required this.cellSize,
    required this.boundaries,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.moonBlue.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    const spacing = 2.0; // Grid spacing
    const padding = 8.0; // Container padding

    for (final boundary in boundaries) {
      final (row, col, isVertical) = boundary;
      
      if (isVertical) {
        // Vertical line at column boundary
        final x = padding + (col * (cellSize + spacing)) + (cellSize / 2);
        final startY = padding;
        final endY = padding + (gridSize * (cellSize + spacing)) - spacing;
        
        canvas.drawLine(
          Offset(x, startY),
          Offset(x, endY),
          paint,
        );
      } else {
        // Horizontal line at row boundary
        final y = padding + (row * (cellSize + spacing)) + (cellSize / 2);
        final startX = padding;
        final endX = padding + (gridSize * (cellSize + spacing)) - spacing;
        
        canvas.drawLine(
          Offset(startX, y),
          Offset(endX, y),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RegionBoundariesPainter oldDelegate) {
    return oldDelegate.gridSize != gridSize ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.boundaries.length != boundaries.length;
  }
}
