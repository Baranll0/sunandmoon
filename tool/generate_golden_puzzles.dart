import 'dart:io';
import 'dart:convert';
import 'package:sun_moon_puzzle/core/utils/level_generator.dart';

/// Tool to generate golden puzzle set for regression testing
/// Generates puzzles and saves them as hard-coded JSON
/// 
/// Note: This tool must be run in Flutter context (use flutter run or test)
/// For now, we'll generate puzzles using LevelGenerator which already has
/// difficulty scores calculated during generation
void main() async {
  print('=== Generating Golden Puzzle Set ===\n');
  
  final generator = LevelGenerator(seed: 12345);
  final goldenPuzzles = <Map<String, dynamic>>>[];
  
  // Generate 5 easy puzzles (Chapter 1, levels 1-5)
  print('Generating Easy puzzles (Score ~2-3)...');
  for (int i = 1; i <= 5; i++) {
    try {
      final level = generator.generateLevel(1, i);
      // Use difficultyScore from GeneratedLevel (already calculated during generation)
      goldenPuzzles.add({
        'id': 'easy_$i',
        'category': 'easy',
        'expectedScoreMin': 2.0,
        'expectedScoreMax': 3.5,
        'size': level.size,
        'givens': level.givens,
        'solution': level.solution,
        'actualScore': level.difficultyScore,
      });
      print('  ✓ Easy $i: Score ${level.difficultyScore.toStringAsFixed(2)}');
    } catch (e) {
      print('  ✗ Failed to generate Easy $i: $e');
      // Continue with next puzzle
    }
  }
  
  // Generate 5 medium puzzles (Chapter 2, levels 1-5)
  print('\nGenerating Medium puzzles (Score ~5-6)...');
  for (int i = 1; i <= 5; i++) {
    try {
      final level = generator.generateLevel(2, i);
      goldenPuzzles.add({
        'id': 'medium_$i',
        'category': 'medium',
        'expectedScoreMin': 5.0,
        'expectedScoreMax': 6.5,
        'size': level.size,
        'givens': level.givens,
        'solution': level.solution,
        'actualScore': level.difficultyScore,
      });
      print('  ✓ Medium $i: Score ${level.difficultyScore.toStringAsFixed(2)}');
    } catch (e) {
      print('  ✗ Failed to generate Medium $i: $e');
    }
  }
  
  // Generate 5 hard puzzles (Chapter 4, levels 1-5, 6x6)
  print('\nGenerating Hard puzzles (Score ~8-9)...');
  for (int i = 1; i <= 5; i++) {
    try {
      final level = generator.generateLevel(4, i);
      goldenPuzzles.add({
        'id': 'hard_$i',
        'category': 'hard',
        'expectedScoreMin': 8.0,
        'expectedScoreMax': 9.5,
        'size': level.size,
        'givens': level.givens,
        'solution': level.solution,
        'actualScore': level.difficultyScore,
      });
      print('  ✓ Hard $i: Score ${level.difficultyScore.toStringAsFixed(2)}');
    } catch (e) {
      print('  ✗ Failed to generate Hard $i: $e');
    }
  }
  
  // Save to JSON
  final json = jsonEncode({
    'version': '1.0.0',
    'generatedAt': DateTime.now().toIso8601String(),
    'puzzles': goldenPuzzles,
  });
  
  final file = File('assets/levels/golden_levels.json');
  await file.create(recursive: true);
  await file.writeAsString(json);
  
  print('\n✓ Generated ${goldenPuzzles.length} golden puzzles');
  print('  Saved to: ${file.path}');
}
