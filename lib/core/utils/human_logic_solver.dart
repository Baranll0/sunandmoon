import '../constants/game_constants.dart';
import 'grid_validator.dart';
import 'grid_helper.dart';

/// Difficulty metrics collected during solving
class DifficultyMetrics {
  int forcedMovesCount = 0;
  int branchingEventsCount = 0;
  int maxBranchDepth = 0;
  int backtracksCount = 0;
  int totalAssignments = 0;
  int firstBranchStepIndex = -1; // -1 means no branching occurred

  double get forcedMoveRatio => totalAssignments > 0 
      ? forcedMovesCount / totalAssignments 
      : 0.0;

  /// Computes difficulty score (0.0 - 10.0)
  /// Higher score = Harder puzzle
  double computeDifficultyScore(int gridSize) {
    // Base score from branching complexity
    double score = 0.0;
    
    // Branching events are the primary difficulty indicator
    score += branchingEventsCount * 1.5;
    
    // Backtracks indicate wrong guesses (harder)
    score += backtracksCount * 0.5;
    
    // Deeper recursion = more complex logic
    score += maxBranchDepth * 0.2;
    
    // Early branching (firstBranchStepIndex low) = harder
    if (firstBranchStepIndex >= 0) {
      // Lower index = earlier branching = harder
      final earlyBranchPenalty = (totalAssignments - firstBranchStepIndex) / totalAssignments;
      score += earlyBranchPenalty * 2.0;
    }
    
    // Penalize high forcedMoveRatio (too easy)
    // If 90%+ is forced, reduce score significantly
    if (forcedMoveRatio > 0.9) {
      score *= 0.3; // Very easy puzzle
    } else if (forcedMoveRatio > 0.7) {
      score *= 0.6; // Easy puzzle
    } else if (forcedMoveRatio > 0.5) {
      score *= 0.8; // Medium puzzle
    }
    
    // Normalize based on grid size
    // 4x4: max expected score ~15, normalize to 10
    // 6x6: max expected score ~25, normalize to 10
    // 8x8: max expected score ~40, normalize to 10
    double normalizationFactor;
    switch (gridSize) {
      case 4:
        normalizationFactor = 10.0 / 15.0;
        break;
      case 6:
        normalizationFactor = 10.0 / 25.0;
        break;
      case 8:
        normalizationFactor = 10.0 / 40.0;
        break;
      default:
        normalizationFactor = 10.0 / 20.0;
    }
    
    score *= normalizationFactor;
    
    // Clamp to 0-10 range
    return score.clamp(0.0, 10.0);
  }
}

/// Result of solving a puzzle
class DifficultyReport {
  final bool isSolvable;
  final bool isUnique; // Exactly one solution
  final DifficultyMetrics metrics;
  final int gridSize;
  late final double difficultyScore;
  
  // NEW: Track indices for quality gates
  final List<int> forcedMoveIndices; // Assignment indices where forced moves occurred
  final List<int> branchingIndices; // Assignment indices where branching occurred
  final List<int> branchDepths; // Depth at each branching point

  DifficultyReport({
    required this.isSolvable,
    required this.isUnique,
    required this.metrics,
    required this.gridSize,
    this.forcedMoveIndices = const [],
    this.branchingIndices = const [],
    this.branchDepths = const [],
  }) {
    difficultyScore = metrics.computeDifficultyScore(gridSize);
  }
}

/// Human-like solver that mimics human deduction
/// Used to measure puzzle difficulty based on logical branching
class HumanLogicSolver {
  final int gridSize;
  DifficultyMetrics? _metrics;
  List<List<int>>? _workingGrid;
  
  // Track indices for quality gates
  final List<int> _forcedMoveIndices = [];
  final List<int> _branchingIndices = [];
  final List<int> _branchDepths = [];

  HumanLogicSolver(this.gridSize);

  /// Solves the puzzle and returns difficulty metrics
  DifficultyReport solve(List<List<int>> puzzle) {
    _metrics = DifficultyMetrics();
    _workingGrid = puzzle.map((row) => List<int>.from(row)).toList();
    _forcedMoveIndices.clear();
    _branchingIndices.clear();
    _branchDepths.clear();

    // Phase 1: Deterministic Pass (Human Eye Logic)
    bool progress = true;
    while (progress) {
      progress = _applyDeterministicRules();
    }

    // Phase 2: Check if solved
    if (GridHelper.isComplete(_workingGrid!)) {
      if (GridValidator.isValidGrid(_workingGrid!)) {
        // Check uniqueness
        final isUnique = _checkUniqueness(puzzle);
        return DifficultyReport(
          isSolvable: true,
          isUnique: isUnique,
          metrics: _metrics!,
          gridSize: gridSize,
          forcedMoveIndices: List.from(_forcedMoveIndices),
          branchingIndices: List.from(_branchingIndices),
          branchDepths: List.from(_branchDepths),
        );
      }
    }

    // Phase 3: Nondeterministic Pass (Branching/Guessing)
    final solved = _solveWithBranching(_workingGrid!, 0);
    
    if (solved && GridHelper.isComplete(_workingGrid!)) {
      final isUnique = _checkUniqueness(puzzle);
      return DifficultyReport(
        isSolvable: true,
        isUnique: isUnique,
        metrics: _metrics!,
        gridSize: gridSize,
        forcedMoveIndices: List.from(_forcedMoveIndices),
        branchingIndices: List.from(_branchingIndices),
        branchDepths: List.from(_branchDepths),
      );
    }

    return DifficultyReport(
      isSolvable: false,
      isUnique: false,
      metrics: _metrics!,
      gridSize: gridSize,
      forcedMoveIndices: List.from(_forcedMoveIndices),
      branchingIndices: List.from(_branchingIndices),
      branchDepths: List.from(_branchDepths),
    );
  }

  /// Phase 1: Apply deterministic rules (human logic)
  /// Returns true if any progress was made
  bool _applyDeterministicRules() {
    bool progress = false;

    // Rule 1: Three-in-a-row (XX_ or _XX or X_X)
    if (_applyThreeInARowRule()) {
      progress = true;
      _metrics!.forcedMovesCount++;
      _metrics!.totalAssignments++;
      _forcedMoveIndices.add(_metrics!.totalAssignments - 1); // Track index
      return true;
    }

    // Rule 2: Balance (N/2 filled -> fill rest)
    if (_applyBalanceRule()) {
      progress = true;
      _metrics!.forcedMovesCount++;
      _metrics!.totalAssignments++;
      _forcedMoveIndices.add(_metrics!.totalAssignments - 1); // Track index
      return true;
    }

    // Rule 3: Uniqueness (avoid duplicate rows/cols)
    if (_applyUniquenessRule()) {
      progress = true;
      _metrics!.forcedMovesCount++;
      _metrics!.totalAssignments++;
      _forcedMoveIndices.add(_metrics!.totalAssignments - 1); // Track index
      return true;
    }

    return progress;
  }

  /// Rule 1: Three-in-a-row patterns
  bool _applyThreeInARowRule() {
    // Check rows
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize - 2; col++) {
        final val1 = _workingGrid![row][col];
        final val2 = _workingGrid![row][col + 1];
        final val3 = _workingGrid![row][col + 2];

        // Pattern: XX_ -> _ must be opposite
        if (val1 != GameConstants.cellEmpty &&
            val1 == val2 &&
            val3 == GameConstants.cellEmpty) {
          _workingGrid![row][col + 2] = _getOpposite(val1);
          return true;
        }

        // Pattern: _XX -> _ must be opposite
        if (val1 == GameConstants.cellEmpty &&
            val2 != GameConstants.cellEmpty &&
            val2 == val3) {
          _workingGrid![row][col] = _getOpposite(val2);
          return true;
        }

        // Pattern: X_X -> middle must be opposite
        if (val1 != GameConstants.cellEmpty &&
            val1 == val3 &&
            val2 == GameConstants.cellEmpty) {
          _workingGrid![row][col + 1] = _getOpposite(val1);
          return true;
        }
      }
    }

    // Check columns
    for (int col = 0; col < gridSize; col++) {
      for (int row = 0; row < gridSize - 2; row++) {
        final val1 = _workingGrid![row][col];
        final val2 = _workingGrid![row + 1][col];
        final val3 = _workingGrid![row + 2][col];

        // Pattern: XX_ -> _ must be opposite
        if (val1 != GameConstants.cellEmpty &&
            val1 == val2 &&
            val3 == GameConstants.cellEmpty) {
          _workingGrid![row + 2][col] = _getOpposite(val1);
          return true;
        }

        // Pattern: _XX -> _ must be opposite
        if (val1 == GameConstants.cellEmpty &&
            val2 != GameConstants.cellEmpty &&
            val2 == val3) {
          _workingGrid![row][col] = _getOpposite(val2);
          return true;
        }

        // Pattern: X_X -> middle must be opposite
        if (val1 != GameConstants.cellEmpty &&
            val1 == val3 &&
            val2 == GameConstants.cellEmpty) {
          _workingGrid![row + 1][col] = _getOpposite(val1);
          return true;
        }
      }
    }

    return false;
  }

  /// Rule 2: Balance rule (N/2 filled -> fill rest)
  bool _applyBalanceRule() {
    final int targetCount = gridSize ~/ 2;

    // Check rows
    for (int row = 0; row < gridSize; row++) {
      int sunCount = 0;
      int moonCount = 0;
      int emptyCount = 0;
      int? emptyCol;

      for (int col = 0; col < gridSize; col++) {
        if (_workingGrid![row][col] == GameConstants.cellSun) {
          sunCount++;
        } else if (_workingGrid![row][col] == GameConstants.cellMoon) {
          moonCount++;
        } else {
          emptyCount++;
          if (emptyCol == null) emptyCol = col;
        }
      }

      // If exactly N/2 of one symbol and only one empty, fill it
      if (emptyCount == 1 && emptyCol != null) {
        if (sunCount == targetCount) {
          _workingGrid![row][emptyCol] = GameConstants.cellMoon;
          return true;
        } else if (moonCount == targetCount) {
          _workingGrid![row][emptyCol] = GameConstants.cellSun;
          return true;
        }
      }
    }

    // Check columns
    for (int col = 0; col < gridSize; col++) {
      int sunCount = 0;
      int moonCount = 0;
      int emptyCount = 0;
      int? emptyRow;

      for (int row = 0; row < gridSize; row++) {
        if (_workingGrid![row][col] == GameConstants.cellSun) {
          sunCount++;
        } else if (_workingGrid![row][col] == GameConstants.cellMoon) {
          moonCount++;
        } else {
          emptyCount++;
          if (emptyRow == null) emptyRow = row;
        }
      }

      // If exactly N/2 of one symbol and only one empty, fill it
      if (emptyCount == 1 && emptyRow != null) {
        if (sunCount == targetCount) {
          _workingGrid![emptyRow][col] = GameConstants.cellMoon;
          return true;
        } else if (moonCount == targetCount) {
          _workingGrid![emptyRow][col] = GameConstants.cellSun;
          return true;
        }
      }
    }

    return false;
  }

  /// Rule 3: Uniqueness rule (avoid duplicate rows/cols)
  bool _applyUniquenessRule() {
    // Check rows
    for (int row = 0; row < gridSize; row++) {
      // Count filled cells
      int filledCount = 0;
      for (int col = 0; col < gridSize; col++) {
        if (_workingGrid![row][col] != GameConstants.cellEmpty) {
          filledCount++;
        }
      }

      // Only apply if row is almost complete (1-2 empty)
      if (filledCount >= gridSize - 2) {
        // Check against other completed rows
        for (int otherRow = 0; otherRow < gridSize; otherRow++) {
          if (otherRow == row) continue;

          // Check if other row is complete
          bool otherComplete = true;
          for (int col = 0; col < gridSize; col++) {
            if (_workingGrid![otherRow][col] == GameConstants.cellEmpty) {
              otherComplete = false;
              break;
            }
          }

          if (!otherComplete) continue;

          // Check if current row would be identical
          bool wouldBeIdentical = true;
          int? emptyCol;
          for (int col = 0; col < gridSize; col++) {
            if (_workingGrid![row][col] == GameConstants.cellEmpty) {
              if (emptyCol == null) {
                emptyCol = col;
              } else {
                wouldBeIdentical = false;
                break;
              }
            } else if (_workingGrid![row][col] != _workingGrid![otherRow][col]) {
              wouldBeIdentical = false;
              break;
            }
          }

          // If would be identical and we have exactly one empty, fill with opposite
          if (wouldBeIdentical && emptyCol != null) {
            final oppositeValue = _getOpposite(_workingGrid![otherRow][emptyCol]);
            _workingGrid![row][emptyCol] = oppositeValue;
            return true;
          }
        }
      }
    }

    // Similar logic for columns
    for (int col = 0; col < gridSize; col++) {
      int filledCount = 0;
      for (int row = 0; row < gridSize; row++) {
        if (_workingGrid![row][col] != GameConstants.cellEmpty) {
          filledCount++;
        }
      }

      if (filledCount >= gridSize - 2) {
        for (int otherCol = 0; otherCol < gridSize; otherCol++) {
          if (otherCol == col) continue;

          bool otherComplete = true;
          for (int row = 0; row < gridSize; row++) {
            if (_workingGrid![row][otherCol] == GameConstants.cellEmpty) {
              otherComplete = false;
              break;
            }
          }

          if (!otherComplete) continue;

          bool wouldBeIdentical = true;
          int? emptyRow;
          for (int row = 0; row < gridSize; row++) {
            if (_workingGrid![row][col] == GameConstants.cellEmpty) {
              if (emptyRow == null) {
                emptyRow = row;
              } else {
                wouldBeIdentical = false;
                break;
              }
            } else if (_workingGrid![row][col] != _workingGrid![row][otherCol]) {
              wouldBeIdentical = false;
              break;
            }
          }

          if (wouldBeIdentical && emptyRow != null) {
            final oppositeValue = _getOpposite(_workingGrid![emptyRow][otherCol]);
            _workingGrid![emptyRow][col] = oppositeValue;
            return true;
          }
        }
      }
    }

    return false;
  }

  /// Phase 2: Solve with branching (guessing)
  bool _solveWithBranching(List<List<int>> grid, int depth) {
    // Track first branch
    if (depth == 0 && _metrics!.firstBranchStepIndex == -1) {
      _metrics!.firstBranchStepIndex = _metrics!.totalAssignments;
      _branchingIndices.add(_metrics!.totalAssignments); // Track first branching index
      _branchDepths.add(depth);
    }

    // Update max depth
    if (depth > _metrics!.maxBranchDepth) {
      _metrics!.maxBranchDepth = depth;
    }

    // Find cell with minimum remaining values (MRV)
    int? bestRow, bestCol;
    int minOptions = 3; // Start with impossible value

    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        if (grid[row][col] != GameConstants.cellEmpty) continue;

        // Count valid options for this cell
        int options = 0;
        for (int value in [GameConstants.cellSun, GameConstants.cellMoon]) {
          if (_isValidPlacement(grid, row, col, value)) {
            options++;
          }
        }

        if (options > 0 && options < minOptions) {
          minOptions = options;
          bestRow = row;
          bestCol = col;
        }
      }
    }

    // If no empty cell found, check if solved
    if (bestRow == null || bestCol == null) {
      return GridHelper.isComplete(grid) && GridValidator.isValidGrid(grid);
    }

    // Try each possible value
    for (int value in [GameConstants.cellSun, GameConstants.cellMoon]) {
      if (!_isValidPlacement(grid, bestRow, bestCol, value)) continue;

      // Make assignment
      grid[bestRow][bestCol] = value;
      _metrics!.totalAssignments++;
      _metrics!.branchingEventsCount++;
      
      // Track branching (only at the point where we branch, not for each value tried)
      if (value == GameConstants.cellSun) { // Only track first branch attempt
        _branchingIndices.add(_metrics!.totalAssignments - 1);
        _branchDepths.add(depth);
      }

      // Recursively solve
      if (_solveWithBranching(grid, depth + 1)) {
        return true;
      }

      // Backtrack
      grid[bestRow][bestCol] = GameConstants.cellEmpty;
      _metrics!.backtracksCount++;
    }

    return false;
  }

  /// Check if puzzle has unique solution
  bool _checkUniqueness(List<List<int>> originalPuzzle) {
    int solutionCount = 0;
    final List<List<int>> testGrid = originalPuzzle.map((row) => List<int>.from(row)).toList();
    
    _countSolutionsRecursive(testGrid, 0, 0, () {
      solutionCount++;
      // Stop counting after 2 solutions (not unique)
      return solutionCount < 2;
    });
    
    return solutionCount == 1;
  }

  /// Count solutions recursively
  void _countSolutionsRecursive(
    List<List<int>> grid,
    int row,
    int col,
    bool Function() onSolution,
  ) {
    // Base case
    if (row == gridSize) {
      if (GridValidator.isValidGrid(grid)) {
        if (!onSolution()) {
          return;
        }
      }
      return;
    }

    // Next position
    int nextRow = col == gridSize - 1 ? row + 1 : row;
    int nextCol = col == gridSize - 1 ? 0 : col + 1;

    // Skip if already filled
    if (grid[row][col] != GameConstants.cellEmpty) {
      _countSolutionsRecursive(grid, nextRow, nextCol, onSolution);
      return;
    }

    // Try both values
    for (int value in [GameConstants.cellSun, GameConstants.cellMoon]) {
      if (_isValidPlacement(grid, row, col, value)) {
        grid[row][col] = value;
        _countSolutionsRecursive(grid, nextRow, nextCol, onSolution);
        grid[row][col] = GameConstants.cellEmpty;
      }
    }
  }

  /// Check if placing value at (row, col) is valid
  bool _isValidPlacement(List<List<int>> grid, int row, int col, int value) {
    final int expectedCount = gridSize ~/ 2;

    // Check adjacency (no 3 consecutive)
    if (col >= 2) {
      if (grid[row][col - 1] == value && grid[row][col - 2] == value) {
        return false;
      }
    }
    if (row >= 2) {
      if (grid[row - 1][col] == value && grid[row - 2][col] == value) {
        return false;
      }
    }

    // Check balance
    int rowSunCount = 0, rowMoonCount = 0;
    int colSunCount = 0, colMoonCount = 0;

    for (int c = 0; c < gridSize; c++) {
      if (grid[row][c] == GameConstants.cellSun) rowSunCount++;
      if (grid[row][c] == GameConstants.cellMoon) rowMoonCount++;
    }
    for (int r = 0; r < gridSize; r++) {
      if (grid[r][col] == GameConstants.cellSun) colSunCount++;
      if (grid[r][col] == GameConstants.cellMoon) colMoonCount++;
    }

    if (value == GameConstants.cellSun) {
      if (rowSunCount >= expectedCount || colSunCount >= expectedCount) return false;
    } else {
      if (rowMoonCount >= expectedCount || colMoonCount >= expectedCount) return false;
    }

    return true;
  }

  /// Get opposite value
  int _getOpposite(int value) {
    if (value == GameConstants.cellSun) return GameConstants.cellMoon;
    if (value == GameConstants.cellMoon) return GameConstants.cellSun;
    return GameConstants.cellEmpty;
  }
}

