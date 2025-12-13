// Example usage of PuzzleGenerator
// This file demonstrates how to use the puzzle generator

import 'puzzle_generator.dart';
import 'grid_validator.dart';

/// Example usage of the puzzle generator
void exampleUsage() {
  // Create a generator with a seed (for reproducible puzzles)
  final generator = PuzzleGenerator(seed: 12345);

  // Generate a 6x6 puzzle
  try {
    // Generate complete board first
    final completeBoard = generator.generateCompleteBoard(6);
    print('Generated 6x6 complete board:');
    _printGrid(completeBoard);

    // Validate the puzzle
    final isValid = GridValidator.isValidGrid(completeBoard);
    print('Puzzle is valid: $isValid');

    // Create a playable puzzle (with some cells removed)
    // difficultyFactor 0.5 means remove 50% of cells (keep 50%)
    final playablePuzzle = generator.createPlayablePuzzle(completeBoard, 0.5);
    print('\nPlayable puzzle (50% cells removed):');
    _printGrid(playablePuzzle);

    // Generate 8x8 complete board
    final largeBoard = generator.generateCompleteBoard(8);
    print('\n8x8 complete board:');
    _printGrid(largeBoard);
  } catch (e) {
    print('Error: $e');
  }
}

void _printGrid(List<List<int>> grid) {
  for (final row in grid) {
    final rowStr = row.map((cell) {
      if (cell == 0) return '.';
      if (cell == 1) return 'S'; // Sun
      return 'M'; // Moon
    }).join(' ');
    print(rowStr);
  }
}

