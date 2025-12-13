import 'dart:math';
import 'package:flutter/foundation.dart';
import '../constants/game_constants.dart';
import 'grid_validator.dart';
import 'grid_helper.dart';
import 'puzzle_solver.dart';

/// Puzzle Generator - Two-phase system: Generation (Backtracking) + Masking (Difficulty)
/// Production-grade implementation for "Soluna" logic puzzle game
class PuzzleGenerator {
  final Random _random;
  int _maxRecursiveDepth = 0;
  static const int _maxDepthForWeb = 150000;

  PuzzleGenerator({int? seed}) : _random = Random(seed ?? DateTime.now().millisecondsSinceEpoch);

  /// PHASE A: Generate a complete valid board using recursive backtracking
  /// Returns a fully filled, valid grid that satisfies all Takuzu/Binairo rules
  List<List<int>> generateCompleteBoard(int size) {
    if (size % 2 != 0) {
      throw ArgumentError('Grid size must be even');
    }

    // Support ONLY 4x4, 6x6, 8x8 grids
    if (size != 4 && size != 6 && size != 8) {
      throw ArgumentError('Grid size must be 4, 6, or 8 only');
    }

    final List<List<int>> grid = List.generate(
      size,
      (_) => List.filled(size, GameConstants.cellEmpty),
    );

    _maxRecursiveDepth = 0;
    final int maxAttempts = kIsWeb ? 25 : 15;
    int attempts = 0;

    while (attempts < maxAttempts) {
      // Reset grid
      if (attempts > 0) {
        for (int i = 0; i < size; i++) {
          for (int j = 0; j < size; j++) {
            grid[i][j] = GameConstants.cellEmpty;
          }
        }
      }
      
      _maxRecursiveDepth = 0;
      final solved = _solveGridBacktracking(grid, 0, 0, size);
      
      if (solved) {
        // CRITICAL: Strictly validate before returning
        if (_hasNoThreeConsecutive(grid, size) && GridValidator.isValidGrid(grid)) {
          return grid;
        }
      }
      attempts++;
    }

    throw Exception('Failed to generate valid board after $maxAttempts attempts');
  }

  /// PHASE B: Create playable puzzle by REDUCTION (removing cells based on difficulty)
  /// CRITICAL: Uses "Logic Solver" to ensure NO-GUESS, UNIQUE SOLUTION puzzles
  /// 
  /// Algorithm:
  /// 1. Start with complete valid grid
  /// 2. Try removing each cell
  /// 3. After removal, run LogicSolver to check if puzzle is still solvable
  /// 4. If LogicSolver can solve it AND solution count is 1: Keep removal
  /// 5. If LogicSolver gets stuck OR multiple solutions: Restore cell
  /// 
  /// Difficulty Config (Keep Rate):
  /// - Levels 1-5 (Tutorial): Keep 60% filled (DifficultyFactor = 0.40 removal)
  /// - Levels 6-15 (Easy): Keep 45% filled (DifficultyFactor = 0.55 removal) - Level 13: ~7 cells
  /// - Levels 16-30 (Medium): Keep 35% filled (DifficultyFactor = 0.65 removal)
  /// - Levels 31+ (Hard): Keep 30% filled (DifficultyFactor = 0.70 removal)
  List<List<int>> createPlayablePuzzle(
    List<List<int>> completeBoard,
    double difficultyFactor,
  ) {
    final int size = completeBoard.length;
    final int totalCells = size * size;
    
    // CRITICAL: difficultyFactor is now the REMOVAL rate (not keep rate)
    // Calculate cells to keep: keepRate = 1.0 - difficultyFactor
    final double keepRate = 1.0 - difficultyFactor;
    final int cellsToKeep = (totalCells * keepRate).round();
    
    // Ensure minimum cells remain for solvability
    final int minCells = (size * 0.25).round(); // At least 25% must remain
    final int actualCellsToKeep = cellsToKeep.clamp(minCells, totalCells);
    final int targetCellsToRemove = totalCells - actualCellsToKeep;

    // Create a copy for the puzzle - start with complete board
    final List<List<int>> puzzle = completeBoard.map((row) => List<int>.from(row)).toList();

    // REDUCTION ALGORITHM: Try to remove cells one by one
    // Only remove if LogicSolver can solve it AND solution is unique
    final List<int> positions = List.generate(totalCells, (i) => i);
    positions.shuffle(_random);

    int removed = 0;
    int attempts = 0;
    final int maxAttempts = totalCells * 5; // More attempts for better reduction

    // Try to remove cells while maintaining solvability and uniqueness
    for (int pos in positions) {
      if (removed >= targetCellsToRemove) break;
      if (attempts >= maxAttempts) break; // Safety limit
      
      attempts++;
      final int row = pos ~/ size;
      final int col = pos % size;
      
      // Skip if already empty
      if (puzzle[row][col] == GameConstants.cellEmpty) continue;
      
      // Save the original value
      final int originalValue = puzzle[row][col];
      
      // Try removing this cell
      puzzle[row][col] = GameConstants.cellEmpty;
      
      // CRITICAL STEP 1: Check if LogicSolver can solve it (no-guess requirement)
      final canSolveLogically = PuzzleSolver.canSolveLogically(puzzle, size);
      
      // CRITICAL STEP 2: Check if solution is unique
      final solutionCount = PuzzleSolver.countSolutions(puzzle, size);
      
      if (canSolveLogically && solutionCount == 1) {
        // Puzzle is solvable by logic AND has unique solution - keep the removal
        removed++;
      } else {
        // Puzzle requires guessing OR has multiple solutions - restore the cell
        puzzle[row][col] = originalValue;
      }
    }

    // If we couldn't remove enough cells, try additional passes
    // but still maintain logic solvability and uniqueness
    if (removed < targetCellsToRemove && removed < totalCells - minCells) {
      final remainingPositions = List.generate(totalCells, (i) => i)
        ..shuffle(_random);
      
      for (int pos in remainingPositions) {
        if (removed >= targetCellsToRemove) break;
        if (attempts >= maxAttempts * 2) break;
        
        attempts++;
        final int row = pos ~/ size;
        final int col = pos % size;
        
        if (puzzle[row][col] == GameConstants.cellEmpty) continue;
        
        final int originalValue = puzzle[row][col];
        puzzle[row][col] = GameConstants.cellEmpty;
        
        final canSolveLogically = PuzzleSolver.canSolveLogically(puzzle, size);
        final solutionCount = PuzzleSolver.countSolutions(puzzle, size);
        
        if (canSolveLogically && solutionCount == 1) {
          removed++;
        } else {
          puzzle[row][col] = originalValue;
        }
      }
    }
    
    return puzzle;
  }

  /// Generate puzzle for a specific level with difficulty factor
  /// This is the main entry point for level-based generation
  List<List<int>> generatePuzzleForLevel(int size, double difficultyFactor, {int? seed}) {
    final generator = seed != null ? PuzzleGenerator(seed: seed) : this;
    
    // Phase A: Generate complete valid board
    final completeBoard = generator.generateCompleteBoard(size);
    
    // Phase B: Create playable puzzle by masking
    return generator.createPlayablePuzzle(completeBoard, difficultyFactor);
  }

  /// Recursive backtracking solver
  /// Fills the grid cell by cell, validating constraints at each step
  bool _solveGridBacktracking(List<List<int>> grid, int row, int col, int size) {
    // Limit recursion depth for web
    if (kIsWeb) {
      _maxRecursiveDepth++;
      final maxDepth = size <= 6 ? _maxDepthForWeb : (_maxDepthForWeb ~/ 2);
      if (_maxRecursiveDepth > maxDepth) {
        return false;
      }
    }
    
    // Base case: if we've filled all cells, check if grid is valid
    if (row == size) {
      return GridValidator.isValidGrid(grid) && _hasNoThreeConsecutive(grid, size);
    }

    // Calculate next position
    int nextRow = col == size - 1 ? row + 1 : row;
    int nextCol = col == size - 1 ? 0 : col + 1;

    // Try placing Sun and Moon in random order
    final List<int> values = [GameConstants.cellSun, GameConstants.cellMoon];
    values.shuffle(_random);

    for (int value in values) {
      grid[row][col] = value;

      // Check if current placement is valid so far
      if (_isValidPlacement(grid, row, col, size)) {
        if (_solveGridBacktracking(grid, nextRow, nextCol, size)) {
          return true;
        }
      }

      // Backtrack
      grid[row][col] = GameConstants.cellEmpty;
    }

    return false;
  }

  /// Validates if placing a value at (row, col) satisfies all constraints
  bool _isValidPlacement(List<List<int>> grid, int row, int col, int size) {
    final int value = grid[row][col];
    final int expectedCount = size ~/ 2;

    // Constraint 1: No more than 2 identical symbols adjacent (horizontally)
    if (col >= 2) {
      if (grid[row][col - 1] == value && grid[row][col - 2] == value) {
        return false;
      }
    }

    // Constraint 1: No more than 2 identical symbols adjacent (vertically)
    if (row >= 2) {
      if (grid[row - 1][col] == value && grid[row - 2][col] == value) {
        return false;
      }
    }

    // Constraint 2: Row count (can't exceed expected count)
    int rowSunCount = 0;
    int rowMoonCount = 0;
    int rowEmptyCount = 0;

    for (int c = 0; c < size; c++) {
      if (grid[row][c] == GameConstants.cellSun) {
        rowSunCount++;
      } else if (grid[row][c] == GameConstants.cellMoon) {
        rowMoonCount++;
      } else {
        rowEmptyCount++;
      }
    }

    if (value == GameConstants.cellSun && rowSunCount > expectedCount) {
      return false;
    }
    if (value == GameConstants.cellMoon && rowMoonCount > expectedCount) {
      return false;
    }

    // If row is complete, check counts match exactly
    if (rowEmptyCount == 0) {
      if (rowSunCount != expectedCount || rowMoonCount != expectedCount) {
        return false;
      }
    }

    // Constraint 2: Column count (can't exceed expected count)
    int colSunCount = 0;
    int colMoonCount = 0;
    int colEmptyCount = 0;

    for (int r = 0; r < size; r++) {
      if (grid[r][col] == GameConstants.cellSun) {
        colSunCount++;
      } else if (grid[r][col] == GameConstants.cellMoon) {
        colMoonCount++;
      } else {
        colEmptyCount++;
      }
    }

    if (value == GameConstants.cellSun && colSunCount > expectedCount) {
      return false;
    }
    if (value == GameConstants.cellMoon && colMoonCount > expectedCount) {
      return false;
    }

    // If column is complete, check counts match exactly
    if (colEmptyCount == 0) {
      if (colSunCount != expectedCount || colMoonCount != expectedCount) {
        return false;
      }
    }

    // Constraint 3: No duplicate rows (only if both rows are complete)
    for (int r = 0; r < row; r++) {
      bool rowComplete = true;
      bool otherRowComplete = true;

      for (int c = 0; c < size; c++) {
        if (grid[row][c] == GameConstants.cellEmpty) rowComplete = false;
        if (grid[r][c] == GameConstants.cellEmpty) otherRowComplete = false;
      }

      if (rowComplete && otherRowComplete) {
        bool areEqual = true;
        for (int c = 0; c < size; c++) {
          if (grid[row][c] != grid[r][c]) {
            areEqual = false;
            break;
          }
        }
        if (areEqual) {
          return false;
        }
      }
    }

    // Constraint 3: No duplicate columns (only if both columns are complete)
    for (int c = 0; c < col; c++) {
      bool colComplete = true;
      bool otherColComplete = true;

      for (int r = 0; r < size; r++) {
        if (grid[r][col] == GameConstants.cellEmpty) colComplete = false;
        if (grid[r][c] == GameConstants.cellEmpty) otherColComplete = false;
      }

      if (colComplete && otherColComplete) {
        bool areEqual = true;
        for (int r = 0; r < size; r++) {
          if (grid[r][col] != grid[r][c]) {
            areEqual = false;
            break;
          }
        }
        if (areEqual) {
          return false;
        }
      }
    }

    return true;
  }

  /// CRITICAL: Check that grid has NO three consecutive symbols
  bool _hasNoThreeConsecutive(List<List<int>> grid, int size) {
    // Check all rows
    for (int row = 0; row < size; row++) {
      for (int col = 2; col < size; col++) {
        final val = grid[row][col];
        if (val != GameConstants.cellEmpty &&
            grid[row][col - 1] == val &&
            grid[row][col - 2] == val) {
          return false;
        }
      }
    }

    // Check all columns
    for (int col = 0; col < size; col++) {
      for (int row = 2; row < size; row++) {
        final val = grid[row][col];
        if (val != GameConstants.cellEmpty &&
            grid[row - 1][col] == val &&
            grid[row - 2][col] == val) {
          return false;
        }
      }
    }

    return true;
  }

  // Legacy methods for backward compatibility
  @Deprecated('Use generateCompleteBoard instead')
  List<List<int>> generatePuzzle(int size) {
    return generateCompleteBoard(size);
  }

  @Deprecated('Use generatePuzzleForLevel instead')
  List<List<int>> generateDailyChallenge(int size) {
    final DateTime now = DateTime.now();
    final int seed = now.year * 10000 + now.month * 100 + now.day;
    final generator = PuzzleGenerator(seed: seed);
    return generator.generatePuzzleForLevel(size, 0.55);
  }
}
