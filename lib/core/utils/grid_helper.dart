import '../constants/game_constants.dart';

/// Helper utilities for grid operations
class GridHelper {
  /// Converts a 2D int grid to a readable string representation
  static String gridToString(List<List<int>> grid) {
    final StringBuffer buffer = StringBuffer();
    for (final row in grid) {
      final rowStr = row.map((cell) {
        if (cell == GameConstants.cellEmpty) return '.';
        if (cell == GameConstants.cellSun) return 'S';
        return 'M';
      }).join(' ');
      buffer.writeln(rowStr);
    }
    return buffer.toString();
  }

  /// Creates a deep copy of a grid
  static List<List<int>> copyGrid(List<List<int>> grid) {
    return grid.map((row) => List<int>.from(row)).toList();
  }

  /// Checks if a grid is complete (no empty cells)
  static bool isComplete(List<List<int>> grid) {
    for (final row in grid) {
      if (row.contains(GameConstants.cellEmpty)) {
        return false;
      }
    }
    return true;
  }

  /// Counts the number of empty cells in a grid
  static int countEmptyCells(List<List<int>> grid) {
    int count = 0;
    for (final row in grid) {
      for (final cell in row) {
        if (cell == GameConstants.cellEmpty) {
          count++;
        }
      }
    }
    return count;
  }

  /// Gets the completion percentage of a grid
  static double getCompletionPercentage(List<List<int>> grid) {
    if (grid.isEmpty) return 0.0;
    final int totalCells = grid.length * grid[0].length;
    final int emptyCells = countEmptyCells(grid);
    return ((totalCells - emptyCells) / totalCells) * 100;
  }

  /// Checks if two grids are equal
  static bool areGridsEqual(List<List<int>> grid1, List<List<int>> grid2) {
    if (grid1.length != grid2.length) return false;
    for (int i = 0; i < grid1.length; i++) {
      if (grid1[i].length != grid2[i].length) return false;
      for (int j = 0; j < grid1[i].length; j++) {
        if (grid1[i][j] != grid2[i][j]) return false;
      }
    }
    return true;
  }
}

