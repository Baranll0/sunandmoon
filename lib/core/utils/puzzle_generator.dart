import 'dart:math';
import '../constants/game_constants.dart';
import 'grid_validator.dart';
import 'grid_helper.dart';
import 'puzzle_solver.dart';
import 'region_layout_helper.dart';

/// Puzzle Generator - Two-phase system: Generation (Backtracking) + Masking (Difficulty)
/// Production-grade implementation for "Soluna" logic puzzle game
class PuzzleGenerator {
  final Random _random;
  final bool useRegions;
  int _maxRecursiveDepth = 0;
  static const int _maxDepthForWeb = 150000;
  // Constant for pure Dart context
  static const bool _isWeb = false; 

  PuzzleGenerator({int? seed, this.useRegions = false}) : _random = Random((seed ?? DateTime.now().millisecondsSinceEpoch) + 55555);

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
    final int maxAttempts = _isWeb ? 25 : 15;
    int attempts = 0;

    while (attempts < maxAttempts) {
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
    // CRITICAL: For 4x4 grids, we can be more aggressive (minimum 4 cells = 25%)
    // For larger grids, keep at least 20% for better difficulty
    final int minCells = size == 4 
        ? 4  // 4x4: Minimum 4 cells (25%) - allows up to 75% removal
        : (size * size * 0.20).round(); // 6x6, 8x8: Minimum 20%
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
    // CRITICAL: Increase attempts for better reduction, especially for smaller grids
    // 4x4 grids need more attempts to reach target difficulty
    final int maxAttempts = size == 4 
        ? totalCells * 10  // 4x4: More attempts (160 attempts)
        : totalCells * 5;  // 6x6, 8x8: Standard attempts

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
      // CRITICAL: Try multiple additional passes with different shuffles
      for (int pass = 0; pass < 3; pass++) {
        if (removed >= targetCellsToRemove) break;
        if (attempts >= maxAttempts * 3) break; // Increased limit
        
        final remainingPositions = List.generate(totalCells, (i) => i)
          ..shuffle(_random);
        
        for (int pos in remainingPositions) {
          if (removed >= targetCellsToRemove) break;
          if (attempts >= maxAttempts * 3) break;
          
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
    }
    
    // FINAL PASS: Strictly enforce Master Spec Anti-Determinism Rule
    // Condition: Every row and column must have at least 2 empty cells.
    // If not met, force remove more cells until satisfied.
    if (!checkMinEmptyPerLine(puzzle, size, 2)) {
      final candidates = <int>[];
      
      // Identify rows/cols violating the min-2-empty rule
      for (int r = 0; r < size; r++) {
        if (_countEmptyInRow(puzzle, r, size) < 2) {
           for (int c = 0; c < size; c++) candidates.add(r * size + c);
        }
      }
      for (int c = 0; c < size; c++) {
        if (_countEmptyInCol(puzzle, c, size) < 2) {
           for (int r = 0; r < size; r++) candidates.add(r * size + c);
        }
      }
      
      candidates.shuffle(_random);
      
      for (int pos in candidates) {
        if (removed >= totalCells - minCells) break; // Cannot remove more
        
        final int r = pos ~/ size;
        final int c = pos % size;
        
        if (puzzle[r][c] == GameConstants.cellEmpty) continue;
        
        final int original = puzzle[r][c];
        puzzle[r][c] = GameConstants.cellEmpty;
        
        final canSolveLogically = PuzzleSolver.canSolveLogically(puzzle, size);
        final solutionCount = PuzzleSolver.countSolutions(puzzle, size);
        
        if (canSolveLogically && solutionCount == 1) {
          removed++;
          // If satisfied, stop
          if (checkMinEmptyPerLine(puzzle, size, 2)) break;
        } else {
          puzzle[r][c] = original; // Restore
        }
      }
    }
    
    // CRITICAL: Log warning if we couldn't reach target difficulty
    if (removed < targetCellsToRemove * 0.8) {
      print('[PuzzleGenerator] WARNING: Could only remove $removed/$targetCellsToRemove cells '
          '(${((removed / totalCells) * 100).toStringAsFixed(1)}% removal, '
          'target: ${(difficultyFactor * 100).toStringAsFixed(1)}%)');
    }
    
    return puzzle;
  }

  /// Check if the puzzle has any fully filled row or column
  bool _hasFullLine(List<List<int>> puzzle, int size) {
    // Check rows
    for (int r = 0; r < size; r++) {
      if (_countEmptyInRow(puzzle, r, size) == 0) return true;
    }
    // Check cols
    for (int c = 0; c < size; c++) {
      if (_countEmptyInCol(puzzle, c, size) == 0) return true;
    }
    return false;
  }

  /// CRITICAL HARD GATE: Check if every row and column has at least [minEmpty] empty cells
  /// Prevents "3 filled + 1 empty" patterns that are instantly forced
  bool checkMinEmptyPerLine(List<List<int>> puzzle, int size, int minEmpty) {
    // Check rows
    for (int r = 0; r < size; r++) {
      if (_countEmptyInRow(puzzle, r, size) < minEmpty) return false;
    }
    // Check cols
    for (int c = 0; c < size; c++) {
      if (_countEmptyInCol(puzzle, c, size) < minEmpty) return false;
    }
    return true;
  }

  /// CRITICAL GATE FOR CHAPTER 1 (4x4):
  /// Prevent "3 givens in a row/col" even if they are not consecutive
  /// This ensures 4x4 puzzles aren't trivally solvable by just filling the last gap immediately
  /// Returns true if valid (not too trivial), false if too trivial
  bool checkChapter1AntiTrivial(List<List<int>> puzzle, int size) {
    if (size != 4) return true; // Only applies to 4x4
    
    // For 4x4, we want at least 2 empty cells per line (which is covered by _checkMinEmptyPerLine)
    // BUT we also want to avoid cases where givens are placed such that they practically solve the line
    // actually _checkMinEmptyPerLine(minEmpty=2) effectively enforces "max 2 givens per line" for 4x4
    // since 4 - 2 = 2. So strict enforcement of minEmpty=2 is sufficient for 4x4.
    
    return checkMinEmptyPerLine(puzzle, size, 2);
  }

  int _countEmptyInRow(List<List<int>> puzzle, int row, int size) {
    int count = 0;
    for (int c = 0; c < size; c++) {
      if (puzzle[row][c] == GameConstants.cellEmpty) count++;
    }
    return count;
  }

  int _countEmptyInCol(List<List<int>> puzzle, int col, int size) {
    int count = 0;
    for (int r = 0; r < size; r++) {
      if (puzzle[r][col] == GameConstants.cellEmpty) count++;
    }
    return count;
  }

  /// Generate puzzle for a specific level with difficulty factor
  /// This is the main entry point for level-based generation
  Future<List<List<int>>> generatePuzzleForLevel(int size, double difficultyFactor, {int? seed}) async {
    final generator = seed != null ? PuzzleGenerator(seed: seed) : this;
    
    // RETRY LOOP to enforce Master Spec Gates
    // Gate 1: MinEmptyPerLine = 2 (Anti-Determinism)
    // Gate 2: Logic Solvable (No Guessing)
    int attempts = 0;
    const int maxAttempts = 20; // Allow 20 attempts to generate a perfect puzzle
    
    while (attempts < maxAttempts) {
      attempts++;
      try {
        // Phase A: Generate complete valid board
        final completeBoard = generator.generateCompleteBoard(size);
        
        // Phase B: Create playable puzzle by masking
        final puzzle = generator.createPlayablePuzzle(completeBoard, difficultyFactor);
        
        // Check Gate 1: MinEmptyPerLine = 2
        // CRITICAL: Strict enforcement
        if (!generator.checkMinEmptyPerLine(puzzle, size, 2)) {
          if (attempts < maxAttempts) continue; // Retry
          print('[PuzzleGenerator] Warning: Could not satisfy MinEmptyPerLine=2 after $attempts attempts');
        }
        
        // Check Solvability (Redundant as createPlayablePuzzle maintains it, but good for sanity)
        if (!PuzzleSolver.canSolveLogically(puzzle, size)) {
           continue; // Should not happen if createPlayablePuzzle is correct
        }
        
        return puzzle;
      } catch (e) {
        print('[PuzzleGenerator] Generation attempt $attempts failed: $e');
        if (attempts >= maxAttempts) rethrow;
      }
    }
    
    // Fallback (should be unreachable given enough attempts)
    throw Exception('Failed to generate valid puzzle satisfying all gates');
  }

  /// Recursive backtracking solver
  /// Fills the grid cell by cell, validating constraints at each step
  bool _solveGridBacktracking(List<List<int>> grid, int row, int col, int size) {
    // Limit recursion depth for web
    if (_isWeb) {
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
    
    // Constraint 4: Regions (if enabled)
    if (useRegions) {
      if (!_checkRegionConstraint(grid, row, col, size, value)) {
        return false;
      }
    }

    return true;
  }
  
  /// Check if placing value validates region constraints
  /// Rule: Each region must contain equal number of Suns and Moons
  bool _checkRegionConstraint(List<List<int>> grid, int row, int col, int size, int value) {
    // Get region ID
    final regionId = RegionLayoutHelper.getRegionId(row, col, size);
    if (regionId == null) return true;
    
    int sunCount = 0;
    int moonCount = 0;
    int regionSize = 0;
    int emptyCount = 0;
    
    // Scan full grid to find cells in this region
    // Optimized: We only need to check cells up to current (row, col) technically,
    // but counting all helps tracking full region completion.
    // However, during backtracking grid is only partially filled.
    for (int r = 0; r < size; r++) {
       for (int c = 0; c < size; c++) {
          if (RegionLayoutHelper.getRegionId(r, c, size) == regionId) {
             regionSize++;
             if (r == row && c == col) {
               // Current cell being placed
               if (value == GameConstants.cellSun) sunCount++;
               else moonCount++;
             } else {
               // Existing cell
               if (grid[r][c] == GameConstants.cellSun) sunCount++;
               else if (grid[r][c] == GameConstants.cellMoon) moonCount++;
               else emptyCount++;
             }
          }
       }
    }
    
    final int maxPerType = regionSize ~/ 2;
    
    // Check if we exceeded limits
    if (sunCount > maxPerType) return false;
    if (moonCount > maxPerType) return false;
    
    // If region is full (no empty slots left to fill), check if balanced
    // Note: 'emptyCount' includes future cells. During backtracking we only care if we broke the limit.
    // If we haven't broken the limit, it's valid so far.
    // The backtracking will eventually fill the region and if it can't balance it, it will backtrack.
    // So simple limit check is sufficient.
    
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


}
