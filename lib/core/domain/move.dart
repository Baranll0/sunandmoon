import '../constants/game_constants.dart';

/// Reason for a forced move
enum MoveReason {
  /// Three-in-a-row rule: XX_ or _XX or X_X
  threeInARow,
  
  /// Row balance: N/2 of one symbol filled, rest must be opposite
  rowBalance,
  
  /// Column balance: N/2 of one symbol filled, rest must be opposite
  colBalance,
  
  /// Row uniqueness: completing this row would make it identical to another
  uniqueRow,
  
  /// Column uniqueness: completing this column would make it identical to another
  uniqueCol,
  
  /// Sandwich pattern: X_X requires opposite in middle
  sandwich,
}

/// A forced move with its logical reason
class Move {
  final int row;
  final int col;
  final int value; // GameConstants.cellSun or cellMoon
  final MoveReason reason;
  
  const Move({
    required this.row,
    required this.col,
    required this.value,
    required this.reason,
  });
  
  /// Human-readable explanation of why this move is forced
  String getExplanation(int gridSize) {
    switch (reason) {
      case MoveReason.threeInARow:
        return 'Placing ${_valueName(value)} here would create three in a row.';
      case MoveReason.rowBalance:
        final targetCount = gridSize ~/ 2;
        return 'Row ${row + 1} has $targetCount ${_valueName(_getOpposite(value))}s. The remaining empty cells must be ${_valueName(value)}.';
      case MoveReason.colBalance:
        final targetCount = gridSize ~/ 2;
        return 'Column ${col + 1} has $targetCount ${_valueName(_getOpposite(value))}s. The remaining empty cells must be ${_valueName(value)}.';
      case MoveReason.uniqueRow:
        return 'Completing row ${row + 1} with ${_valueName(_getOpposite(value))} would make it identical to another row.';
      case MoveReason.uniqueCol:
        return 'Completing column ${col + 1} with ${_valueName(_getOpposite(value))} would make it identical to another column.';
      case MoveReason.sandwich:
        return 'This cell is sandwiched between two ${_valueName(_getOpposite(value))}s, so it must be ${_valueName(value)}.';
    }
  }
  
  String _valueName(int value) {
    return value == GameConstants.cellSun ? 'Sun' : 'Moon';
  }
  
  int _getOpposite(int value) {
    return value == GameConstants.cellSun 
        ? GameConstants.cellMoon 
        : GameConstants.cellSun;
  }
  
  @override
  String toString() => 'Move($row, $col, ${_valueName(value)}, $reason)';
}

