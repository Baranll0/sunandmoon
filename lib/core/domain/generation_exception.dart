import 'generation_failure_reason.dart';

/// Exception thrown when puzzle generation fails after all retry strategies
class GenerationException implements Exception {
  final String message;
  final GenerationFailureReason reason;
  final GenerationFailureSummary? summary;
  
  GenerationException(
    this.message, {
    required this.reason,
    this.summary,
  });
  
  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('GenerationException: $message');
    buffer.writeln('Reason: ${reason.name}');
    if (summary != null) {
      buffer.writeln(summary!.getSummary());
    }
    return buffer.toString();
  }
}

