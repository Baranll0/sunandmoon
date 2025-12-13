/// Reasons why puzzle generation failed
enum GenerationFailureReason {
  /// Quality gates failed (earlyForcedRatio, maxChain, timeToAmbiguity)
  qualityGatesFailed,
  
  /// Difficulty score outside target range
  difficultyOutOfRange,
  
  /// Puzzle is not unique (multiple solutions)
  notUnique,
  
  /// Puzzle is not solvable
  notSolvable,
  
  /// Maximum attempts exceeded
  maxAttemptsExceeded,
  
  /// Unknown error
  unknown,
}

/// Summary of generation failures for logging
class GenerationFailureSummary {
  final Map<GenerationFailureReason, int> failureCounts;
  final List<String> topReasons;
  final int totalAttempts;
  
  GenerationFailureSummary({
    required this.failureCounts,
    required this.topReasons,
    required this.totalAttempts,
  });
  
  /// Create summary from list of failures
  factory GenerationFailureSummary.fromFailures(
    List<GenerationFailureReason> failures,
  ) {
    final counts = <GenerationFailureReason, int>{};
    for (final reason in failures) {
      counts[reason] = (counts[reason] ?? 0) + 1;
    }
    
    // Sort by count (descending) and get top 3
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topReasons = sorted.take(3).map((e) => 
      '${e.key.name}: ${e.value} times'
    ).toList();
    
    return GenerationFailureSummary(
      failureCounts: counts,
      topReasons: topReasons,
      totalAttempts: failures.length,
    );
  }
  
  String getSummary() {
    final buffer = StringBuffer();
    buffer.writeln('Generation Failure Summary:');
    buffer.writeln('Total Attempts: $totalAttempts');
    buffer.writeln('Top Failure Reasons:');
    for (final reason in topReasons) {
      buffer.writeln('  - $reason');
    }
    return buffer.toString();
  }
}

