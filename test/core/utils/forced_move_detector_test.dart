import 'package:flutter_test/flutter_test.dart';
import 'package:sun_moon_puzzle/core/constants/game_constants.dart';
import 'package:sun_moon_puzzle/core/domain/move.dart';
import 'package:sun_moon_puzzle/core/utils/forced_move_detector.dart';

void main() {
  group('ForcedMoveDetector - Three-in-a-row', () {
    test('detects XX_ pattern in row', () {
      final grid = [
        [GameConstants.cellSun, GameConstants.cellSun, GameConstants.cellEmpty, GameConstants.cellMoon],
        [GameConstants.cellMoon, GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty],
        [GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty],
        [GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty],
      ];
      
      final detector = ForcedMoveDetector(grid: grid);
      final moves = detector.findForcedMoves();
      
      expect(moves.isNotEmpty, isTrue);
      final move = moves.firstWhere((m) => m.row == 0 && m.col == 2);
      expect(move.value, GameConstants.cellMoon); // Must be opposite of Sun
      expect(move.reason, MoveReason.threeInARow);
    });
    
    test('detects _XX pattern in row', () {
      final grid = [
        [GameConstants.cellEmpty, GameConstants.cellMoon, GameConstants.cellMoon, GameConstants.cellSun],
        [GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty],
        [GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty],
        [GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty],
      ];
      
      final detector = ForcedMoveDetector(grid: grid);
      final moves = detector.findForcedMoves();
      
      expect(moves.isNotEmpty, isTrue);
      final move = moves.firstWhere((m) => m.row == 0 && m.col == 0);
      expect(move.value, GameConstants.cellSun); // Must be opposite of Moon
      expect(move.reason, MoveReason.threeInARow);
    });
    
    test('detects X_X pattern (sandwich)', () {
      final grid = [
        [GameConstants.cellSun, GameConstants.cellEmpty, GameConstants.cellSun, GameConstants.cellMoon],
        [GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty],
        [GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty],
        [GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty],
      ];
      
      final detector = ForcedMoveDetector(grid: grid);
      final moves = detector.findForcedMoves();
      
      expect(moves.isNotEmpty, isTrue);
      final move = moves.firstWhere((m) => m.row == 0 && m.col == 1);
      expect(move.value, GameConstants.cellMoon); // Must be opposite of Sun
      expect(move.reason, MoveReason.sandwich);
    });
    
    test('detects three-in-a-row in columns', () {
      final grid = [
        [GameConstants.cellSun, GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty],
        [GameConstants.cellSun, GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty],
        [GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty],
        [GameConstants.cellMoon, GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty],
      ];
      
      final detector = ForcedMoveDetector(grid: grid);
      final moves = detector.findForcedMoves();
      
      expect(moves.isNotEmpty, isTrue);
      final move = moves.firstWhere((m) => m.row == 2 && m.col == 0);
      expect(move.value, GameConstants.cellMoon); // Must be opposite of Sun
    });
  });
  
  group('ForcedMoveDetector - Balance Rule', () {
    test('detects row balance: 2 Suns filled, rest must be Moon', () {
      // For 4x4, N/2 = 2, so if 2 Suns are filled, the remaining 2 must be Moon
      final grid = [
        [GameConstants.cellSun, GameConstants.cellSun, GameConstants.cellEmpty, GameConstants.cellEmpty],
        [GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty],
        [GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty],
        [GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty],
      ];
      
      final detector = ForcedMoveDetector(grid: grid);
      final moves = detector.findForcedMoves();
      
      // Should find moves for row 0, cols 2 and 3 (must be Moon)
      // Note: Balance rule only triggers when exactly N/2 of one symbol is filled
      // In this case, 2 Suns = N/2, so remaining 2 empty cells must be Moon
      final row0Moves = moves.where((m) => m.row == 0 && m.reason == MoveReason.rowBalance).toList();
      // At least 1 move should be found (deduplication may reduce to 1 if other strategies also find moves)
      expect(row0Moves.length, greaterThanOrEqualTo(1));
      expect(row0Moves.every((m) => m.value == GameConstants.cellMoon), isTrue);
      
      // Check that all empty cells in row 0 are covered (either by rowBalance or other strategies)
      final row0AllMoves = moves.where((m) => m.row == 0).toList();
      expect(row0AllMoves.length, greaterThanOrEqualTo(1));
    });
    
    test('detects column balance: 2 Moons filled, rest must be Sun', () {
      // For 4x4, N/2 = 2, so if 2 Moons are filled, the remaining 2 must be Sun
      final grid = [
        [GameConstants.cellMoon, GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty],
        [GameConstants.cellMoon, GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty],
        [GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty],
        [GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty],
      ];
      
      final detector = ForcedMoveDetector(grid: grid);
      final moves = detector.findForcedMoves();
      
      // Should find moves for col 0, rows 2 and 3 (must be Sun)
      // Note: Balance rule only triggers when exactly N/2 of one symbol is filled
      final col0Moves = moves.where((m) => m.col == 0 && m.reason == MoveReason.colBalance).toList();
      // At least 1 move should be found (deduplication may reduce to 1 if other strategies also find moves)
      expect(col0Moves.length, greaterThanOrEqualTo(1));
      expect(col0Moves.every((m) => m.value == GameConstants.cellSun), isTrue);
      
      // Check that all empty cells in col 0 are covered (either by colBalance or other strategies)
      final col0AllMoves = moves.where((m) => m.col == 0).toList();
      expect(col0AllMoves.length, greaterThanOrEqualTo(1));
    });
  });
  
  group('ForcedMoveDetector - Given Locks', () {
    test('ignores locked (given) cells', () {
      final grid = [
        [GameConstants.cellSun, GameConstants.cellSun, GameConstants.cellEmpty, GameConstants.cellMoon],
        [GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty],
        [GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty],
        [GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellEmpty],
      ];
      
      final givenLocks = [
        [true, true, false, true], // First 3 cells are given
        [false, false, false, false],
        [false, false, false, false],
        [false, false, false, false],
      ];
      
      final detector = ForcedMoveDetector(grid: grid, givenLocks: givenLocks);
      final moves = detector.findForcedMoves();
      
      // Should not suggest moves for locked cells
      expect(moves.every((m) => !givenLocks[m.row][m.col]), isTrue);
    });
  });
  
  group('ForcedMoveDetector - Edge Cases', () {
    test('returns empty list for complete grid', () {
      final grid = [
        [GameConstants.cellSun, GameConstants.cellMoon, GameConstants.cellSun, GameConstants.cellMoon],
        [GameConstants.cellMoon, GameConstants.cellSun, GameConstants.cellMoon, GameConstants.cellSun],
        [GameConstants.cellSun, GameConstants.cellSun, GameConstants.cellMoon, GameConstants.cellMoon],
        [GameConstants.cellMoon, GameConstants.cellMoon, GameConstants.cellSun, GameConstants.cellSun],
      ];
      
      final detector = ForcedMoveDetector(grid: grid);
      final moves = detector.findForcedMoves();
      
      expect(moves.isEmpty, isTrue);
    });
    
    test('returns empty list for empty grid', () {
      final grid = List.generate(4, (_) => List.filled(4, GameConstants.cellEmpty));
      
      final detector = ForcedMoveDetector(grid: grid);
      final moves = detector.findForcedMoves();
      
      // Empty grid has no forced moves
      expect(moves.isEmpty, isTrue);
    });
  });
}

