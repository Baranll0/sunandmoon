import '../domain/generation_failure_reason.dart';
import '../domain/generation_report.dart';
import 'level_generator.dart';

/// Internal result class for generation attempts
class GenerationResult {
  final bool success;
  final GeneratedLevel? level;
  final GenerationReport? report;
  final List<GenerationFailureReason> failures;
  
  GenerationResult({
    required this.success,
    this.level,
    this.report,
    this.failures = const [],
  });
}

