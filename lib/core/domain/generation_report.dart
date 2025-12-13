import '../utils/human_logic_solver.dart';

/// Comprehensive report for puzzle generation quality
/// Includes solver metrics and player-perceived difficulty indicators
class GenerationReport {
  final int size;
  final int chapter;
  final int level;
  final double targetDifficultyMin;
  final double targetDifficultyMax;
  
  // Final difficulty score
  final double finalDifficultyScore;
  
  // Solver metrics
  final DifficultyMetrics metrics;
  
  // NEW: Player-perceived difficulty metrics
  final double earlyForcedRatio; // Forced moves in first K assignments
  final int maxForcedChainLength; // Longest consecutive forced-move streak
  final int timeToFirstAmbiguity; // Assignments until first branching
  final double avgBranchingDepthContribution; // Meaningful branching depth
  
  // Generation metadata
  final int generationAttempts;
  final int givensCount;
  final bool isAccepted;
  final String? rejectionReason;
  
  GenerationReport({
    required this.size,
    required this.chapter,
    required this.level,
    required this.targetDifficultyMin,
    required this.targetDifficultyMax,
    required this.finalDifficultyScore,
    required this.metrics,
    required this.earlyForcedRatio,
    required this.maxForcedChainLength,
    required this.timeToFirstAmbiguity,
    required this.avgBranchingDepthContribution,
    required this.generationAttempts,
    required this.givensCount,
    this.isAccepted = true,
    this.rejectionReason,
  });
  
  /// Create a report from solver metrics
  factory GenerationReport.fromMetrics({
    required int size,
    required int chapter,
    required int level,
    required double targetDifficultyMin,
    required double targetDifficultyMax,
    required DifficultyMetrics metrics,
    required int generationAttempts,
    required int givensCount,
    required List<int> forcedMoveIndices, // Indices where forced moves occurred
    required List<int> branchingIndices, // Indices where branching occurred
    required List<int> branchDepths, // Depth at each branching point
    bool isAccepted = true,
    String? rejectionReason,
  }) {
    // Calculate earlyForcedRatio (first K assignments)
    final int k = _getEarlyWindowSize(size);
    final int earlyForcedCount = forcedMoveIndices.where((idx) => idx < k).length;
    final double earlyForcedRatio = k > 0 ? earlyForcedCount / k : 0.0;
    
    // Calculate maxForcedChainLength
    final int maxForcedChainLength = _calculateMaxForcedChainLength(forcedMoveIndices);
    
    // Calculate timeToFirstAmbiguity (firstBranchStepIndex, but normalized)
    final int timeToFirstAmbiguity = metrics.firstBranchStepIndex >= 0 
        ? metrics.firstBranchStepIndex 
        : metrics.totalAssignments; // If no branching, use total
    
    // Calculate avgBranchingDepthContribution
    final double avgBranchingDepthContribution = branchDepths.isNotEmpty
        ? branchDepths.reduce((a, b) => a + b) / branchDepths.length
        : 0.0;
    
    return GenerationReport(
      size: size,
      chapter: chapter,
      level: level,
      targetDifficultyMin: targetDifficultyMin,
      targetDifficultyMax: targetDifficultyMax,
      finalDifficultyScore: metrics.computeDifficultyScore(size),
      metrics: metrics,
      earlyForcedRatio: earlyForcedRatio,
      maxForcedChainLength: maxForcedChainLength,
      timeToFirstAmbiguity: timeToFirstAmbiguity,
      avgBranchingDepthContribution: avgBranchingDepthContribution,
      generationAttempts: generationAttempts,
      givensCount: givensCount,
      isAccepted: isAccepted,
      rejectionReason: rejectionReason,
    );
  }
  
  /// Get early window size based on grid size
  static int _getEarlyWindowSize(int size) {
    switch (size) {
      case 4: return 6;
      case 6: return 12;
      case 8: return 20;
      default: return size * 1.5 as int;
    }
  }
  
  /// Calculate longest consecutive forced-move streak
  static int _calculateMaxForcedChainLength(List<int> forcedMoveIndices) {
    if (forcedMoveIndices.isEmpty) return 0;
    
    forcedMoveIndices.sort();
    int maxChain = 1;
    int currentChain = 1;
    
    for (int i = 1; i < forcedMoveIndices.length; i++) {
      if (forcedMoveIndices[i] == forcedMoveIndices[i - 1] + 1) {
        currentChain++;
        maxChain = currentChain > maxChain ? currentChain : maxChain;
      } else {
        currentChain = 1;
      }
    }
    
    return maxChain;
  }
  
  /// Check if puzzle meets quality gates
  bool meetsQualityGates() {
    if (chapter >= 2) {
      // Chapter 2+ constraints
      if (earlyForcedRatio > 0.80) return false;
      
      final int maxChainThreshold = size == 4 ? 6 : (size == 6 ? 10 : 15);
      if (maxForcedChainLength > maxChainThreshold) return false;
      
      final int ambiguityThreshold = size == 4 ? 8 : (size == 6 ? 16 : 24);
      if (timeToFirstAmbiguity > ambiguityThreshold) return false;
    } else {
      // Chapter 1: allow higher earlyForcedRatio but gradually reduce
      final double maxEarlyForced = 0.90 - (level * 0.02); // 90% at level 1, 60% at level 15
      if (earlyForcedRatio > maxEarlyForced) return false;
    }
    
    return true;
  }
  
  /// Convert to JSON for export
  Map<String, dynamic> toJson() {
    return {
      'size': size,
      'chapter': chapter,
      'level': level,
      'targetDifficultyRange': {
        'min': targetDifficultyMin,
        'max': targetDifficultyMax,
      },
      'finalDifficultyScore': finalDifficultyScore,
      'solverMetrics': {
        'forcedMovesCount': metrics.forcedMovesCount,
        'branchingEventsCount': metrics.branchingEventsCount,
        'maxBranchDepth': metrics.maxBranchDepth,
        'backtracksCount': metrics.backtracksCount,
        'totalAssignments': metrics.totalAssignments,
        'firstBranchStepIndex': metrics.firstBranchStepIndex,
        'forcedMoveRatio': metrics.forcedMoveRatio,
      },
      'playerPerceivedMetrics': {
        'earlyForcedRatio': earlyForcedRatio,
        'maxForcedChainLength': maxForcedChainLength,
        'timeToFirstAmbiguity': timeToFirstAmbiguity,
        'avgBranchingDepthContribution': avgBranchingDepthContribution,
      },
      'generation': {
        'attempts': generationAttempts,
        'givensCount': givensCount,
        'isAccepted': isAccepted,
        'rejectionReason': rejectionReason,
      },
    };
  }
  
  /// Get human-readable summary
  String getSummary() {
    final buffer = StringBuffer();
    buffer.writeln('=== Generation Report ===');
    buffer.writeln('Chapter $chapter, Level $level (${size}x$size)');
    buffer.writeln('Target Difficulty: $targetDifficultyMin - $targetDifficultyMax');
    buffer.writeln('Final Score: ${finalDifficultyScore.toStringAsFixed(2)}');
    buffer.writeln('');
    buffer.writeln('Solver Metrics:');
    buffer.writeln('  Forced Moves: ${metrics.forcedMovesCount}/${metrics.totalAssignments} (${(metrics.forcedMoveRatio * 100).toStringAsFixed(1)}%)');
    buffer.writeln('  Branching Events: ${metrics.branchingEventsCount}');
    buffer.writeln('  Backtracks: ${metrics.backtracksCount}');
    buffer.writeln('  Max Depth: ${metrics.maxBranchDepth}');
    buffer.writeln('');
    buffer.writeln('Player-Perceived Metrics:');
    buffer.writeln('  Early Forced Ratio: ${(earlyForcedRatio * 100).toStringAsFixed(1)}%');
    buffer.writeln('  Max Forced Chain: $maxForcedChainLength');
    buffer.writeln('  Time to First Ambiguity: $timeToFirstAmbiguity');
    buffer.writeln('  Avg Branching Depth: ${avgBranchingDepthContribution.toStringAsFixed(2)}');
    buffer.writeln('');
    buffer.writeln('Quality Gates: ${meetsQualityGates() ? "PASS" : "FAIL"}');
    if (rejectionReason != null) {
      buffer.writeln('Rejection: $rejectionReason');
    }
    return buffer.toString();
  }
}

