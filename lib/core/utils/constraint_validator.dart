import '../constants/game_constants.dart';

/// Constraint Validator - Validates constraint markers (x and =) between cells
/// This is for advanced levels with constraint markers
class ConstraintValidator {
  /// Map of constraints: key is "row1-col1-row2-col2", value is constraint type
  final Map<String, String> constraints;

  ConstraintValidator(this.constraints);

  /// Validates if a constraint is satisfied
  /// Returns true if constraint is satisfied or if constraint doesn't exist
  bool isValidConstraint(
    List<List<int>> grid,
    int row1,
    int col1,
    int row2,
    int col2,
  ) {
    final String key = _getConstraintKey(row1, col1, row2, col2);
    final String? constraint = constraints[key];

    if (constraint == null) {
      return true; // No constraint, always valid
    }

    final int value1 = grid[row1][col1];
    final int value2 = grid[row2][col2];

    // If either cell is empty, constraint is not yet applicable
    if (value1 == GameConstants.cellEmpty || value2 == GameConstants.cellEmpty) {
      return true;
    }

    if (constraint == GameConstants.constraintDifferent) {
      // Must be different
      return value1 != value2;
    } else if (constraint == GameConstants.constraintSame) {
      // Must be same
      return value1 == value2;
    }

    return true;
  }

  /// Gets constraint key for two adjacent cells
  String _getConstraintKey(int row1, int col1, int row2, int col2) {
    // Normalize: always use smaller coordinates first
    if (row1 < row2 || (row1 == row2 && col1 < col2)) {
      return '$row1-$col1-$row2-$col2';
    } else {
      return '$row2-$col2-$row1-$col1';
    }
  }

  /// Validates all constraints in the grid
  bool validateAllConstraints(List<List<int>> grid) {
    for (final entry in constraints.entries) {
      final List<int> coords = entry.key.split('-').map(int.parse).toList();
      if (coords.length != 4) continue;

      final int row1 = coords[0];
      final int col1 = coords[1];
      final int row2 = coords[2];
      final int col2 = coords[3];

      if (!isValidConstraint(grid, row1, col1, row2, col2)) {
        return false;
      }
    }

    return true;
  }
}

