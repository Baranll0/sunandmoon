import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../utils/grid_validator.dart';
import '../utils/human_logic_solver.dart';
import '../domain/generation_report.dart';

import '../domain/mechanic_flag.dart';
import '../domain/level_meta.dart';

/// Loaded level data from JSON (with mechanics support)
class LoadedLevel {
  final int id;
  final int chapter;
  final int level;
  final int size;
  final List<List<int>> givens;
  final List<List<int>> solution;
  final double difficultyScore;
  final List<MechanicFlag> mechanics;
  final Map<String, dynamic> params;
  
  LoadedLevel({
    required this.id,
    required this.chapter,
    required this.level,
    required this.size,
    required this.givens,
    required this.solution,
    required this.difficultyScore,
    List<MechanicFlag>? mechanics,
    Map<String, dynamic>? params,
  }) : mechanics = mechanics ?? [MechanicFlag.classic],
       params = params ?? {};
  
  factory LoadedLevel.fromJson(Map<String, dynamic> json) {
    // Parse mechanics
    final mechanics = <MechanicFlag>[];
    if (json['mechanics'] != null) {
      final mechanicsList = json['mechanics'] as List;
      for (final m in mechanicsList) {
        final flag = MechanicFlagExtension.fromString(m as String);
        if (flag != null) {
          mechanics.add(flag);
        }
      }
    }
    // Default to classic if no mechanics specified
    if (mechanics.isEmpty) {
      mechanics.add(MechanicFlag.classic);
    }
    
    // Parse params
    final params = json['params'] != null
        ? Map<String, dynamic>.from(json['params'] as Map)
        : <String, dynamic>{};
    
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
      mechanics: mechanics,
      params: params,
    );
  }
  
  /// Convert to LevelMeta
  LevelMeta toLevelMeta() {
    return LevelMeta(
      chapter: chapter,
      level: level,
      size: size,
      mechanics: mechanics,
      params: params,
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
/// CRASH-PROOF: Handles errors gracefully in release, fails loudly in debug
class LevelLoader {
  static LevelPackIndex? _cachedIndex;
  static bool _verificationComplete = false;
  
  /// Load the level pack index
  /// Throws LevelLoadException in debug, returns null in release (graceful failure)
  static Future<LevelPackIndex?> loadIndex({bool throwOnError = true}) async {
    if (_cachedIndex != null) {
      return _cachedIndex;
    }
    
    try {
      final jsonString = await rootBundle.loadString('assets/levels/index.json');
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Validate schema
      if (json['version'] == null || json['chapters'] == null) {
        final error = 'Invalid index.json schema: missing required fields';
        if (kDebugMode || throwOnError) {
          throw LevelLoadException(error);
        }
        debugPrint('[LEVELS] $error');
        return null;
      }
      
      _cachedIndex = LevelPackIndex.fromJson(json);
      return _cachedIndex;
    } on PlatformException catch (e) {
      // File not found or asset error
      final error = 'Failed to load index.json: ${e.message}';
      if (kDebugMode || throwOnError) {
        throw LevelLoadException(error);
      }
      debugPrint('[LEVELS] $error');
      return null;
    } on FormatException catch (e) {
      // JSON parse error
      final error = 'Invalid JSON in index.json: ${e.message}';
      if (kDebugMode || throwOnError) {
        throw LevelLoadException(error);
      }
      debugPrint('[LEVELS] $error');
      return null;
    } catch (e) {
      final error = 'Unexpected error loading index.json: $e';
      if (kDebugMode || throwOnError) {
        throw LevelLoadException(error);
      }
      debugPrint('[LEVELS] $error');
      return null;
    }
  }
  
  /// Load a specific chapter
  /// Returns empty list in release on error, throws in debug
  static Future<List<LoadedLevel>> loadChapter(int chapter, {bool throwOnError = true}) async {
    final index = await loadIndex(throwOnError: throwOnError);
    if (index == null) {
      if (throwOnError) {
        throw LevelLoadException('Cannot load chapter $chapter: index not available');
      }
      return [];
    }
    
    final chapterMeta = index.chapters.firstWhere(
      (c) => c.chapter == chapter,
      orElse: () {
        if (kDebugMode || throwOnError) {
          throw LevelLoadException('Chapter $chapter not found in index');
        }
        return ChapterMetadata(
          chapter: chapter,
          gridSize: 4,
          levelCount: 0,
          difficultyLabel: 'Unknown',
          file: 'chapter_${chapter.toString().padLeft(2, '0')}.json',
        );
      },
    );
    
    try {
      final jsonString = await rootBundle.loadString('assets/levels/${chapterMeta.file}');
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Validate schema
      if (json['levels'] == null || json['levels'] is! List) {
        final error = 'Invalid chapter JSON schema: missing or invalid "levels" field';
        if (kDebugMode || throwOnError) {
          throw LevelLoadException('Failed to load chapter $chapter: $error');
        }
        debugPrint('[LEVELS] Chapter $chapter: $error');
        return [];
      }
      
      final levelsJson = json['levels'] as List;
      
      // Parse levels with error handling
      final levels = <LoadedLevel>[];
      for (int i = 0; i < levelsJson.length; i++) {
        try {
          final levelJson = levelsJson[i] as Map<String, dynamic>;
          levels.add(LoadedLevel.fromJson(levelJson));
        } catch (e) {
          final error = 'Failed to parse level $i in chapter $chapter: $e';
          if (kDebugMode) {
            throw LevelLoadException(error);
          }
          debugPrint('[LEVELS] $error');
          // Skip invalid level in release
        }
      }
      
      return levels;
    } on PlatformException catch (e) {
      final error = 'Failed to load chapter $chapter file: ${e.message}';
      if (kDebugMode || throwOnError) {
        throw LevelLoadException(error);
      }
      debugPrint('[LEVELS] $error');
      return [];
    } on FormatException catch (e) {
      final error = 'Invalid JSON in chapter $chapter: ${e.message}';
      if (kDebugMode || throwOnError) {
        throw LevelLoadException(error);
      }
      debugPrint('[LEVELS] $error');
      return [];
    } catch (e) {
      final error = 'Unexpected error loading chapter $chapter: $e';
      if (kDebugMode || throwOnError) {
        throw LevelLoadException(error);
      }
      debugPrint('[LEVELS] $error');
      return [];
    }
  }
  
  /// Load a specific level
  /// Returns null in release on error, throws in debug
  static Future<LoadedLevel?> loadLevel(int chapter, int level, {bool throwOnError = true}) async {
    final levels = await loadChapter(chapter, throwOnError: throwOnError);
    if (levels.isEmpty) {
      if (throwOnError) {
        throw LevelLoadException('Cannot load level $level from Chapter $chapter: chapter not available');
      }
      return null;
    }
    
    try {
      return levels.firstWhere((l) => l.level == level);
    } catch (e) {
      final error = 'Level $level not found in Chapter $chapter (available: ${levels.map((l) => l.level).join(", ")})';
      if (kDebugMode || throwOnError) {
        throw LevelLoadException(error);
      }
      debugPrint('[LEVELS] $error');
      return null;
    }
  }
  
  /// Runtime verification: Check that level packs are valid
  /// Logs summary in debug, returns verification result
  static Future<LevelVerificationResult> verifyLevelPacks() async {
    if (_verificationComplete) {
      return LevelVerificationResult(success: true, message: 'Already verified');
    }
    
    try {
      final index = await loadIndex(throwOnError: true);
      if (index == null) {
        return LevelVerificationResult(
          success: false,
          message: 'Failed to load index.json',
        );
      }
      
      int totalLevels = 0;
      final chapterCounts = <int, int>{};
      
      for (final chapterMeta in index.chapters) {
        final levels = await loadChapter(chapterMeta.chapter, throwOnError: false);
        chapterCounts[chapterMeta.chapter] = levels.length;
        totalLevels += levels.length;
        
        // Verify level count matches metadata
        if (levels.length != chapterMeta.levelCount) {
          if (kDebugMode) {
            debugPrint('[LEVELS] WARNING: Chapter ${chapterMeta.chapter} has ${levels.length} levels, but metadata says ${chapterMeta.levelCount}');
          }
        }
      }
      
      _verificationComplete = true;
      
      if (kDebugMode) {
        debugPrint('[LEVELS] Verification complete: ${index.chapters.length} chapters, $totalLevels total levels');
        for (final entry in chapterCounts.entries) {
          debugPrint('[LEVELS]   Chapter ${entry.key}: ${entry.value} levels');
        }
      }
      
      return LevelVerificationResult(
        success: true,
        message: 'Loaded ${index.chapters.length} chapters, $totalLevels levels',
        chapterCounts: chapterCounts,
        totalLevels: totalLevels,
      );
    } catch (e) {
      final error = 'Verification failed: $e';
      if (kDebugMode) {
        debugPrint('[LEVELS] ERROR: $error');
      }
      return LevelVerificationResult(
        success: false,
        message: error,
      );
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
    final givensViolations = GridValidator.validatePartialGrid(level.givens);
    if (givensViolations.isNotEmpty) {
      issues.add('Givens violations: ${givensViolations.map((v) => v.message).join(", ")}');
    }
    
    // 3. Solution validation (must be complete and valid)
    if (!GridValidator.isValidGrid(level.solution)) {
      final solutionViolations = GridValidator.validatePartialGrid(level.solution);
      if (solutionViolations.isNotEmpty) {
        issues.add('Solution invalid: ${solutionViolations.map((v) => v.message).join(", ")}');
      } else {
        issues.add('Solution invalid: Grid does not follow Takuzu rules');
      }
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

/// Verification result for level packs
class LevelVerificationResult {
  final bool success;
  final String message;
  final Map<int, int>? chapterCounts;
  final int? totalLevels;
  
  LevelVerificationResult({
    required this.success,
    required this.message,
    this.chapterCounts,
    this.totalLevels,
  });
}

