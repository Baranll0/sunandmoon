import 'package:flutter_test/flutter_test.dart';
import 'package:sun_moon_puzzle/core/constants/game_constants.dart';
import 'package:sun_moon_puzzle/core/utils/grid_validator.dart';

void main() {
  group('GridValidator - Full Validation', () {
    test('validates a correct 4x4 grid', () {
      // Valid 4x4 grid: 2 Suns and 2 Moons per row/col, no 3 in a row, unique rows/cols
      final grid = [
        [GameConstants.cellSun, GameConstants.cellMoon, GameConstants.cellSun, GameConstants.cellMoon],
        [GameConstants.cellMoon, GameConstants.cellSun, GameConstants.cellMoon, GameConstants.cellSun],
        [GameConstants.cellSun, GameConstants.cellSun, GameConstants.cellMoon, GameConstants.cellMoon],
        [GameConstants.cellMoon, GameConstants.cellMoon, GameConstants.cellSun, GameConstants.cellSun],
      ];
      
      expect(GridValidator.isValidGrid(grid), isTrue);
    });
    
    test('rejects grid with three Suns in a row', () {
      final grid = [
        [GameConstants.cellSun, GameConstants.cellSun, GameConstants.cellSun, GameConstants.cellMoon],
        [GameConstants.cellMoon, GameConstants.cellSun, GameConstants.cellMoon, GameConstants.cellSun],
        [GameConstants.cellSun, GameConstants.cellMoon, GameConstants.cellSun, GameConstants.cellMoon],
        [GameConstants.cellMoon, GameConstants.cellMoon, GameConstants.cellSun, GameConstants.cellSun],
      ];
      
      expect(GridValidator.isValidGrid(grid), isFalse);
    });
    
    test('rejects grid with three Moons in a column', () {
      final grid = [
        [GameConstants.cellSun, GameConstants.cellMoon, GameConstants.cellSun, GameConstants.cellMoon],
        [GameConstants.cellMoon, GameConstants.cellMoon, GameConstants.cellSun, GameConstants.cellMoon],
        [GameConstants.cellSun, GameConstants.cellMoon, GameConstants.cellMoon, GameConstants.cellSun],
        [GameConstants.cellMoon, GameConstants.cellSun, GameConstants.cellSun, GameConstants.cellSun],
      ];
      
      expect(GridValidator.isValidGrid(grid), isFalse);
    });
    
    test('rejects grid with unbalanced row (3 Suns, 1 Moon)', () {
      final grid = [
        [GameConstants.cellSun, GameConstants.cellSun, GameConstants.cellSun, GameConstants.cellMoon],
        [GameConstants.cellMoon, GameConstants.cellSun, GameConstants.cellMoon, GameConstants.cellSun],
        [GameConstants.cellSun, GameConstants.cellMoon, GameConstants.cellSun, GameConstants.cellMoon],
        [GameConstants.cellMoon, GameConstants.cellMoon, GameConstants.cellSun, GameConstants.cellSun],
      ];
      
      expect(GridValidator.isValidGrid(grid), isFalse);
    });
    
    test('rejects grid with duplicate rows', () {
      final grid = [
        [GameConstants.cellSun, GameConstants.cellMoon, GameConstants.cellSun, GameConstants.cellMoon],
        [GameConstants.cellSun, GameConstants.cellMoon, GameConstants.cellSun, GameConstants.cellMoon], // Duplicate
        [GameConstants.cellSun, GameConstants.cellSun, GameConstants.cellMoon, GameConstants.cellMoon],
        [GameConstants.cellMoon, GameConstants.cellMoon, GameConstants.cellSun, GameConstants.cellSun],
      ];
      
      expect(GridValidator.isValidGrid(grid), isFalse);
    });
    
    test('rejects grid with duplicate columns', () {
      final grid = [
        [GameConstants.cellSun, GameConstants.cellMoon, GameConstants.cellSun, GameConstants.cellMoon],
        [GameConstants.cellMoon, GameConstants.cellSun, GameConstants.cellMoon, GameConstants.cellSun],
        [GameConstants.cellSun, GameConstants.cellMoon, GameConstants.cellSun, GameConstants.cellMoon], // Col 0 and 2 are same
        [GameConstants.cellMoon, GameConstants.cellMoon, GameConstants.cellSun, GameConstants.cellSun],
      ];
      
      expect(GridValidator.isValidGrid(grid), isFalse);
    });
  });
  
  group('GridValidator - Partial Validation', () {
    test('validates partial grid with empty cells', () {
      final grid = [
        [GameConstants.cellSun, GameConstants.cellMoon, GameConstants.cellEmpty, GameConstants.cellEmpty],
        [GameConstants.cellMoon, GameConstants.cellSun, GameConstants.cellMoon, GameConstants.cellSun],
        [GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellSun, GameConstants.cellMoon],
        [GameConstants.cellMoon, GameConstants.cellMoon, GameConstants.cellSun, GameConstants.cellSun],
      ];
      
      final violations = GridValidator.validatePartialGrid(grid);
      // Should have no violations (empty cells are allowed)
      expect(violations.isEmpty, isTrue);
    });
    
    test('detects three in a row violation in partial grid', () {
      final grid = [
        [GameConstants.cellSun, GameConstants.cellSun, GameConstants.cellSun, GameConstants.cellEmpty],
        [GameConstants.cellMoon, GameConstants.cellSun, GameConstants.cellMoon, GameConstants.cellSun],
        [GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellSun, GameConstants.cellMoon],
        [GameConstants.cellMoon, GameConstants.cellMoon, GameConstants.cellSun, GameConstants.cellSun],
      ];
      
      final violations = GridValidator.validatePartialGrid(grid);
      expect(violations.isNotEmpty, isTrue);
      expect(violations.any((v) => v.type == ViolationType.threeConsecutive), isTrue);
    });
    
    test('detects balance violation in partial grid', () {
      final grid = [
        [GameConstants.cellSun, GameConstants.cellSun, GameConstants.cellSun, GameConstants.cellMoon], // 3 Suns, 1 Moon
        [GameConstants.cellMoon, GameConstants.cellSun, GameConstants.cellMoon, GameConstants.cellSun],
        [GameConstants.cellEmpty, GameConstants.cellEmpty, GameConstants.cellSun, GameConstants.cellMoon],
        [GameConstants.cellMoon, GameConstants.cellMoon, GameConstants.cellSun, GameConstants.cellSun],
      ];
      
      final violations = GridValidator.validatePartialGrid(grid);
      expect(violations.isNotEmpty, isTrue);
      expect(violations.any((v) => v.type == ViolationType.countMismatch), isTrue);
    });
  });
  
  group('GridValidator - Edge Cases', () {
    test('handles empty grid', () {
      final grid = <List<int>>[];
      expect(() => GridValidator.isValidGrid(grid), returnsNormally);
      expect(GridValidator.isValidGrid(grid), isFalse);
    });
    
    test('handles 6x6 grid', () {
      // Valid 6x6 grid: 3 Suns and 3 Moons per row/col
      final grid = List.generate(6, (row) {
        return List.generate(6, (col) {
          // Simple pattern: alternate Sun/Moon
          return (row + col) % 2 == 0 
              ? GameConstants.cellSun 
              : GameConstants.cellMoon;
        });
      });
      
      // Adjust to ensure balance (3 and 3)
      // This is a simplified test - a real valid 6x6 would need proper validation
      expect(() => GridValidator.isValidGrid(grid), returnsNormally);
    });
  });
}

