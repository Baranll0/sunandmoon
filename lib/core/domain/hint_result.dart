import '../utils/forced_move_detector.dart';
import 'move.dart';

/// Result of a hint request
class HintResult {
  /// Whether a forced move was found
  final bool hasHint;
  
  /// The forced move (if found)
  final Move? move;
  
  /// Human-readable explanation
  final String explanation;
  
  /// Suggestion when no forced move exists
  final String? suggestion;
  
  const HintResult({
    required this.hasHint,
    this.move,
    required this.explanation,
    this.suggestion,
  });
  
  /// Create a hint result with a forced move
  factory HintResult.withMove(Move move, int gridSize) {
    return HintResult(
      hasHint: true,
      move: move,
      explanation: move.getExplanation(gridSize),
    );
  }
  
  /// Create a hint result when no forced move exists
  factory HintResult.noHint() {
    return const HintResult(
      hasHint: false,
      explanation: 'No immediate forced moves found.',
      suggestion: 'Try using Note Mode to explore possibilities. Some puzzles require deeper logical reasoning.',
    );
  }
  
  /// Create a hint result suggesting note mode
  factory HintResult.suggestNoteMode() {
    return const HintResult(
      hasHint: false,
      explanation: 'This puzzle requires deeper reasoning.',
      suggestion: 'Use Note Mode to mark possibilities and test hypotheses. The solution will emerge through logical deduction.',
    );
  }
}

/// Hint API for finding explainable hints
class HintAPI {
  /// Get a hint for the current board state
  /// 
  /// Returns a HintResult with either:
  /// - A forced move with explanation, OR
  /// - A suggestion to use Note Mode
  static HintResult getHint(
    List<List<int>> grid, {
    List<List<bool>>? givenLocks,
  }) {
    final detector = ForcedMoveDetector(
      grid: grid,
      givenLocks: givenLocks,
    );
    
    final move = detector.findFirstForcedMove();
    
    if (move != null) {
      return HintResult.withMove(move, grid.length);
    }
    
    // No forced moves - suggest note mode
    return HintResult.suggestNoteMode();
  }
  
  /// Get all available forced moves (for advanced UI)
  static List<Move> getAllForcedMoves(
    List<List<int>> grid, {
    List<List<bool>>? givenLocks,
  }) {
    final detector = ForcedMoveDetector(
      grid: grid,
      givenLocks: givenLocks,
    );
    
    return detector.findForcedMoves();
  }
}

