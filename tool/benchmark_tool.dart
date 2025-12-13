import 'dart:io';
import 'package:sun_moon_puzzle/core/utils/level_generator.dart';
import 'package:sun_moon_puzzle/core/utils/human_logic_solver.dart';
import 'package:sun_moon_puzzle/core/constants/game_constants.dart';

/// Performance benchmark tool
/// Measures generation time, uniqueness check time, and solver performance
void main() {
  print('=== Tango Logic - Performance Benchmarks ===\n');
  
  final generator = LevelGenerator();
  
  // Benchmark uniqueness check
  _benchmarkUniquenessCheck();
  
  // Benchmark generation
  _benchmarkGeneration(generator);
  
  // Benchmark solver performance
  _benchmarkSolver();
}

void _benchmarkUniquenessCheck() {
  print('--- Uniqueness Check Benchmarks ---');
  
  for (final size in [4, 6, 8]) {
    print('\nGrid Size: ${size}x$size');
    
    // Create a test puzzle (minimal givens)
    final puzzle = List.generate(size, (_) => List.filled(size, GameConstants.cellEmpty));
    // Add a few givens
    puzzle[0][0] = GameConstants.cellSun;
    puzzle[0][1] = GameConstants.cellSun;
    puzzle[1][0] = GameConstants.cellMoon;
    
    final solver = HumanLogicSolver(size);
    
    final stopwatch = Stopwatch()..start();
    final report = solver.solve(puzzle);
    stopwatch.stop();
    
    print('  Uniqueness check: ${stopwatch.elapsedMilliseconds}ms');
    print('  Is Unique: ${report.isUnique}');
    print('  Is Solvable: ${report.isSolvable}');
    
    // Check if within budget (maxSolverNodes)
    const int maxSolverNodes = 100000; // Budget
    final estimatedNodes = report.metrics.totalAssignments * 
                          (report.metrics.branchingEventsCount + 1);
    print('  Estimated Nodes: $estimatedNodes (Budget: $maxSolverNodes)');
    
    if (estimatedNodes > maxSolverNodes) {
      print('  ⚠️  WARNING: Exceeds node budget!');
    }
  }
}

void _benchmarkGeneration(LevelGenerator generator) {
  print('\n--- Generation Benchmarks ---');
  
  for (final size in [4, 6, 8]) {
    print('\nGrid Size: ${size}x$size');
    
    final times = <int>[];
    int successCount = 0;
    const int maxAttempts = 10;
    const int maxGenerationAttempts = 50; // Per level
    
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final stopwatch = Stopwatch()..start();
      
      try {
        // Generate a level (chapter 2 for consistency)
        final level = generator.generateLevel(2, 1);
        
        stopwatch.stop();
        times.add(stopwatch.elapsedMilliseconds);
        successCount++;
        
        if (stopwatch.elapsedMilliseconds > 5000) {
          print('  ⚠️  WARNING: Generation took ${stopwatch.elapsedMilliseconds}ms (>5s)');
        }
      } catch (e) {
        stopwatch.stop();
        print('  Error: $e');
      }
    }
    
    if (times.isNotEmpty) {
      final avgTime = times.reduce((a, b) => a + b) / times.length;
      final minTime = times.reduce((a, b) => a < b ? a : b);
      final maxTime = times.reduce((a, b) => a > b ? a : b);
      
      print('  Success Rate: ${successCount}/$maxAttempts');
      print('  Avg Time: ${avgTime.toStringAsFixed(2)}ms');
      print('  Min Time: ${minTime}ms');
      print('  Max Time: ${maxTime}ms');
      
      // Check if within budget
      const int maxGenerationTime = 3000; // 3 seconds
      if (avgTime > maxGenerationTime) {
        print('  ⚠️  WARNING: Average time exceeds budget ($maxGenerationTime ms)!');
      }
    }
  }
}

void _benchmarkSolver() {
  print('\n--- Solver Performance Benchmarks ---');
  
  for (final size in [4, 6, 8]) {
    print('\nGrid Size: ${size}x$size');
    
    // Create test puzzles with varying difficulty
    final testCases = [
      ('Easy (high forced)', _createEasyPuzzle(size)),
      ('Medium (moderate branching)', _createMediumPuzzle(size)),
      ('Hard (high branching)', _createHardPuzzle(size)),
    ];
    
    for (final testCase in testCases) {
      final name = testCase.$1;
      final puzzle = testCase.$2;
      
      final solver = HumanLogicSolver(size);
      final stopwatch = Stopwatch()..start();
      final report = solver.solve(puzzle);
      stopwatch.stop();
      
      print('  $name:');
      print('    Time: ${stopwatch.elapsedMilliseconds}ms');
      print('    Solvable: ${report.isSolvable}');
      print('    Unique: ${report.isUnique}');
      print('    Score: ${report.difficultyScore.toStringAsFixed(2)}');
      print('    Assignments: ${report.metrics.totalAssignments}');
      print('    Branching: ${report.metrics.branchingEventsCount}');
    }
  }
}

List<List<int>> _createEasyPuzzle(int size) {
  final puzzle = List.generate(size, (_) => List.filled(size, GameConstants.cellEmpty));
  // Add many givens (high forced moves)
  puzzle[0][0] = GameConstants.cellSun;
  puzzle[0][1] = GameConstants.cellSun;
  puzzle[1][0] = GameConstants.cellMoon;
  if (size >= 6) {
    puzzle[2][2] = GameConstants.cellSun;
    puzzle[2][3] = GameConstants.cellSun;
  }
  return puzzle;
}

List<List<int>> _createMediumPuzzle(int size) {
  final puzzle = List.generate(size, (_) => List.filled(size, GameConstants.cellEmpty));
  // Moderate givens
  puzzle[0][0] = GameConstants.cellSun;
  puzzle[0][1] = GameConstants.cellMoon;
  puzzle[1][0] = GameConstants.cellMoon;
  return puzzle;
}

List<List<int>> _createHardPuzzle(int size) {
  final puzzle = List.generate(size, (_) => List.filled(size, GameConstants.cellEmpty));
  // Minimal givens (forces branching)
  puzzle[0][0] = GameConstants.cellSun;
  puzzle[0][1] = GameConstants.cellMoon;
  return puzzle;
}

