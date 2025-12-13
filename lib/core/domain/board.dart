import '../constants/game_constants.dart';

/// Board abstraction for puzzle grids
/// 
/// Provides a clean interface for working with puzzle grids,
/// including safe cloning, cell access, and row/column helpers.
class Board {
  final int size;
  final List<List<int>> grid;
  final List<List<bool>> givenLocks; // Track which cells are given (locked)
  
  Board({
    required this.size,
    required List<List<int>> grid,
    List<List<bool>>? givenLocks,
  }) : grid = grid,
       givenLocks = givenLocks ?? List.generate(
         grid.length,
         (i) => List.filled(grid[i].length, false),
       ) {
    // Validate grid dimensions
    if (grid.isEmpty || grid.length != size || grid[0].length != size) {
      throw ArgumentError('Grid must be square (NxN)');
    }
    if (givenLocks != null) {
      if (givenLocks.length != size || givenLocks[0].length != size) {
        throw ArgumentError('GivenLocks must match grid dimensions');
      }
    }
  }
  
  /// Create a board from a 2D list
  factory Board.fromGrid(List<List<int>> grid, {List<List<bool>>? givenLocks}) {
    final size = grid.length;
    return Board(
      size: size,
      grid: grid,
      givenLocks: givenLocks,
    );
  }
  
  /// Create an empty board
  factory Board.empty(int size) {
    return Board(
      size: size,
      grid: List.generate(size, (_) => List.filled(size, GameConstants.cellEmpty)),
    );
  }
  
  /// Get cell value at (row, col)
  int getCell(int row, int col) {
    _validateIndex(row, col);
    return grid[row][col];
  }
  
  /// Set cell value at (row, col)
  void setCell(int row, int col, int value) {
    _validateIndex(row, col);
    if (givenLocks[row][col]) {
      throw StateError('Cannot modify locked (given) cell at ($row, $col)');
    }
    grid[row][col] = value;
  }
  
  /// Check if cell is locked (given)
  bool isLocked(int row, int col) {
    _validateIndex(row, col);
    return givenLocks[row][col];
  }
  
  /// Lock a cell (mark as given)
  void lockCell(int row, int col) {
    _validateIndex(row, col);
    givenLocks[row][col] = true;
  }
  
  /// Unlock a cell
  void unlockCell(int row, int col) {
    _validateIndex(row, col);
    givenLocks[row][col] = false;
  }
  
  /// Get a row as a list
  List<int> row(int rowIndex) {
    _validateIndex(rowIndex, 0);
    return List<int>.from(grid[rowIndex]);
  }
  
  /// Get a column as a list
  List<int> col(int colIndex) {
    _validateIndex(0, colIndex);
    return List.generate(size, (row) => grid[row][colIndex]);
  }
  
  /// Check if board is complete (no empty cells)
  bool isComplete() {
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        if (grid[row][col] == GameConstants.cellEmpty) {
          return false;
        }
      }
    }
    return true;
  }
  
  /// Count empty cells
  int countEmpty() {
    int count = 0;
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        if (grid[row][col] == GameConstants.cellEmpty) {
          count++;
        }
      }
    }
    return count;
  }
  
  /// Count filled cells
  int countFilled() {
    return (size * size) - countEmpty();
  }
  
  /// Create a deep copy of this board
  Board clone() {
    final clonedGrid = grid.map((row) => List<int>.from(row)).toList();
    final clonedLocks = givenLocks.map((row) => List<bool>.from(row)).toList();
    return Board(
      size: size,
      grid: clonedGrid,
      givenLocks: clonedLocks,
    );
  }
  
  /// Convert to 2D list (for compatibility with existing code)
  List<List<int>> toGrid() {
    return grid.map((row) => List<int>.from(row)).toList();
  }
  
  /// Convert to 2D list of given locks
  List<List<bool>> toGivenLocks() {
    return givenLocks.map((row) => List<bool>.from(row)).toList();
  }
  
  /// Check if two boards are equal (same grid values)
  bool equals(Board other) {
    if (size != other.size) return false;
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < size; col++) {
        if (grid[row][col] != other.grid[row][col]) {
          return false;
        }
      }
    }
    return true;
  }
  
  /// Get string representation for debugging
  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Board($size x $size):');
    for (int row = 0; row < size; row++) {
      buffer.write('  ');
      for (int col = 0; col < size; col++) {
        final value = grid[row][col];
        final symbol = value == GameConstants.cellSun 
            ? 'S' 
            : value == GameConstants.cellMoon 
                ? 'M' 
                : '.';
        final locked = givenLocks[row][col] ? '!' : ' ';
        buffer.write('$symbol$locked ');
      }
      buffer.writeln();
    }
    return buffer.toString();
  }
  
  void _validateIndex(int row, int col) {
    if (row < 0 || row >= size || col < 0 || col >= size) {
      throw RangeError('Index ($row, $col) out of bounds for board size $size');
    }
  }
}

