/// Mechanic flags that can be applied to levels
/// These represent optional constraints/rules that add variety
enum MechanicFlag {
  /// Baseline classic mode (no special mechanics)
  classic,
  
  /// Board partitioned into regions; each region must have equal Sun/Moon
  regions,
  
  /// More "fixed locks" or special locks beyond normal givens
  lockedCells,
  
  /// Extra pattern rules beyond base (e.g., forbidding more patterns or enforcing symmetry)
  advancedNoThree,
  
  /// A rule that is not displayed initially; revealed after N mistakes or via tutorial
  hiddenRule,
  
  /// Max moves allowed (soft in early usage)
  moveLimit,
  
  /// Max invalid attempts allowed
  mistakeLimit,
  
  /// Certain levels require pencil mode usage or show "hint suggests notes"
  noteRequired,
  
  /// Daily or per-level cap / gating for hints
  limitedHints,
  
  /// Future challenge mode (optional)
  challengeMode,
}

/// Extension to get string representation for JSON serialization
extension MechanicFlagExtension on MechanicFlag {
  String get name => toString().split('.').last;
  
  static MechanicFlag? fromString(String name) {
    try {
      return MechanicFlag.values.firstWhere(
        (m) => m.name == name,
      );
    } catch (e) {
      return null;
    }
  }
}

