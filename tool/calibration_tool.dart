import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:sun_moon_puzzle/core/utils/level_generator.dart';
import 'package:sun_moon_puzzle/core/utils/human_logic_solver.dart';
import 'package:sun_moon_puzzle/core/domain/generation_report.dart';

/// Calibration tool for difficulty distribution analysis
/// Generates N puzzles per chapter and outputs statistics
void main(List<String> args) {
  final int puzzlesPerChapter = args.isNotEmpty ? int.parse(args[0]) : 200;
  final int maxChapters = args.length > 1 ? int.parse(args[1]) : 5;
  
  print('=== Tango Logic - Difficulty Calibration Tool ===');
  print('Generating $puzzlesPerChapter puzzles per chapter (Chapters 1-$maxChapters)\n');
  
  final generator = LevelGenerator();
  final Map<int, ChapterStats> stats = {};
  
  for (int chapter = 1; chapter <= maxChapters; chapter++) {
    print('Generating Chapter $chapter...');
    final chapterStats = ChapterStats();
    
    for (int i = 0; i < puzzlesPerChapter; i++) {
      final level = (i % 15) + 1; // Cycle through levels 1-15
      GenerationReport? report;
      
      try {
        final generatedLevel = generator.generateLevel(chapter, level);
        // Create report manually since we can't get it from generateLevel easily
        // For now, we'll solve again to get the report
        // TODO: Refactor generateLevel to return report
        final solver = HumanLogicSolver(generatedLevel.size);
        final solveReport = solver.solve(generatedLevel.givens);
        
        report = GenerationReport.fromMetrics(
          size: generatedLevel.size,
          chapter: chapter,
          level: level,
          targetDifficultyMin: 0.0, // Will be calculated
          targetDifficultyMax: 10.0,
          metrics: solveReport.metrics,
          generationAttempts: 1,
          givensCount: _countGivens(generatedLevel.givens),
          forcedMoveIndices: solveReport.forcedMoveIndices,
          branchingIndices: solveReport.branchingIndices,
          branchDepths: solveReport.branchDepths,
        );
        
        chapterStats.addPuzzle(report);
      } catch (e) {
        print('Error generating Chapter $chapter, Level $level: $e');
        continue;
      }
      
      if ((i + 1) % 50 == 0) {
        print('  Progress: ${i + 1}/$puzzlesPerChapter');
      }
    }
    
    stats[chapter] = chapterStats;
    print('Chapter $chapter complete: ${chapterStats.summary}\n');
  }
  
  // Generate report
  final report = _generateReport(stats);
  print(report);
  
  // Save to file
  final reportFile = File('calibration_report.json');
  reportFile.writeAsStringSync(jsonEncode(_generateJsonReport(stats)));
  print('\nReport saved to: ${reportFile.path}');
}

int _countGivens(List<List<int>> puzzle) {
  int count = 0;
  for (final row in puzzle) {
    for (final cell in row) {
      if (cell != 0) count++;
    }
  }
  return count;
}

String _generateReport(Map<int, ChapterStats> stats) {
  final buffer = StringBuffer();
  buffer.writeln('=== Calibration Report ===\n');
  
  for (final entry in stats.entries) {
    final chapter = entry.key;
    final stat = entry.value;
    buffer.writeln('Chapter $chapter:');
    buffer.writeln(stat.summary);
    buffer.writeln('');
  }
  
  return buffer.toString();
}

Map<String, dynamic> _generateJsonReport(Map<int, ChapterStats> stats) {
  final Map<String, dynamic> report = {
    'generatedAt': DateTime.now().toIso8601String(),
    'chapters': {},
  };
  
  for (final entry in stats.entries) {
    report['chapters'][entry.key.toString()] = entry.value.toJson();
  }
  
  return report;
}

class ChapterStats {
  final List<double> difficultyScores = [];
  final List<double> forcedMoveRatios = [];
  final List<int> branchingEvents = [];
  final List<int> timeToFirstAmbiguity = [];
  final List<double> earlyForcedRatios = [];
  final List<int> maxForcedChainLengths = [];
  
  void addPuzzle(GenerationReport report) {
    difficultyScores.add(report.finalDifficultyScore);
    forcedMoveRatios.add(report.metrics.forcedMoveRatio);
    branchingEvents.add(report.metrics.branchingEventsCount);
    timeToFirstAmbiguity.add(report.timeToFirstAmbiguity);
    earlyForcedRatios.add(report.earlyForcedRatio);
    maxForcedChainLengths.add(report.maxForcedChainLength);
  }
  
  String get summary {
    final buffer = StringBuffer();
    buffer.writeln('  Difficulty Score:');
    buffer.writeln('    Mean: ${_mean(difficultyScores).toStringAsFixed(2)}');
    buffer.writeln('    Median: ${_median(difficultyScores).toStringAsFixed(2)}');
    buffer.writeln('    Std: ${_std(difficultyScores).toStringAsFixed(2)}');
    buffer.writeln('    Range: ${_min(difficultyScores).toStringAsFixed(2)} - ${_max(difficultyScores).toStringAsFixed(2)}');
    buffer.writeln('  Forced Move Ratio:');
    buffer.writeln('    Mean: ${_mean(forcedMoveRatios).toStringAsFixed(3)}');
    buffer.writeln('  Branching Events:');
    buffer.writeln('    Mean: ${_mean(branchingEvents.map((e) => e.toDouble())).toStringAsFixed(2)}');
    buffer.writeln('  Time to First Ambiguity:');
    buffer.writeln('    Mean: ${_mean(timeToFirstAmbiguity.map((e) => e.toDouble())).toStringAsFixed(2)}');
    buffer.writeln('  Early Forced Ratio:');
    buffer.writeln('    Mean: ${_mean(earlyForcedRatios).toStringAsFixed(3)}');
    buffer.writeln('  Max Forced Chain:');
    buffer.writeln('    Mean: ${_mean(maxForcedChainLengths.map((e) => e.toDouble())).toStringAsFixed(2)}');
    return buffer.toString();
  }
  
  Map<String, dynamic> toJson() {
    return {
      'difficultyScore': {
        'mean': _mean(difficultyScores),
        'median': _median(difficultyScores),
        'std': _std(difficultyScores),
        'min': _min(difficultyScores),
        'max': _max(difficultyScores),
        'histogram': _histogram(difficultyScores, 0.0, 10.0, 20),
      },
      'forcedMoveRatio': {
        'mean': _mean(forcedMoveRatios),
        'histogram': _histogram(forcedMoveRatios, 0.0, 1.0, 20),
      },
      'branchingEvents': {
        'mean': _mean(branchingEvents.map((e) => e.toDouble())),
        'histogram': _histogram(branchingEvents.map((e) => e.toDouble()), 0.0, 20.0, 20),
      },
      'timeToFirstAmbiguity': {
        'mean': _mean(timeToFirstAmbiguity.map((e) => e.toDouble())),
        'histogram': _histogram(timeToFirstAmbiguity.map((e) => e.toDouble()), 0.0, 50.0, 25),
      },
    };
  }
  
  double _mean(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }
  
  double _median(List<double> values) {
    if (values.isEmpty) return 0.0;
    final sorted = List<double>.from(values)..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length % 2 == 0) {
      return (sorted[mid - 1] + sorted[mid]) / 2;
    }
    return sorted[mid];
  }
  
  double _std(List<double> values) {
    if (values.isEmpty) return 0.0;
    final mean = _mean(values);
    final variance = values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / values.length;
    return variance.sqrt();
  }
  
  double _min(List<double> values) => values.isEmpty ? 0.0 : values.reduce((a, b) => a < b ? a : b);
  double _max(List<double> values) => values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);
  
  List<int> _histogram(List<double> values, double min, double max, int bins) {
    final histogram = List.filled(bins, 0);
    final binWidth = (max - min) / bins;
    
    for (final value in values) {
      if (value < min || value > max) continue;
      final binIndex = ((value - min) / binWidth).floor().clamp(0, bins - 1);
      histogram[binIndex]++;
    }
    
    return histogram;
  }
}

