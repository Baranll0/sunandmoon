import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

        return Container(
          padding: const EdgeInsets.all(8),
          child: GridView.builder(
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
                  gameNotifier.onCellTap(row, col);
                },
              );
            },
          ),
        );
      },
    );
  }
}
