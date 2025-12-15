/// Helper for region layouts in regions mechanic
/// Provides default region partitioning for different grid sizes
class RegionLayoutHelper {
  /// Get region ID for a cell at (row, col) in a grid of given size
  /// Returns region ID (0-based) or null if not in any region
  /// 
  /// Default layouts:
  /// - 4x4: 2x2 regions (4 regions total)
  /// - 6x6: 2x3 regions (6 regions total) or 3x2 regions
  /// - 8x8: 2x4 regions (8 regions total) or 4x2 regions
  static int? getRegionId(int row, int col, int gridSize) {
    if (gridSize == 4) {
      // 4x4: 2x2 regions (4 regions)
      final regionRow = row ~/ 2;
      final regionCol = col ~/ 2;
      return regionRow * 2 + regionCol;
    } else if (gridSize == 6) {
      // 6x6: 2x3 regions (6 regions)
      final regionRow = row ~/ 2;
      final regionCol = col ~/ 3;
      return regionRow * 3 + regionCol;
    } else if (gridSize == 8) {
      // 8x8: 2x4 regions (8 regions)
      final regionRow = row ~/ 2;
      final regionCol = col ~/ 4;
      return regionRow * 4 + regionCol;
    }
    return null;
  }
  
  /// Get all cells in a region
  static List<(int row, int col)> getCellsInRegion(int regionId, int gridSize) {
    final cells = <(int, int)>[];
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (getRegionId(r, c, gridSize) == regionId) {
          cells.add((r, c));
        }
      }
    }
    return cells;
  }
  
  /// Get region boundaries for drawing
  /// Returns list of (row, col) positions where region boundaries should be drawn
  static List<(int row, int col, bool isVertical)> getRegionBoundaries(int gridSize) {
    final boundaries = <(int, int, bool)>[];
    
    if (gridSize == 4) {
      // 2x2 regions: boundaries at row 2, col 2
      boundaries.add((2, 0, false)); // Horizontal line at row 2
      boundaries.add((0, 2, true)); // Vertical line at col 2
    } else if (gridSize == 6) {
      // 2x3 regions: boundaries at row 2, 4 and col 3
      boundaries.add((2, 0, false)); // Horizontal line at row 2
      boundaries.add((4, 0, false)); // Horizontal line at row 4
      boundaries.add((0, 3, true)); // Vertical line at col 3
    } else if (gridSize == 8) {
      // 2x4 regions: boundaries at row 2, 4, 6 and col 4
      boundaries.add((2, 0, false)); // Horizontal line at row 2
      boundaries.add((4, 0, false)); // Horizontal line at row 4
      boundaries.add((6, 0, false)); // Horizontal line at row 6
      boundaries.add((0, 4, true)); // Vertical line at col 4
    }
    
    return boundaries;
  }
  
  /// Get total number of regions for a grid size
  static int getTotalRegions(int gridSize) {
    if (gridSize == 4) return 4; // 2x2
    if (gridSize == 6) return 6; // 2x3
    if (gridSize == 8) return 8; // 2x4
    return 0;
  }
}

