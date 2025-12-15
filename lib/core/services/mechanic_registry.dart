import '../domain/mechanic_flag.dart';
import '../localization/app_strings.dart';

/// Registry for mechanic metadata (localized titles, descriptions, icons, default params)
class MechanicRegistry {
  /// Get localized title for a mechanic
  static String getTitle(MechanicFlag mechanic, AppStrings strings) {
    switch (mechanic) {
      case MechanicFlag.classic:
        return strings.mechanicClassicTitle;
      case MechanicFlag.regions:
        return strings.mechanicRegionsTitle;
      case MechanicFlag.lockedCells:
        return strings.mechanicLockedCellsTitle;
      case MechanicFlag.advancedNoThree:
        return strings.mechanicAdvancedNoThreeTitle;
      case MechanicFlag.hiddenRule:
        return strings.mechanicHiddenRuleTitle;
      case MechanicFlag.moveLimit:
        return strings.mechanicMoveLimitTitle;
      case MechanicFlag.mistakeLimit:
        return strings.mechanicMistakeLimitTitle;
      case MechanicFlag.noteRequired:
        return strings.mechanicNoteRequiredTitle;
      case MechanicFlag.limitedHints:
        return strings.mechanicLimitedHintsTitle;
      case MechanicFlag.challengeMode:
        return strings.mechanicChallengeModeTitle;
    }
  }
  
  /// Get localized description for a mechanic
  static String getDescription(MechanicFlag mechanic, AppStrings strings) {
    switch (mechanic) {
      case MechanicFlag.classic:
        return strings.mechanicClassicDescription;
      case MechanicFlag.regions:
        return strings.mechanicRegionsDescription;
      case MechanicFlag.lockedCells:
        return strings.mechanicLockedCellsDescription;
      case MechanicFlag.advancedNoThree:
        return strings.mechanicAdvancedNoThreeDescription;
      case MechanicFlag.hiddenRule:
        return strings.mechanicHiddenRuleDescription;
      case MechanicFlag.moveLimit:
        return strings.mechanicMoveLimitDescription;
      case MechanicFlag.mistakeLimit:
        return strings.mechanicMistakeLimitDescription;
      case MechanicFlag.noteRequired:
        return strings.mechanicNoteRequiredDescription;
      case MechanicFlag.limitedHints:
        return strings.mechanicLimitedHintsDescription;
      case MechanicFlag.challengeMode:
        return strings.mechanicChallengeModeDescription;
    }
  }
  
  /// Get icon data for a mechanic (returns icon name/code)
  static String getIcon(MechanicFlag mechanic) {
    switch (mechanic) {
      case MechanicFlag.classic:
        return 'classic';
      case MechanicFlag.regions:
        return 'grid';
      case MechanicFlag.lockedCells:
        return 'lock';
      case MechanicFlag.advancedNoThree:
        return 'pattern';
      case MechanicFlag.hiddenRule:
        return 'visibility_off';
      case MechanicFlag.moveLimit:
        return 'timer';
      case MechanicFlag.mistakeLimit:
        return 'error';
      case MechanicFlag.noteRequired:
        return 'edit';
      case MechanicFlag.limitedHints:
        return 'lightbulb';
      case MechanicFlag.challengeMode:
        return 'star';
    }
  }
  
  /// Get default parameters for a mechanic
  static Map<String, dynamic> getDefaultParams(MechanicFlag mechanic) {
    switch (mechanic) {
      case MechanicFlag.classic:
        return {};
      case MechanicFlag.regions:
        return {'regionLayoutId': 'default'};
      case MechanicFlag.lockedCells:
        return {'lockedCount': 0};
      case MechanicFlag.advancedNoThree:
        return {'patternLevel': 1};
      case MechanicFlag.hiddenRule:
        return {'revealAfterMistakes': 3};
      case MechanicFlag.moveLimit:
        return {'maxMoves': 50};
      case MechanicFlag.mistakeLimit:
        return {'maxMistakes': 5};
      case MechanicFlag.noteRequired:
        return {'requiredNoteCount': 3};
      case MechanicFlag.limitedHints:
        return {'hintsPerLevel': 3};
      case MechanicFlag.challengeMode:
        return {};
    }
  }
  
  /// Get mechanics schedule for a specific level (first 200 levels)
  static List<MechanicFlag> getMechanicsForLevel(int chapter, int level) {
    // Chapter 1 (4x4, 10 levels): classic only
    if (chapter == 1) {
      return [MechanicFlag.classic];
    }
    
    // Chapter 2 (6x6, 60 levels)
    if (chapter == 2) {
      if (level <= 15) {
        return [MechanicFlag.classic];
      } else if (level <= 30) {
        return [MechanicFlag.regions];
      } else if (level <= 45) {
        return [MechanicFlag.regions, MechanicFlag.lockedCells];
      } else {
        return [MechanicFlag.regions, MechanicFlag.lockedCells, MechanicFlag.advancedNoThree];
      }
    }
    
    // Chapter 3 (8x8, 70 levels)
    if (chapter == 3) {
      if (level <= 15) {
        return [MechanicFlag.classic];
      } else if (level <= 30) {
        return [MechanicFlag.regions];
      } else if (level <= 45) {
        return [MechanicFlag.lockedCells, MechanicFlag.advancedNoThree];
      } else if (level <= 60) {
        return [MechanicFlag.regions, MechanicFlag.hiddenRule];
      } else {
        return [MechanicFlag.regions, MechanicFlag.lockedCells, MechanicFlag.advancedNoThree];
      }
    }
    
    // Chapter 4 (8x8 mastery, 60 levels)
    if (chapter == 4) {
      if (level <= 15) {
        return [MechanicFlag.classic, MechanicFlag.moveLimit];
      } else if (level <= 30) {
        return [MechanicFlag.regions, MechanicFlag.moveLimit];
      } else if (level <= 45) {
        return [MechanicFlag.classic, MechanicFlag.advancedNoThree, MechanicFlag.mistakeLimit];
      } else {
        return [MechanicFlag.regions, MechanicFlag.lockedCells, MechanicFlag.advancedNoThree, MechanicFlag.mistakeLimit];
      }
    }
    
    // Chapter 5+ (procedural continuation)
    return [MechanicFlag.classic];
  }
  
  /// Get default params for a level based on its mechanics
  static Map<String, dynamic> getParamsForLevel(int chapter, int level, List<MechanicFlag> mechanics) {
    final params = <String, dynamic>{};
    
    for (final mechanic in mechanics) {
      final defaultParams = getDefaultParams(mechanic);
      params.addAll(defaultParams);
      
      // Adjust params based on chapter/level difficulty
      if (mechanic == MechanicFlag.moveLimit) {
        final baseMoves = chapter == 2 ? 60 : (chapter == 3 ? 80 : 100);
        params['maxMoves'] = baseMoves - (level ~/ 5);
      } else if (mechanic == MechanicFlag.mistakeLimit) {
        params['maxMistakes'] = chapter >= 4 ? 3 : 5;
      }
    }
    
    return params;
  }
}

