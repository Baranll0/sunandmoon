import '../constants/game_constants.dart';
import 'grid_validator.dart';
import 'grid_helper.dart';

/// Logic Solver - Mimics human player logic
/// Used internally by PuzzleGenerator to verify solvability
/// Implements human logic strategies to solve puzzles without guessing
class PuzzleSolver {
  /// Attempts to solve a partial puzzle using pure logic (no guessing)
  /// Returns true if the puzzle can be solved using only logical strategies
  /// Returns false if the puzzle requires guessing or has multiple solutions
  static bool canSolveLogically(List<List<int>> puzzle, int size) {
    final List<List<int>> grid = puzzle.map((row) => List<int>.from(row)).toList();
    bool progress = true;
    int iterations = 0;
    const int maxIterations = 100; // Prevent infinite loops

    // Keep applying logic strategies until no more progress can be made
    while (progress && iterations < maxIterations) {
      progress = false;
      iterations++;

      // Strategy 1: Three-in-a-row rule
      if (_applyThreeInARowRule(grid, size)) {
        progress = true;
        continue;
      }

      // Strategy 2: Sandwich rule
      if (_applySandwichRule(grid, size)) {
        progress = true;
        continue;
      }

      // Strategy 3: Row/Column balance rule
      if (_applyBalanceRule(grid, size)) {
        progress = true;
        continue;
      }

      // Strategy 4: Avoid duplicate rows/columns
      if (_applyUniquenessRule(grid, size)) {
        progress = true;
        continue;
      }
    }

    // Check if puzzle is complete and valid
    if (GridHelper.isComplete(grid)) {
      return GridValidator.isValidGrid(grid);
    }

    // If puzzle is not complete, it requires guessing (not solvable by pure logic)
    return false;
  }

  /// Strategy 1: Three-in-a-row rule
  /// If we have A-A-?, then ? MUST be B (to avoid 3 consecutive)
  static bool _applyThreeInARowRule(List<List<int>> grid, int size) {
    bool progress = false;

    // Check rows
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size - 2; col++) {
        final val1 = grid[row][col];
        final val2 = grid[row][col + 1];
        final val3 = grid[row][col + 2];

        // Pattern: A-A-? -> ? must be B
        if (val1 != GameConstants.cellEmpty &&
            val1 == val2 &&
            val3 == GameConstants.cellEmpty) {
          grid[row][col + 2] = _getOpposite(val1);
          progress = true;
        }

        // Pattern: ?-A-A -> ? must be B
        if (val1 == GameConstants.cellEmpty &&
            val2 != GameConstants.cellEmpty &&
            val2 == val3) {
          grid[row][col] = _getOpposite(val2);
          progress = true;
        }

        // Pattern: A-?-A -> ? must be B (to avoid 3 consecutive)
        if (val1 != GameConstants.cellEmpty &&
            val1 == val3 &&
            val2 == GameConstants.cellEmpty) {
          grid[row][col + 1] = _getOpposite(val1);
          progress = true;
        }
      }
    }

    // Check columns
    for (int col = 0; col < size; col++) {
      for (int row = 0; row < size - 2; row++) {
        final val1 = grid[row][col];
        final val2 = grid[row + 1][col];
        final val3 = grid[row + 2][col];

        // Pattern: A-A-? -> ? must be B
        if (val1 != GameConstants.cellEmpty &&
            val1 == val2 &&
            val3 == GameConstants.cellEmpty) {
          grid[row + 2][col] = _getOpposite(val1);
          progress = true;
        }

        // Pattern: ?-A-A -> ? must be B
        if (val1 == GameConstants.cellEmpty &&
            val2 != GameConstants.cellEmpty &&
            val2 == val3) {
          grid[row][col] = _getOpposite(val2);
          progress = true;
        }

        // Pattern: A-?-A -> ? must be B
        if (val1 != GameConstants.cellEmpty &&
            val1 == val3 &&
            val2 == GameConstants.cellEmpty) {
          grid[row + 1][col] = _getOpposite(val1);
          progress = true;
        }
      }
    }

    return progress;
  }

  /// Strategy 2: Sandwich rule
  /// If we have A-?-A, then ? MUST be B (to avoid 3 consecutive)
  static bool _applySandwichRule(List<List<int>> grid, int size) {
    bool progress = false;

    // Check rows
    for (int row = 0; row < size; row++) {
      for (int col = 1; col < size - 1; col++) {
        final val1 = grid[row][col - 1];
        final val2 = grid[row][col];
        final val3 = grid[row][col + 1];

        // Pattern: A-?-A -> ? must be B
        if (val1 != GameConstants.cellEmpty &&
            val1 == val3 &&
            val2 == GameConstants.cellEmpty) {
          grid[row][col] = _getOpposite(val1);
          progress = true;
        }
      }
    }

    // Check columns
    for (int col = 0; col < size; col++) {
      for (int row = 1; row < size - 1; row++) {
        final val1 = grid[row - 1][col];
        final val2 = grid[row][col];
        final val3 = grid[row + 1][col];

        // Pattern: A-?-A -> ? must be B
        if (val1 != GameConstants.cellEmpty &&
            val1 == val3 &&
            val2 == GameConstants.cellEmpty) {
          grid[row][col] = _getOpposite(val1);
          progress = true;
        }
      }
    }

    return progress;
  }

  /// Strategy 3: Row/Column balance rule
  /// If a row/col has N/2 of one symbol, all remaining empty cells MUST be the opposite
  static bool _applyBalanceRule(List<List<int>> grid, int size) {
    bool progress = false;
    final int targetCount = size ~/ 2;

    // Check rows
    for (int row = 0; row < size; row++) {
      int sunCount = 0;
      int moonCount = 0;
      int emptyCount = 0;

      for (int col = 0; col < size; col++) {
        if (grid[row][col] == GameConstants.cellSun) {
          sunCount++;
        } else if (grid[row][col] == GameConstants.cellMoon) {
          moonCount++;
        } else {
          emptyCount++;
        }
      }

      // If we have exactly N/2 of one symbol, fill remaining with opposite
      if (sunCount == targetCount && emptyCount > 0) {
        for (int col = 0; col < size; col++) {
          if (grid[row][col] == GameConstants.cellEmpty) {
            grid[row][col] = GameConstants.cellMoon;
            progress = true;
          }
        }
      } else if (moonCount == targetCount && emptyCount > 0) {
        for (int col = 0; col < size; col++) {
          if (grid[row][col] == GameConstants.cellEmpty) {
            grid[row][col] = GameConstants.cellSun;
            progress = true;
          }
        }
      }
    }

    // Check columns
    for (int col = 0; col < size; col++) {
      int sunCount = 0;
      int moonCount = 0;
      int emptyCount = 0;

      for (int row = 0; row < size; row++) {
        if (grid[row][col] == GameConstants.cellSun) {
          sunCount++;
        } else if (grid[row][col] == GameConstants.cellMoon) {
          moonCount++;
        } else {
          emptyCount++;
        }
      }

      // If we have exactly N/2 of one symbol, fill remaining with opposite
      if (sunCount == targetCount && emptyCount > 0) {
        for (int row = 0; row < size; row++) {
          if (grid[row][col] == GameConstants.cellEmpty) {
            grid[row][col] = GameConstants.cellMoon;
            progress = true;
          }
        }
      } else if (moonCount == targetCount && emptyCount > 0) {
        for (int row = 0; row < size; row++) {
          if (grid[row][col] == GameConstants.cellEmpty) {
            grid[row][col] = GameConstants.cellSun;
            progress = true;
          }
        }
      }
    }

    return progress;
  }

  /// Strategy 4: Avoid duplicate rows/columns
  /// If completing a row/col would make it identical to another, we must use the opposite
  static bool _applyUniquenessRule(List<List<int>> grid, int size) {
    bool progress = false;

    // Check rows
    for (int row = 0; row < size; row++) {
      // Count how many cells are filled in this row
      int filledCount = 0;
      for (int col = 0; col < size; col++) {
        if (grid[row][col] != GameConstants.cellEmpty) {
          filledCount++;
        }
      }

      // Only apply if row is almost complete (1-2 empty cells)
      if (filledCount >= size - 2) {
        // Check against other completed rows
        for (int otherRow = 0; otherRow < size; otherRow++) {
          if (otherRow == row) continue;

          // Check if other row is complete
          bool otherComplete = true;
          for (int col = 0; col < size; col++) {
            if (grid[otherRow][col] == GameConstants.cellEmpty) {
              otherComplete = false;
              break;
            }
          }

          if (!otherComplete) continue;

          // Check if current row would be identical if we fill remaining cells
          bool wouldBeIdentical = true;
          int emptyCol = -1;
          for (int col = 0; col < size; col++) {
            if (grid[row][col] == GameConstants.cellEmpty) {
              if (emptyCol == -1) {
                emptyCol = col;
              } else {
                wouldBeIdentical = false;
                break;
              }
            } else if (grid[row][col] != grid[otherRow][col]) {
              wouldBeIdentical = false;
              break;
            }
          }

          // If would be identical and we have exactly one empty cell, fill with opposite
          if (wouldBeIdentical && emptyCol >= 0) {
            final oppositeValue = _getOpposite(grid[otherRow][emptyCol]);
            grid[row][emptyCol] = oppositeValue;
            progress = true;
            break;
          }
        }
      }
    }

    // Check columns (similar logic)
    for (int col = 0; col < size; col++) {
      int filledCount = 0;
      for (int row = 0; row < size; row++) {
        if (grid[row][col] != GameConstants.cellEmpty) {
          filledCount++;
        }
      }

      if (filledCount >= size - 2) {
        for (int otherCol = 0; otherCol < size; otherCol++) {
          if (otherCol == col) continue;

          bool otherComplete = true;
          for (int row = 0; row < size; row++) {
            if (grid[row][otherCol] == GameConstants.cellEmpty) {
              otherComplete = false;
              break;
            }
          }

          if (!otherComplete) continue;

          bool wouldBeIdentical = true;
          int emptyRow = -1;
          for (int row = 0; row < size; row++) {
            if (grid[row][col] == GameConstants.cellEmpty) {
              if (emptyRow == -1) {
                emptyRow = row;
              } else {
                wouldBeIdentical = false;
                break;
              }
            } else if (grid[row][col] != grid[row][otherCol]) {
              wouldBeIdentical = false;
              break;
            }
          }

          if (wouldBeIdentical && emptyRow >= 0) {
            final oppositeValue = _getOpposite(grid[emptyRow][otherCol]);
            grid[emptyRow][col] = oppositeValue;
            progress = true;
            break;
          }
        }
      }
    }

    return progress;
  }

  /// Helper: Get opposite value
  static int _getOpposite(int value) {
    if (value == GameConstants.cellSun) {
      return GameConstants.cellMoon;
    } else if (value == GameConstants.cellMoon) {
      return GameConstants.cellSun;
    }
    return GameConstants.cellEmpty;
  }

  /// Counts how many solutions exist for a partial puzzle
  /// Returns 0, 1, or 2+ (stops counting after 2 for efficiency)
  static int countSolutions(List<List<int>> partialPuzzle, int size) {
    int solutionCount = 0;
    final List<List<int>> testGrid = partialPuzzle.map((row) => List<int>.from(row)).toList();
    
    _countSolutionsRecursive(testGrid, 0, 0, size, () {
      solutionCount++;
      // Stop counting after 2 solutions (not unique)
      return solutionCount < 2;
    });
    
    return solutionCount;
  }

  /// Recursive backtracking to count solutions
  static void _countSolutionsRecursive(
    List<List<int>> grid,
    int row,
    int col,
    int size,
    bool Function() onSolution,
  ) {
    // Base case: if we've filled all cells, check if it's a valid solution
    if (row == size) {
      if (GridValidator.isValidGrid(grid)) {
        if (!onSolution()) {
          return; // Stop counting (found 2+ solutions)
        }
      }
      return;
    }

    // Calculate next position
    int nextRow = col == size - 1 ? row + 1 : row;
    int nextCol = col == size - 1 ? 0 : col + 1;

    // If current cell is already filled (given), skip it
    if (grid[row][col] != GameConstants.cellEmpty) {
      _countSolutionsRecursive(grid, nextRow, nextCol, size, onSolution);
      return;
    }

    // Try placing Sun and Moon
    for (int value in [GameConstants.cellSun, GameConstants.cellMoon]) {
      grid[row][col] = value;

      // Check if current placement is valid so far
      if (_isValidPlacement(grid, row, col, size)) {
        _countSolutionsRecursive(grid, nextRow, nextCol, size, onSolution);
      }

      // Backtrack
      grid[row][col] = GameConstants.cellEmpty;
    }
  }

  /// Validates if placing a value at (row, col) satisfies constraints
  static bool _isValidPlacement(List<List<int>> grid, int row, int col, int size) {
    final int value = grid[row][col];
    final int expectedCount = size ~/ 2;

    // Constraint 1: No more than 2 identical symbols adjacent (horizontally)
    if (col >= 2) {
      if (grid[row][col - 1] == value && grid[row][col - 2] == value) {
        return false;
      }
    }

    // Constraint 2: No more than 2 identical symbols adjacent (vertically)
    if (row >= 2) {
      if (grid[row - 1][col] == value && grid[row - 2][col] == value) {
        return false;
      }
    }

    // Constraint 3: Row balance (count current row)
    int rowSunCount = 0;
    int rowMoonCount = 0;
    for (int c = 0; c < size; c++) {
      if (grid[row][c] == GameConstants.cellSun) rowSunCount++;
      if (grid[row][c] == GameConstants.cellMoon) rowMoonCount++;
    }
    if (value == GameConstants.cellSun && rowSunCount > expectedCount) return false;
    if (value == GameConstants.cellMoon && rowMoonCount > expectedCount) return false;

    // Constraint 4: Column balance (count current column)
    int colSunCount = 0;
    int colMoonCount = 0;
    for (int r = 0; r < size; r++) {
      if (grid[r][col] == GameConstants.cellSun) colSunCount++;
      if (grid[r][col] == GameConstants.cellMoon) colMoonCount++;
    }
    if (value == GameConstants.cellSun && colSunCount > expectedCount) return false;
    if (value == GameConstants.cellMoon && colMoonCount > expectedCount) return false;

    return true;
  }
}

