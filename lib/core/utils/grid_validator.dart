import '../constants/game_constants.dart';

/// Grid Validator - Validates puzzle grids according to Takuzu/Binairo rules
class GridValidator {
  /// Validates if a grid follows all Takuzu/Binairo rules:
  /// 1. Equal number of Suns (1) and Moons (2) in every row and column
  /// 2. No more than two of the same symbol adjacent (horizontally or vertically)
  /// 3. No two rows can be identical
  /// 4. No two columns can be identical
  static bool isValidGrid(List<List<int>> grid) {
    if (grid.isEmpty || grid.length != grid[0].length) {
      return false;
    }

    final int size = grid.length;
    final int expectedCount = size ~/ 2;

    // Check rows
    for (int row = 0; row < size; row++) {
      if (!_isValidRow(grid[row], expectedCount)) {
        return false;
      }
    }

    // Check columns
    for (int col = 0; col < size; col++) {
      if (!_isValidColumn(grid, col, expectedCount)) {
        return false;
      }
    }

    // Check for duplicate rows
    for (int i = 0; i < size; i++) {
      for (int j = i + 1; j < size; j++) {
        if (_areRowsEqual(grid[i], grid[j])) {
          return false;
        }
      }
    }

    // Check for duplicate columns
    for (int i = 0; i < size; i++) {
      for (int j = i + 1; j < size; j++) {
        if (_areColumnsEqual(grid, i, j)) {
          return false;
        }
      }
    }

    return true;
  }

  /// Validates a single row
  static bool _isValidRow(List<int> row, int expectedCount) {
    int sunCount = 0;
    int moonCount = 0;

    for (int i = 0; i < row.length; i++) {
      if (row[i] == GameConstants.cellSun) {
        sunCount++;
      } else if (row[i] == GameConstants.cellMoon) {
        moonCount++;
      }

      // Check for three consecutive same values
      if (i >= 2) {
        if (row[i] == row[i - 1] && row[i] == row[i - 2] && row[i] != GameConstants.cellEmpty) {
          return false;
        }
      }
    }

    return sunCount == expectedCount && moonCount == expectedCount;
  }

  /// Validates a single column
  static bool _isValidColumn(List<List<int>> grid, int col, int expectedCount) {
    int sunCount = 0;
    int moonCount = 0;

    for (int i = 0; i < grid.length; i++) {
      if (grid[i][col] == GameConstants.cellSun) {
        sunCount++;
      } else if (grid[i][col] == GameConstants.cellMoon) {
        moonCount++;
      }

      // Check for three consecutive same values
      if (i >= 2) {
        if (grid[i][col] == grid[i - 1][col] &&
            grid[i][col] == grid[i - 2][col] &&
            grid[i][col] != GameConstants.cellEmpty) {
          return false;
        }
      }
    }

    return sunCount == expectedCount && moonCount == expectedCount;
  }

  /// Checks if two rows are equal (ignoring empty cells)
  static bool _areRowsEqual(List<int> row1, List<int> row2) {
    if (row1.length != row2.length) return false;

    // Check if both rows are complete (no empty cells)
    bool row1Complete = row1.every((cell) => cell != GameConstants.cellEmpty);
    bool row2Complete = row2.every((cell) => cell != GameConstants.cellEmpty);

    if (!row1Complete || !row2Complete) {
      return false; // Incomplete rows can't be considered duplicates
    }

    for (int i = 0; i < row1.length; i++) {
      if (row1[i] != row2[i]) {
        return false;
      }
    }

    return true;
  }

  /// Checks if two columns are equal (ignoring empty cells)
  static bool _areColumnsEqual(List<List<int>> grid, int col1, int col2) {
    // Check if both columns are complete (no empty cells)
    bool col1Complete = true;
    bool col2Complete = true;

    for (int i = 0; i < grid.length; i++) {
      if (grid[i][col1] == GameConstants.cellEmpty) col1Complete = false;
      if (grid[i][col2] == GameConstants.cellEmpty) col2Complete = false;
    }

    if (!col1Complete || !col2Complete) {
      return false; // Incomplete columns can't be considered duplicates
    }

    for (int i = 0; i < grid.length; i++) {
      if (grid[i][col1] != grid[i][col2]) {
        return false;
      }
    }

    return true;
  }

  /// Validates a partial grid (for in-game validation)
  /// Returns a list of violations found
  static List<GridViolation> validatePartialGrid(List<List<int>> grid) {
    final List<GridViolation> violations = [];
    final int size = grid.length;
    final int expectedCount = size ~/ 2;

    // Check rows
    for (int row = 0; row < size; row++) {
      final rowViolations = _validateRowPartial(grid[row], row, expectedCount);
      violations.addAll(rowViolations);
    }

    // Check columns
    for (int col = 0; col < size; col++) {
      final colViolations = _validateColumnPartial(grid, col, expectedCount);
      violations.addAll(colViolations);
    }

    // Check for duplicate rows (only if complete)
    for (int i = 0; i < size; i++) {
      for (int j = i + 1; j < size; j++) {
        if (_areRowsEqual(grid[i], grid[j])) {
          violations.add(GridViolation(
            type: ViolationType.duplicateRow,
            row: i,
            column: -1,
            message: 'Row $i and Row $j are identical',
          ));
        }
      }
    }

    // Check for duplicate columns (only if complete)
    for (int i = 0; i < size; i++) {
      for (int j = i + 1; j < size; j++) {
        if (_areColumnsEqual(grid, i, j)) {
          violations.add(GridViolation(
            type: ViolationType.duplicateColumn,
            row: -1,
            column: i,
            message: 'Column $i and Column $j are identical',
          ));
        }
      }
    }

    return violations;
  }

  /// Validates a row partially (for hints)
  static List<GridViolation> _validateRowPartial(
    List<int> row,
    int rowIndex,
    int expectedCount,
  ) {
    final List<GridViolation> violations = [];
    int sunCount = 0;
    int moonCount = 0;

    for (int i = 0; i < row.length; i++) {
      if (row[i] == GameConstants.cellSun) {
        sunCount++;
      } else if (row[i] == GameConstants.cellMoon) {
        moonCount++;
      }

      // Check for three consecutive same values
      // Mark all 3 cells when violation is found
      if (i >= 2) {
        if (row[i] == row[i - 1] && row[i] == row[i - 2] && row[i] != GameConstants.cellEmpty) {
          // Mark all 3 consecutive cells
          violations.add(GridViolation(
            type: ViolationType.threeConsecutive,
            row: rowIndex,
            column: i - 2,
            message: 'Three consecutive ${row[i] == GameConstants.cellSun ? "Suns" : "Moons"} in row $rowIndex',
          ));
          violations.add(GridViolation(
            type: ViolationType.threeConsecutive,
            row: rowIndex,
            column: i - 1,
            message: 'Three consecutive ${row[i] == GameConstants.cellSun ? "Suns" : "Moons"} in row $rowIndex',
          ));
          violations.add(GridViolation(
            type: ViolationType.threeConsecutive,
            row: rowIndex,
            column: i,
            message: 'Three consecutive ${row[i] == GameConstants.cellSun ? "Suns" : "Moons"} in row $rowIndex',
          ));
        }
      }
    }

    // Check count violations (only if row is complete)
    bool isComplete = row.every((cell) => cell != GameConstants.cellEmpty);
    if (isComplete) {
      if (sunCount != expectedCount) {
        violations.add(GridViolation(
          type: ViolationType.countMismatch,
          row: rowIndex,
          column: -1,
          message: 'Row $rowIndex has $sunCount Suns, expected $expectedCount',
        ));
      }
      if (moonCount != expectedCount) {
        violations.add(GridViolation(
          type: ViolationType.countMismatch,
          row: rowIndex,
          column: -1,
          message: 'Row $rowIndex has $moonCount Moons, expected $expectedCount',
        ));
      }
    }

    return violations;
  }

  /// Validates a column partially (for hints)
  static List<GridViolation> _validateColumnPartial(
    List<List<int>> grid,
    int colIndex,
    int expectedCount,
  ) {
    final List<GridViolation> violations = [];
    int sunCount = 0;
    int moonCount = 0;

    for (int i = 0; i < grid.length; i++) {
      if (grid[i][colIndex] == GameConstants.cellSun) {
        sunCount++;
      } else if (grid[i][colIndex] == GameConstants.cellMoon) {
        moonCount++;
      }

      // Check for three consecutive same values
      // Mark all 3 cells when violation is found
      if (i >= 2) {
        if (grid[i][colIndex] == grid[i - 1][colIndex] &&
            grid[i][colIndex] == grid[i - 2][colIndex] &&
            grid[i][colIndex] != GameConstants.cellEmpty) {
          // Mark all 3 consecutive cells
          violations.add(GridViolation(
            type: ViolationType.threeConsecutive,
            row: i - 2,
            column: colIndex,
            message: 'Three consecutive ${grid[i][colIndex] == GameConstants.cellSun ? "Suns" : "Moons"} in column $colIndex',
          ));
          violations.add(GridViolation(
            type: ViolationType.threeConsecutive,
            row: i - 1,
            column: colIndex,
            message: 'Three consecutive ${grid[i][colIndex] == GameConstants.cellSun ? "Suns" : "Moons"} in column $colIndex',
          ));
          violations.add(GridViolation(
            type: ViolationType.threeConsecutive,
            row: i,
            column: colIndex,
            message: 'Three consecutive ${grid[i][colIndex] == GameConstants.cellSun ? "Suns" : "Moons"} in column $colIndex',
          ));
        }
      }
    }

    // Check count violations (only if column is complete)
    bool isComplete = true;
    for (int i = 0; i < grid.length; i++) {
      if (grid[i][colIndex] == GameConstants.cellEmpty) {
        isComplete = false;
        break;
      }
    }

    if (isComplete) {
      if (sunCount != expectedCount) {
        violations.add(GridViolation(
          type: ViolationType.countMismatch,
          row: -1,
          column: colIndex,
          message: 'Column $colIndex has $sunCount Suns, expected $expectedCount',
        ));
      }
      if (moonCount != expectedCount) {
        violations.add(GridViolation(
          type: ViolationType.countMismatch,
          row: -1,
          column: colIndex,
          message: 'Column $colIndex has $moonCount Moons, expected $expectedCount',
        ));
      }
    }

    return violations;
  }
}

/// Represents a violation found in the grid
class GridViolation {
  final ViolationType type;
  final int row;
  final int column;
  final String message;

  GridViolation({
    required this.type,
    required this.row,
    required this.column,
    required this.message,
  });
}

/// Types of violations
enum ViolationType {
  threeConsecutive,
  countMismatch,
  duplicateRow,
  duplicateColumn,
}

