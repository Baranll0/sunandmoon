import '../domain/mechanic_flag.dart';

/// Plan for mechanics active in a specific level
class MechanicsPlan {
  final List<MechanicFlag> mechanics;
  final Map<String, dynamic> params;

  const MechanicsPlan({
    required this.mechanics,
    required this.params,
  });

  factory MechanicsPlan.empty() {
    return const MechanicsPlan(mechanics: [], params: {});
  }
}

/// Central authority for Game Mechanics scheduling
/// Enforces the Master Spec progression (Chapters 1-5)
class MechanicsManager {
  
  /// Get the mechanics plan for a specific chapter and level
  /// [chapter]: 1-based chapter number
  /// [level]: 1-based relative level number within the chapter
  static MechanicsPlan getMechanicsFor(int chapter, int level) {
    switch (chapter) {
      case 1:
        return MechanicsPlan.empty();
        
      case 2:
        return _getChapter2Mechanics(level);
        
      case 3:
        return _getChapter3Mechanics(level);
        
      case 4:
        return _getChapter4Mechanics(level);
        
      case 5:
        return _getChapter5Mechanics(level);
        
      default:
        // Future chapters: Procedural or repeat Ch5
        return MechanicsPlan.empty();
    }
  }
  
  // Chapter 2: Introduce Locked Cells (Light)
  static MechanicsPlan _getChapter2Mechanics(int level) {
    if (level < 10) {
      return MechanicsPlan.empty();
    }
    // Level 10-20: Classic (Locked Cells removed)
    return MechanicsPlan.empty();
  }
  
  // Chapter 3: Introduce Mistake Limit
  static MechanicsPlan _getChapter3Mechanics(int level) {
    // Level 1-20: Mistake Limit
    // (Levels 11-20 are harder puzzles, but mechanic stays same)
    return const MechanicsPlan(
      mechanics: [MechanicFlag.mistakeLimit],
      params: {
        'maxMistakes': 3, // Standard 3 lives
      },
    );
  }
  
  // Chapter 4: Introduce Regions
  static MechanicsPlan _getChapter4Mechanics(int level) {
    // Level 1-20: Regions
    // Initially visual-only (soft enforcement), later strict
    return const MechanicsPlan(
      mechanics: [MechanicFlag.regions],
      params: {
        'regionCount': 2, // 2 regions for 6x6 usually
      },
    );
  }
  
  // Chapter 5: Move Limit & Mix
  static MechanicsPlan _getChapter5Mechanics(int level) {
    if (level <= 10) {
      // Level 1-10: Move Limit (Harder)
      return const MechanicsPlan(
        mechanics: [MechanicFlag.moveLimit],
        params: {
          'moveBuffer': 5, // Optimal moves + 5
        },
      );
    }
    
    // Level 11-20: Mixed Mechanics (Combos)
    // Every 3-4 levels, mix current (Move Limit) with previous
    
    // Pattern: 
    // 11-13: Move Limit + Locked Cells
    // 14-16: Move Limit + Mistake Limit
    // 17-20: Move Limit + Regions + Locked Cells (Boss levels)
    
    if (level <= 13) {
      return const MechanicsPlan(
        mechanics: [MechanicFlag.moveLimit],
        params: {
          'moveBuffer': 5,
        },
      );
    } else if (level <= 16) {
      return const MechanicsPlan(
        mechanics: [MechanicFlag.moveLimit, MechanicFlag.mistakeLimit],
        params: {
          'moveBuffer': 4,
          'maxMistakes': 3,
        },
      );
    } else {
      return const MechanicsPlan(
        mechanics: [MechanicFlag.moveLimit, MechanicFlag.regions],
        params: {
          'moveBuffer': 5,
          'regionCount': 2,
        },
      );
    }
  }
}
