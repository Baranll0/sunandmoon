import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../utils/grid_validator.dart';
import '../utils/human_logic_solver.dart';
import '../domain/generation_report.dart';

/// Loaded level data from JSON
class LoadedLevel {
  final int id;
  final int chapter;
  final int level;
  final int size;
  final List<List<int>> givens;
  final List<List<int>> solution;
  final double difficultyScore;
  
  LoadedLevel({
    required this.id,
    required this.chapter,
    required this.level,
    required this.size,
    required this.givens,
    required this.solution,
    required this.difficultyScore,
  });
  
  factory LoadedLevel.fromJson(Map<String, dynamic> json) {
    return LoadedLevel(
      id: json['id'] as int,
      chapter: json['chapter'] as int,
      level: json['level'] as int,
      size: json['size'] as int,
      givens: (json['givens'] as List)
          .map((row) => (row as List).map((e) => e as int).toList())
          .toList(),
      solution: (json['solution'] as List)
          .map((row) => (row as List).map((e) => e as int).toList())
          .toList(),
      difficultyScore: (json['difficultyScore'] as num).toDouble(),
    );
  }
}

/// Chapter metadata from index.json
class ChapterMetadata {
  final int chapter;
  final int gridSize;
  final int levelCount;
  final String difficultyLabel;
  final String file;
  
  ChapterMetadata({
    required this.chapter,
    required this.gridSize,
    required this.levelCount,
    required this.difficultyLabel,
    required this.file,
  });
  
  factory ChapterMetadata.fromJson(Map<String, dynamic> json) {
    return ChapterMetadata(
      chapter: json['chapter'] as int,
      gridSize: json['gridSize'] as int,
      levelCount: json['levelCount'] as int,
      difficultyLabel: json['difficultyLabel'] as String,
      file: json['file'] as String,
    );
  }
}

/// Level pack index
class LevelPackIndex {
  final String version;
  final String generatedAt;
  final String? gitCommitHash;
  final List<ChapterMetadata> chapters;
  
  LevelPackIndex({
    required this.version,
    required this.generatedAt,
    this.gitCommitHash,
    required this.chapters,
  });
  
  factory LevelPackIndex.fromJson(Map<String, dynamic> json) {
    return LevelPackIndex(
      version: json['version'] as String,
      generatedAt: json['generatedAt'] as String,
      gitCommitHash: json['gitCommitHash'] as String?,
      chapters: (json['chapters'] as List)
          .map((c) => ChapterMetadata.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Runtime level loader and validator
class LevelLoader {
  static LevelPackIndex? _cachedIndex;
  
  /// Load the level pack index
  static Future<LevelPackIndex> loadIndex() async {
    if (_cachedIndex != null) {
      return _cachedIndex!;
    }
    
    try {
      final jsonString = await rootBundle.loadString('assets/levels/index.json');
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      _cachedIndex = LevelPackIndex.fromJson(json);
      return _cachedIndex!;
    } catch (e) {
      throw LevelLoadException('Failed to load index.json: $e');
    }
  }
  
  /// Load a specific chapter
  static Future<List<LoadedLevel>> loadChapter(int chapter) async {
    final index = await loadIndex();
    final chapterMeta = index.chapters.firstWhere(
      (c) => c.chapter == chapter,
      orElse: () => throw LevelLoadException('Chapter $chapter not found in index'),
    );
    
    try {
      final jsonString = await rootBundle.loadString('assets/levels/${chapterMeta.file}');
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final levelsJson = json['levels'] as List;
      
      return levelsJson
          .map((l) => LoadedLevel.fromJson(l as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw LevelLoadException('Failed to load chapter $chapter: $e');
    }
  }
  
  /// Load a specific level
  static Future<LoadedLevel> loadLevel(int chapter, int level) async {
    final levels = await loadChapter(chapter);
    try {
      return levels.firstWhere((l) => l.level == level);
    } catch (e) {
      throw LevelLoadException('Level $level not found in Chapter $chapter');
    }
  }
  
  /// Validate a loaded level (structure, rules, uniqueness)
  /// Returns validation result with optional solver report
  static Future<LevelValidationResult> validateLevel(
    LoadedLevel level, {
    bool checkUniqueness = false,
  }) async {
    final issues = <String>[];
    
    // 1. Structure validation
    if (level.givens.length != level.size) {
      issues.add('Givens grid height (${level.givens.length}) != size ($level.size)');
    }
    for (int i = 0; i < level.givens.length; i++) {
      if (level.givens[i].length != level.size) {
        issues.add('Row $i width (${level.givens[i].length}) != size ($level.size)');
      }
    }
    
    if (level.solution.length != level.size) {
      issues.add('Solution grid height (${level.solution.length}) != size ($level.size)');
    }
    for (int i = 0; i < level.solution.length; i++) {
      if (level.solution[i].length != level.size) {
        issues.add('Solution row $i width (${level.solution[i].length}) != size ($level.size)');
      }
    }
    
    // 2. Rules validation (givens must be valid)
    final validator = GridValidator(level.size);
    for (int r = 0; r < level.size; r++) {
      for (int c = 0; c < level.size; c++) {
        final value = level.givens[r][c];
        if (value != 0) { // Not empty
          final violations = validator.checkMove(level.givens, r, c, value);
          if (violations.isNotEmpty) {
            issues.add('Givens violation at [$r, $c]: ${violations.map((v) => v.type.name).join(", ")}');
          }
        }
      }
    }
    
    // 3. Solution validation (must be complete and valid)
    final solutionViolations = validator.validateComplete(level.solution);
    if (solutionViolations.isNotEmpty) {
      issues.add('Solution invalid: ${solutionViolations.map((v) => v.type.name).join(", ")}');
    }
    
    // 4. Uniqueness check (optional, expensive)
    bool isUnique = true;
    String? uniquenessError;
    if (checkUniqueness) {
      try {
        final solver = HumanLogicSolver(level.size);
        final report = solver.solve(level.givens);
        isUnique = report.isUnique;
        if (!report.isUnique) {
          uniquenessError = 'Puzzle does not have unique solution';
        }
      } catch (e) {
        uniquenessError = 'Uniqueness check failed: $e';
      }
    }
    
    return LevelValidationResult(
      isValid: issues.isEmpty && (checkUniqueness ? isUnique : true),
      issues: issues,
      uniquenessError: uniquenessError,
      isUnique: isUnique,
    );
  }
}

/// Validation result
class LevelValidationResult {
  final bool isValid;
  final List<String> issues;
  final String? uniquenessError;
  final bool isUnique;
  
  LevelValidationResult({
    required this.isValid,
    required this.issues,
    this.uniquenessError,
    required this.isUnique,
  });
  
  String getSummary() {
    if (isValid) {
      return 'Level is valid';
    }
    final buffer = StringBuffer();
    buffer.writeln('Validation failed:');
    for (final issue in issues) {
      buffer.writeln('  - $issue');
    }
    if (uniquenessError != null) {
      buffer.writeln('  - $uniquenessError');
    }
    return buffer.toString();
  }
}

/// Exception thrown when level loading fails
class LevelLoadException implements Exception {
  final String message;
  
  LevelLoadException(this.message);
  
  @override
  String toString() => 'LevelLoadException: $message';
}

