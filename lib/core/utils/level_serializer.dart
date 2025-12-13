import 'dart:convert';
import 'human_logic_solver.dart';
import 'level_generator.dart';

/// Serialization utilities for level import/export
class LevelSerializer {
  /// Parse a level from JSON string
  /// 
  /// Expected JSON format:
  /// {
  ///   "id": 19,
  ///   "chapter": 2,
  ///   "level": 4,
  ///   "size": 6,
  ///   "givens": [[...], [...]],
  ///   "solution": [[...], [...]],
  ///   "difficultyScore": 7.5,
  ///   "metrics": {...}
  /// }
  static GeneratedLevel? parseLevel(String jsonString) {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      
      // Validate required fields
      if (!json.containsKey('id') ||
          !json.containsKey('size') ||
          !json.containsKey('givens')) {
        return null;
      }
      
      final id = json['id'] as int;
      final chapter = json['chapter'] as int? ?? 1;
      final level = json['level'] as int? ?? 1;
      final size = json['size'] as int;
      final givens = (json['givens'] as List)
          .map((row) => (row as List).map((e) => e as int).toList())
          .toList();
      
      // Validate givens structure
      if (givens.length != size || givens.any((row) => row.length != size)) {
        return null;
      }
      
      // Parse solution (optional)
      List<List<int>>? solution;
      if (json.containsKey('solution')) {
        solution = (json['solution'] as List)
            .map((row) => (row as List).map((e) => e as int).toList())
            .toList();
        
        // Validate solution structure
        if (solution.length != size || solution.any((row) => row.length != size)) {
          solution = null;
        }
      }
      
      // Parse difficulty score (optional)
      final difficultyScore = (json['difficultyScore'] as num?)?.toDouble() ?? 0.0;
      
      // Parse metrics (optional)
      DifficultyMetrics? metrics;
      if (json.containsKey('metrics') && json['metrics'] is Map) {
        final metricsJson = json['metrics'] as Map<String, dynamic>;
        metrics = DifficultyMetrics()
          ..forcedMovesCount = metricsJson['forcedMovesCount'] as int? ?? 0
          ..branchingEventsCount = metricsJson['branchingEventsCount'] as int? ?? 0
          ..maxBranchDepth = metricsJson['maxBranchDepth'] as int? ?? 0
          ..backtracksCount = metricsJson['backtracksCount'] as int? ?? 0
          ..totalAssignments = metricsJson['totalAssignments'] as int? ?? 0
          ..firstBranchStepIndex = metricsJson['firstBranchStepIndex'] as int? ?? -1;
      } else {
        // Create default metrics if not provided
        metrics = DifficultyMetrics();
      }
      
      // If solution is missing, generate it (optional - can be computed later)
      if (solution == null) {
        // Note: In production, you might want to solve the puzzle here
        // For now, we'll leave it null and let the game solve it
        solution = List.generate(size, (_) => List.filled(size, 0));
      }
      
      return GeneratedLevel(
        id: id,
        chapter: chapter,
        level: level,
        size: size,
        givens: givens,
        solution: solution,
        difficultyScore: difficultyScore,
        metrics: metrics,
      );
    } catch (e) {
      // Invalid JSON or structure
      return null;
    }
  }
  
  /// Parse multiple levels from JSON array
  /// 
  /// Expected format: [{...}, {...}, ...]
  static List<GeneratedLevel> parseLevelPack(String jsonString) {
    try {
      final List<dynamic> jsonArray = jsonDecode(jsonString);
      final List<GeneratedLevel> levels = [];
      
      for (final item in jsonArray) {
        if (item is Map<String, dynamic>) {
          final level = parseLevel(jsonEncode(item));
          if (level != null) {
            levels.add(level);
          }
        }
      }
      
      return levels;
    } catch (e) {
      return [];
    }
  }
  
  /// Serialize a level to JSON string
  /// 
  /// Uses GeneratedLevel.toJson() internally
  static String serializeLevel(GeneratedLevel level) {
    return jsonEncode(level.toJson());
  }
  
  /// Serialize multiple levels to JSON array
  static String serializeLevelPack(List<GeneratedLevel> levels) {
    final List<Map<String, dynamic>> jsonArray = levels
        .map((level) => level.toJson())
        .toList();
    return jsonEncode(jsonArray);
  }
  
  /// Validate a level JSON string without parsing
  static bool isValidLevelJson(String jsonString) {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      
      // Check required fields
      if (!json.containsKey('id') ||
          !json.containsKey('size') ||
          !json.containsKey('givens')) {
        return false;
      }
      
      final size = json['size'] as int;
      if (size <= 0 || size % 2 != 0) {
        return false; // Size must be positive and even
      }
      
      final givens = json['givens'] as List?;
      if (givens == null || givens.length != size) {
        return false;
      }
      
      // Validate each row
      for (final row in givens) {
        if (row is! List || row.length != size) {
          return false;
        }
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
}

