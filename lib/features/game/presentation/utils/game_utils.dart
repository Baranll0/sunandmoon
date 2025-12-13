import '../../domain/models/cell_model.dart';
import '../../domain/models/puzzle_model.dart';
import '../../../../core/utils/grid_validator.dart';
import '../../../../core/utils/grid_helper.dart' show GridHelper;

/// Utility functions for game operations
class GameUtils {
  /// Converts CellModel grid to int grid for validation
  static List<List<int>> cellGridToIntGrid(List<List<CellModel>> cellGrid) {
    return cellGrid.map((row) {
      return row.map((cell) => cell.value).toList();
    }).toList();
  }

  /// Converts int grid to CellModel grid
  static List<List<CellModel>> intGridToCellGrid(
    List<List<int>> intGrid,
    List<List<CellModel>>? originalCellGrid,
  ) {
    return intGrid.asMap().entries.map((rowEntry) {
      final int rowIndex = rowEntry.key;
      return rowEntry.value.asMap().entries.map((colEntry) {
        final int colIndex = colEntry.key;
        final int value = colEntry.value;
        
        // Preserve original cell properties if available
        if (originalCellGrid != null &&
            rowIndex < originalCellGrid.length &&
            colIndex < originalCellGrid[rowIndex].length) {
          final CellModel originalCell = originalCellGrid[rowIndex][colIndex];
          return originalCell.copyWith(
            value: value,
            hasError: false,
            isHighlighted: false,
          );
        }
        
        return CellModel(
          value: value,
          isGiven: value != 0,
        );
      }).toList();
    }).toList();
  }

  /// Checks if the puzzle is completed and correct
  /// CRITICAL: Uses RULE-BASED validation, NOT solution comparison
  /// A puzzle is complete if:
  /// 1. All cells are filled
  /// 2. The grid follows all Takuzu/Binairo rules (validated by GridValidator)
  static bool isPuzzleCompleted(PuzzleModel puzzle) {
    final List<List<int>> currentGrid = cellGridToIntGrid(puzzle.currentState);
    
    // Check if all cells are filled
    if (!GridHelper.isComplete(currentGrid)) {
      return false;
    }
    
    // CRITICAL: Validate using RULES, not solution comparison
    // If the grid is complete and valid according to rules, it's solved
    return GridValidator.isValidGrid(currentGrid);
  }

  /// Validates the current puzzle state and updates error flags
  /// Marks entire rows/columns when violations are found
  static List<List<CellModel>> validateAndMarkErrors(
    List<List<CellModel>> currentState,
  ) {
    final List<List<int>> intGrid = cellGridToIntGrid(currentState);
    final List<GridViolation> violations = GridValidator.validatePartialGrid(intGrid);
    
    // Track which rows and columns have errors
    final Set<int> errorRows = {};
    final Set<int> errorColumns = {};
    final Set<String> errorCells = {}; // For specific cell errors
    
    for (final violation in violations) {
      if (violation.type == ViolationType.threeConsecutive) {
        // For three consecutive violations, mark the entire row or column
        if (violation.row >= 0 && violation.column >= 0) {
          // Check if it's a row violation (same row, different columns)
          // or column violation (same column, different rows)
          // We'll mark both the row and column to be safe
          errorRows.add(violation.row);
          errorColumns.add(violation.column);
        }
      } else if (violation.row >= 0 && violation.column < 0) {
        // Row violation - mark entire row
        errorRows.add(violation.row);
      } else if (violation.column >= 0 && violation.row < 0) {
        // Column violation - mark entire column
        errorColumns.add(violation.column);
      } else if (violation.row >= 0 && violation.column >= 0) {
        // Specific cell error - mark the cell
        errorCells.add('${violation.row}-${violation.column}');
      }
    }
    
    // Mark all cells in error rows and columns
    final Set<String> errorPositions = {};
    
    // Add all cells in error rows
    for (final row in errorRows) {
      for (int col = 0; col < currentState[row].length; col++) {
        errorPositions.add('$row-$col');
      }
    }
    
    // Add all cells in error columns
    for (final col in errorColumns) {
      for (int row = 0; row < currentState.length; row++) {
        errorPositions.add('$row-$col');
      }
    }
    
    // Add specific cell errors
    errorPositions.addAll(errorCells);
    
    // Update cells with error flags
    return currentState.asMap().entries.map((rowEntry) {
      final int rowIndex = rowEntry.key;
      return rowEntry.value.asMap().entries.map((colEntry) {
        final int colIndex = colEntry.key;
        final CellModel cell = colEntry.value;
        final String position = '$rowIndex-$colIndex';
        
        return cell.copyWith(
          hasError: errorPositions.contains(position),
        );
      }).toList();
    }).toList();
  }

  /// Gets hint violations for highlighting
  static List<GridViolation> getHintViolations(List<List<CellModel>> currentState) {
    final List<List<int>> intGrid = cellGridToIntGrid(currentState);
    return GridValidator.validatePartialGrid(intGrid);
  }

  /// Deep copies a CellModel grid
  static List<List<CellModel>> copyCellGrid(List<List<CellModel>> grid) {
    return grid.map((row) {
      return row.map((cell) => cell).toList();
    }).toList();
  }
}

