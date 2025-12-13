import '../constants/game_constants.dart';
import '../domain/move.dart';

/// Detects forced moves in a partial puzzle grid
/// 
/// A forced move is a cell placement that can be logically deduced
/// from the current state without guessing.
class ForcedMoveDetector {
  final List<List<int>> grid;
  final int size;
  final List<List<bool>>? givenLocks; // Optional: track which cells are given (locked)
  
  ForcedMoveDetector({
    required this.grid,
    this.givenLocks,
  }) : size = grid.length {
    if (grid.isEmpty || grid.length != grid[0].length) {
      throw ArgumentError('Grid must be square (NxN)');
    }
  }
  
  /// Find all forced moves in the current grid state
  /// Returns empty list if no forced moves are found
  List<Move> findForcedMoves() {
    final List<Move> moves = [];
    
    // Strategy 1: Three-in-a-row rule
    moves.addAll(_findThreeInARowMoves());
    
    // Strategy 2: Balance rule (N/2 filled)
    moves.addAll(_findBalanceMoves());
    
    // Strategy 3: Uniqueness rule (avoid duplicate rows/cols)
    moves.addAll(_findUniquenessMoves());
    
    // Remove duplicates (same row, col)
    return _deduplicateMoves(moves);
  }
  
  /// Find the first forced move (for hints)
  Move? findFirstForcedMove() {
    final moves = findForcedMoves();
    return moves.isNotEmpty ? moves.first : null;
  }
  
  /// Check if a cell is locked (given)
  bool _isLocked(int row, int col) {
    if (givenLocks == null) return false;
    if (row < 0 || row >= size || col < 0 || col >= size) return false;
    return givenLocks![row][col];
  }
  
  /// Strategy 1: Three-in-a-row patterns
  List<Move> _findThreeInARowMoves() {
    final List<Move> moves = [];
    
    // Check rows
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size - 2; col++) {
        final val1 = grid[row][col];
        final val2 = grid[row][col + 1];
        final val3 = grid[row][col + 2];
        
        // Pattern: XX_ -> _ must be opposite
        if (val1 != GameConstants.cellEmpty &&
            val1 == val2 &&
            val3 == GameConstants.cellEmpty &&
            !_isLocked(row, col + 2)) {
          moves.add(Move(
            row: row,
            col: col + 2,
            value: _getOpposite(val1),
            reason: MoveReason.threeInARow,
          ));
        }
        
        // Pattern: _XX -> _ must be opposite
        if (val1 == GameConstants.cellEmpty &&
            val2 != GameConstants.cellEmpty &&
            val2 == val3 &&
            !_isLocked(row, col)) {
          moves.add(Move(
            row: row,
            col: col,
            value: _getOpposite(val2),
            reason: MoveReason.threeInARow,
          ));
        }
        
        // Pattern: X_X -> middle must be opposite
        if (val1 != GameConstants.cellEmpty &&
            val1 == val3 &&
            val2 == GameConstants.cellEmpty &&
            !_isLocked(row, col + 1)) {
          moves.add(Move(
            row: row,
            col: col + 1,
            value: _getOpposite(val1),
            reason: MoveReason.sandwich,
          ));
        }
      }
    }
    
    // Check columns
    for (int col = 0; col < size; col++) {
      for (int row = 0; row < size - 2; row++) {
        final val1 = grid[row][col];
        final val2 = grid[row + 1][col];
        final val3 = grid[row + 2][col];
        
        // Pattern: XX_ -> _ must be opposite
        if (val1 != GameConstants.cellEmpty &&
            val1 == val2 &&
            val3 == GameConstants.cellEmpty &&
            !_isLocked(row + 2, col)) {
          moves.add(Move(
            row: row + 2,
            col: col,
            value: _getOpposite(val1),
            reason: MoveReason.threeInARow,
          ));
        }
        
        // Pattern: _XX -> _ must be opposite
        if (val1 == GameConstants.cellEmpty &&
            val2 != GameConstants.cellEmpty &&
            val2 == val3 &&
            !_isLocked(row, col)) {
          moves.add(Move(
            row: row,
            col: col,
            value: _getOpposite(val2),
            reason: MoveReason.threeInARow,
          ));
        }
        
        // Pattern: X_X -> middle must be opposite
        if (val1 != GameConstants.cellEmpty &&
            val1 == val3 &&
            val2 == GameConstants.cellEmpty &&
            !_isLocked(row + 1, col)) {
          moves.add(Move(
            row: row + 1,
            col: col,
            value: _getOpposite(val1),
            reason: MoveReason.sandwich,
          ));
        }
      }
    }
    
    return moves;
  }
  
  /// Strategy 2: Balance rule (N/2 filled -> fill rest)
  List<Move> _findBalanceMoves() {
    final List<Move> moves = [];
    final int targetCount = size ~/ 2;
    
    // Check rows
    for (int row = 0; row < size; row++) {
      int sunCount = 0;
      int moonCount = 0;
      final List<int> emptyCols = [];
      
      for (int col = 0; col < size; col++) {
        if (grid[row][col] == GameConstants.cellSun) {
          sunCount++;
        } else if (grid[row][col] == GameConstants.cellMoon) {
          moonCount++;
        } else if (!_isLocked(row, col)) {
          emptyCols.add(col);
        }
      }
      
      // If exactly N/2 of one symbol, fill all empty cells with opposite
      if (sunCount == targetCount && emptyCols.isNotEmpty) {
        for (final col in emptyCols) {
          moves.add(Move(
            row: row,
            col: col,
            value: GameConstants.cellMoon,
            reason: MoveReason.rowBalance,
          ));
        }
      } else if (moonCount == targetCount && emptyCols.isNotEmpty) {
        for (final col in emptyCols) {
          moves.add(Move(
            row: row,
            col: col,
            value: GameConstants.cellSun,
            reason: MoveReason.rowBalance,
          ));
        }
      }
    }
    
    // Check columns
    for (int col = 0; col < size; col++) {
      int sunCount = 0;
      int moonCount = 0;
      final List<int> emptyRows = [];
      
      for (int row = 0; row < size; row++) {
        if (grid[row][col] == GameConstants.cellSun) {
          sunCount++;
        } else if (grid[row][col] == GameConstants.cellMoon) {
          moonCount++;
        } else if (!_isLocked(row, col)) {
          emptyRows.add(row);
        }
      }
      
      // If exactly N/2 of one symbol, fill all empty cells with opposite
      if (sunCount == targetCount && emptyRows.isNotEmpty) {
        for (final row in emptyRows) {
          moves.add(Move(
            row: row,
            col: col,
            value: GameConstants.cellMoon,
            reason: MoveReason.colBalance,
          ));
        }
      } else if (moonCount == targetCount && emptyRows.isNotEmpty) {
        for (final row in emptyRows) {
          moves.add(Move(
            row: row,
            col: col,
            value: GameConstants.cellSun,
            reason: MoveReason.colBalance,
          ));
        }
      }
    }
    
    return moves;
  }
  
  /// Strategy 3: Uniqueness rule (avoid duplicate rows/cols)
  List<Move> _findUniquenessMoves() {
    final List<Move> moves = [];
    
    // Check rows (simplified: only if row is almost complete)
    for (int row = 0; row < size; row++) {
      int filledCount = 0;
      final List<int> emptyCols = [];
      
      for (int col = 0; col < size; col++) {
        if (grid[row][col] != GameConstants.cellEmpty) {
          filledCount++;
        } else if (!_isLocked(row, col)) {
          emptyCols.add(col);
        }
      }
      
      // Only check if row is almost complete (1-2 empty)
      if (filledCount >= size - 2 && emptyCols.length <= 2) {
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
          
          // Check if completing current row would make it identical
          bool wouldBeIdentical = true;
          for (int col = 0; col < size; col++) {
            if (emptyCols.contains(col)) continue; // Skip empty cells
            if (grid[row][col] != grid[otherRow][col]) {
              wouldBeIdentical = false;
              break;
            }
          }
          
          if (wouldBeIdentical && emptyCols.length == 1) {
            // Must place opposite value to avoid duplicate
            final col = emptyCols.first;
            final oppositeValue = _getOpposite(grid[otherRow][col]);
            moves.add(Move(
              row: row,
              col: col,
              value: oppositeValue,
              reason: MoveReason.uniqueRow,
            ));
          }
        }
      }
    }
    
    // Check columns (similar logic)
    for (int col = 0; col < size; col++) {
      int filledCount = 0;
      final List<int> emptyRows = [];
      
      for (int row = 0; row < size; row++) {
        if (grid[row][col] != GameConstants.cellEmpty) {
          filledCount++;
        } else if (!_isLocked(row, col)) {
          emptyRows.add(row);
        }
      }
      
      // Only check if column is almost complete (1-2 empty)
      if (filledCount >= size - 2 && emptyRows.length <= 2) {
        // Check against other completed columns
        for (int otherCol = 0; otherCol < size; otherCol++) {
          if (otherCol == col) continue;
          
          // Check if other column is complete
          bool otherComplete = true;
          for (int row = 0; row < size; row++) {
            if (grid[row][otherCol] == GameConstants.cellEmpty) {
              otherComplete = false;
              break;
            }
          }
          
          if (!otherComplete) continue;
          
          // Check if completing current column would make it identical
          bool wouldBeIdentical = true;
          for (int row = 0; row < size; row++) {
            if (emptyRows.contains(row)) continue; // Skip empty cells
            if (grid[row][col] != grid[row][otherCol]) {
              wouldBeIdentical = false;
              break;
            }
          }
          
          if (wouldBeIdentical && emptyRows.length == 1) {
            // Must place opposite value to avoid duplicate
            final row = emptyRows.first;
            final oppositeValue = _getOpposite(grid[row][otherCol]);
            moves.add(Move(
              row: row,
              col: col,
              value: oppositeValue,
              reason: MoveReason.uniqueCol,
            ));
          }
        }
      }
    }
    
    return moves;
  }
  
  /// Remove duplicate moves (same row, col)
  List<Move> _deduplicateMoves(List<Move> moves) {
    final Map<String, Move> uniqueMoves = {};
    
    for (final move in moves) {
      final key = '${move.row}_${move.col}';
      // Keep first occurrence (prioritize earlier strategies)
      if (!uniqueMoves.containsKey(key)) {
        uniqueMoves[key] = move;
      }
    }
    
    return uniqueMoves.values.toList();
  }
  
  int _getOpposite(int value) {
    return value == GameConstants.cellSun 
        ? GameConstants.cellMoon 
        : GameConstants.cellSun;
  }
}

