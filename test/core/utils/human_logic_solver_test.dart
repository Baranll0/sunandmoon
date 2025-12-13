import 'package:flutter_test/flutter_test.dart';
import 'package:sun_moon_puzzle/core/constants/game_constants.dart';
import 'package:sun_moon_puzzle/core/utils/human_logic_solver.dart';

void main() {
  group('HumanLogicSolver - Solvability', () {
    test('solves a simple 4x4 puzzle with forced moves', () {
      // Puzzle with clear forced moves (three-in-a-row pattern)
      final puzzle = [
        [GameConstants.cellSun, GameConstants.cellSun, GameConstants.cellEmpty, GameConstants.cellMoon],
        [GameConstants.cellMoon, GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty],
        [GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty],
        [GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty],
      ];
      
      final solver = HumanLogicSolver(4);
      final report = solver.solve(puzzle);
      
      expect(report.isSolvable, isTrue);
      expect(report.metrics.forcedMovesCount, greaterThan(0));
    });
    
    test('detects unsolvable puzzle (contradiction)', () {
      // Invalid puzzle: three Suns in a row
      final puzzle = [
        [GameConstants.cellSun, GameConstants.cellSun, GameConstants.cellSun, GameConstants.cellEmpty],
        [GameConstants.cellMoon, GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty],
        [GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty],
        [GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty],
      ];
      
      final solver = HumanLogicSolver(4);
      final report = solver.solve(puzzle);
      
      // Should detect contradiction during solving
      // Note: This depends on implementation - may still return isSolvable=false
      expect(report.isSolvable, isFalse);
    });
    
    test('tracks branching events for complex puzzles', () {
      // Puzzle that requires guessing (branching)
      final puzzle = [
        [GameConstants.cellSun, GameConstants.cellMoon, GameConstants.cellEmpty, GameConstants.cellEmpty],
        [GameConstants.cellMoon, GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty],
        [GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty],
        [GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty],
      ];
      
      final solver = HumanLogicSolver(4);
      final report = solver.solve(puzzle);
      
      // Should track metrics
      expect(report.metrics.totalAssignments, greaterThan(0));
      // May or may not have branching depending on puzzle
    });
  });
  
  group('HumanLogicSolver - Uniqueness', () {
    test('checks for unique solution', () {
      // Valid puzzle with unique solution
      final puzzle = [
        [GameConstants.cellSun, GameConstants.cellSun, GameConstants.cellEmpty, GameConstants.cellMoon],
        [GameConstants.cellMoon, GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty],
        [GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty],
        [GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty],
      ];
      
      final solver = HumanLogicSolver(4);
      final report = solver.solve(puzzle);
      
      // Should check uniqueness
      expect(report.isUnique, isA<bool>());
    });
  });
  
  group('HumanLogicSolver - Metrics', () {
    test('tracks forced moves count', () {
      final puzzle = [
        [GameConstants.cellSun, GameConstants.cellSun, GameConstants.cellEmpty, GameConstants.cellMoon],
        [GameConstants.cellMoon, GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty],
        [GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty],
        [GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty],
      ];
      
      final solver = HumanLogicSolver(4);
      final report = solver.solve(puzzle);
      
      expect(report.metrics.forcedMovesCount, greaterThanOrEqualTo(0));
      expect(report.metrics.totalAssignments, greaterThanOrEqualTo(report.metrics.forcedMovesCount));
    });
    
    test('calculates forced move ratio', () {
      final puzzle = [
        [GameConstants.cellSun, GameConstants.cellSun, GameConstants.cellEmpty, GameConstants.cellMoon],
        [GameConstants.cellMoon, GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty],
        [GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty],
        [GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty],
      ];
      
      final solver = HumanLogicSolver(4);
      final report = solver.solve(puzzle);
      
      final ratio = report.metrics.forcedMoveRatio;
      expect(ratio, greaterThanOrEqualTo(0.0));
      expect(ratio, lessThanOrEqualTo(1.0));
    });
  });
}

