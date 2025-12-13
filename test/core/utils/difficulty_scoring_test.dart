import 'package:flutter_test/flutter_test.dart';
import 'package:sun_moon_puzzle/core/utils/human_logic_solver.dart';

void main() {
  group('DifficultyMetrics - Score Calculation', () {
    test('computes score for easy puzzle (high forced moves)', () {
      final metrics = DifficultyMetrics()
        ..forcedMovesCount = 10
        ..totalAssignments = 12
        ..branchingEventsCount = 0
        ..backtracksCount = 0
        ..maxBranchDepth = 0
        ..firstBranchStepIndex = -1;
      
      final score = metrics.computeDifficultyScore(4);
      
      // High forced move ratio should result in lower score
      expect(score, lessThan(5.0));
      expect(score, greaterThanOrEqualTo(0.0));
      expect(score, lessThanOrEqualTo(10.0));
    });
    
    test('computes score for hard puzzle (high branching)', () {
      final metrics = DifficultyMetrics()
        ..forcedMovesCount = 2
        ..totalAssignments = 16
        ..branchingEventsCount = 5
        ..backtracksCount = 3
        ..maxBranchDepth = 4
        ..firstBranchStepIndex = 2;
      
      final score = metrics.computeDifficultyScore(4);
      
      // High branching should result in higher score
      expect(score, greaterThan(5.0));
      expect(score, lessThanOrEqualTo(10.0));
    });
    
    test('normalizes score to 0-10 range', () {
      final metrics = DifficultyMetrics()
        ..forcedMovesCount = 5
        ..totalAssignments = 10
        ..branchingEventsCount = 10
        ..backtracksCount = 5
        ..maxBranchDepth = 5
        ..firstBranchStepIndex = 1;
      
      final score = metrics.computeDifficultyScore(4);
      
      expect(score, greaterThanOrEqualTo(0.0));
      expect(score, lessThanOrEqualTo(10.0));
    });
    
    test('penalizes very high forced move ratio (>90%)', () {
      final metrics = DifficultyMetrics()
        ..forcedMovesCount = 15
        ..totalAssignments = 16
        ..branchingEventsCount = 0
        ..backtracksCount = 0
        ..maxBranchDepth = 0
        ..firstBranchStepIndex = -1;
      
      final score = metrics.computeDifficultyScore(4);
      
      // Should be heavily penalized (score * 0.3)
      expect(score, lessThan(3.0));
    });
    
    test('rewards early branching (low firstBranchStepIndex)', () {
      final metrics1 = DifficultyMetrics()
        ..forcedMovesCount = 2
        ..totalAssignments = 16
        ..branchingEventsCount = 3
        ..backtracksCount = 1
        ..maxBranchDepth = 2
        ..firstBranchStepIndex = 2; // Early branching
      
      final metrics2 = DifficultyMetrics()
        ..forcedMovesCount = 10
        ..totalAssignments = 16
        ..branchingEventsCount = 3
        ..backtracksCount = 1
        ..maxBranchDepth = 2
        ..firstBranchStepIndex = 12; // Late branching
      
      final score1 = metrics1.computeDifficultyScore(4);
      final score2 = metrics2.computeDifficultyScore(4);
      
      // Early branching should result in higher score
      expect(score1, greaterThan(score2));
    });
    
    test('handles different grid sizes (4x4, 6x6, 8x8)', () {
      final metrics = DifficultyMetrics()
        ..forcedMovesCount = 5
        ..totalAssignments = 10
        ..branchingEventsCount = 3
        ..backtracksCount = 1
        ..maxBranchDepth = 2
        ..firstBranchStepIndex = 5;
      
      final score4 = metrics.computeDifficultyScore(4);
      final score6 = metrics.computeDifficultyScore(6);
      final score8 = metrics.computeDifficultyScore(8);
      
      // All should be in valid range
      expect(score4, greaterThanOrEqualTo(0.0));
      expect(score4, lessThanOrEqualTo(10.0));
      expect(score6, greaterThanOrEqualTo(0.0));
      expect(score6, lessThanOrEqualTo(10.0));
      expect(score8, greaterThanOrEqualTo(0.0));
      expect(score8, lessThanOrEqualTo(10.0));
    });
    
    test('handles zero assignments gracefully', () {
      final metrics = DifficultyMetrics()
        ..forcedMovesCount = 0
        ..totalAssignments = 0
        ..branchingEventsCount = 0
        ..backtracksCount = 0
        ..maxBranchDepth = 0
        ..firstBranchStepIndex = -1;
      
      final score = metrics.computeDifficultyScore(4);
      
      expect(score, equals(0.0));
    });
  });
  
  group('DifficultyMetrics - Forced Move Ratio', () {
    test('calculates ratio correctly', () {
      final metrics = DifficultyMetrics()
        ..forcedMovesCount = 5
        ..totalAssignments = 10;
      
      expect(metrics.forcedMoveRatio, equals(0.5));
    });
    
    test('handles zero total assignments', () {
      final metrics = DifficultyMetrics()
        ..forcedMovesCount = 0
        ..totalAssignments = 0;
      
      expect(metrics.forcedMoveRatio, equals(0.0));
    });
  });
}

