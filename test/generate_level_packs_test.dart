import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sun_moon_puzzle/core/utils/level_generator.dart';
import 'package:sun_moon_puzzle/core/services/level_manager.dart';

/// Test file that also serves as level pack generator
/// Run with: flutter test test/generate_level_packs_test.dart
void main() {
  test('Generate level packs for chapters 1-4', () async {
    await _generateLevelPacks();
  });
}

Future<void> _generateLevelPacks() async {
  print('=== Building Level Packs (First 200 Levels) ===');
  print('Chapters: 1 to 4\n');

  final generator = LevelGenerator(seed: 42);
  final indexData = <String, dynamic>{
    'version': '1.0.0',
    'generatedAt': DateTime.now().toIso8601String(),
    'gitCommitHash': _getGitCommitHash(),
    'chapters': <Map<String, dynamic>>[],
  };

  int totalGenerated = 0;
  int totalFailed = 0;

  for (int chapter = 1; chapter <= 4; chapter++) {
    final levelsPerChapter = _getLevelsPerChapter(chapter);
    
    print('Generating Chapter $chapter ($levelsPerChapter levels)...');
    final chapterLevels = <Map<String, dynamic>>[];
    int chapterGenerated = 0;
    int chapterFailed = 0;
    
    for (int level = 1; level <= levelsPerChapter; level++) {
      try {
        final generatedLevel = generator.generateLevel(chapter, level);
        
        // Get mechanics for this level
        final mechanics = _getMechanicsForLevel(chapter, level);
        final params = _getParamsForLevel(chapter, level, mechanics);
        
        chapterLevels.add({
          'id': generatedLevel.id,
          'chapter': generatedLevel.chapter,
          'level': generatedLevel.level,
          'size': generatedLevel.size,
          'givens': generatedLevel.givens,
          'solution': generatedLevel.solution,
          'difficultyScore': generatedLevel.difficultyScore,
          'mechanics': mechanics.map((m) => m.toString().split('.').last).toList(),
          'params': params,
        });
        
        chapterGenerated++;
        if (level % 5 == 0) {
          print('  Level $level/$levelsPerChapter (Score: ${generatedLevel.difficultyScore.toStringAsFixed(2)}, Mechanics: ${mechanics.map((m) => m.toString().split('.').last).join(", ")})');
        }
      } catch (e) {
        chapterFailed++;
        print('  ✗ Failed to generate Level $level: $e');
        // Continue with next level
      }
    }
    
    // Save chapter JSON
    final chapterJson = jsonEncode({
      'chapter': chapter,
      'version': '1.0.0',
      'generatedAt': DateTime.now().toIso8601String(),
      'levels': chapterLevels,
    });
    
    final chapterFile = File('assets/levels/chapter_${chapter.toString().padLeft(2, '0')}.json');
    await chapterFile.create(recursive: true);
    await chapterFile.writeAsString(chapterJson);
    
    // Add to index
    final gridSize = _getGridSizeForChapter(chapter);
    indexData['chapters']!.add({
      'chapter': chapter,
      'gridSize': gridSize,
      'levelCount': chapterLevels.length,
      'difficultyLabel': _getDifficultyLabel(chapter),
      'file': 'chapter_${chapter.toString().padLeft(2, '0')}.json',
    });
    
    totalGenerated += chapterGenerated;
    totalFailed += chapterFailed;
    
    print('  ✓ Chapter $chapter: $chapterGenerated/$levelsPerChapter levels generated');
    if (chapterFailed > 0) {
      print('  ⚠  $chapterFailed levels failed');
    }
    print('');
  }
  
  // Save index
  final indexJson = jsonEncode(indexData);
  final indexFile = File('assets/levels/index.json');
  await indexFile.create(recursive: true);
  await indexFile.writeAsString(indexJson);
  
  print('=== Summary ===');
  print('Total generated: $totalGenerated levels');
  if (totalFailed > 0) {
    print('Total failed: $totalFailed levels');
  }
  print('Index saved to: ${indexFile.path}');
  print('Chapter files saved to: assets/levels/');
  
  // Verify
  print('\n=== Verification ===');
  final index = jsonDecode(await indexFile.readAsString()) as Map<String, dynamic>;
  final chapters = index['chapters'] as List;
  int totalLevels = 0;
  for (final ch in chapters) {
    final chMap = ch as Map<String, dynamic>;
    totalLevels += chMap['levelCount'] as int;
    print('Chapter ${chMap['chapter']}: ${chMap['levelCount']} levels (${chMap['gridSize']}x${chMap['gridSize']})');
  }
  print('Total chapters: ${chapters.length}');
  print('Total levels: $totalLevels');
  
  expect(chapters.length, 4, reason: 'Should have 4 chapters');
  expect(totalLevels, 200, reason: 'Should have 200 levels total');
}

int _getLevelsPerChapter(int chapter) {
  if (chapter == 1) return 10;
  if (chapter == 2) return 60;
  if (chapter == 3) return 70;
  if (chapter == 4) return 60;
  return 20;
}

int _getGridSizeForChapter(int chapter) {
  if (chapter == 1) return 4;
  if (chapter == 2) return 6;
  return 8;
}

String _getDifficultyLabel(int chapter) {
  if (chapter == 1) return 'Beginner Logic';
  if (chapter == 2) return 'Intermediate Logic';
  if (chapter == 3) return 'Advanced Logic';
  if (chapter == 4) return 'Expert Logic';
  return 'Master Logic';
}

List<String> _getMechanicsForLevel(int chapter, int level) {
  if (chapter == 1) {
    return ['classic'];
  }
  
  if (chapter == 2) {
    if (level <= 15) {
      return ['classic'];
    } else if (level <= 30) {
      return ['regions'];
    } else if (level <= 45) {
      return ['regions', 'lockedCells'];
    } else {
      return ['regions', 'lockedCells', 'advancedNoThree'];
    }
  }
  
  if (chapter == 3) {
    if (level <= 15) {
      return ['classic'];
    } else if (level <= 30) {
      return ['regions'];
    } else if (level <= 45) {
      return ['lockedCells', 'advancedNoThree'];
    } else if (level <= 60) {
      return ['regions', 'hiddenRule'];
    } else {
      return ['regions', 'lockedCells', 'advancedNoThree'];
    }
  }
  
  if (chapter == 4) {
    if (level <= 15) {
      return ['classic', 'moveLimit'];
    } else if (level <= 30) {
      return ['regions', 'moveLimit'];
    } else if (level <= 45) {
      return ['classic', 'advancedNoThree', 'mistakeLimit'];
    } else {
      return ['regions', 'lockedCells', 'advancedNoThree', 'mistakeLimit'];
    }
  }
  
  return ['classic'];
}

Map<String, dynamic> _getParamsForLevel(int chapter, int level, List<String> mechanics) {
  final params = <String, dynamic>{};
  
  for (final mechanic in mechanics) {
    if (mechanic == 'moveLimit') {
      final baseMoves = chapter == 2 ? 60 : (chapter == 3 ? 80 : 100);
      params['maxMoves'] = baseMoves - (level ~/ 5);
    } else if (mechanic == 'mistakeLimit') {
      params['maxMistakes'] = chapter >= 4 ? 3 : 5;
    } else if (mechanic == 'regions') {
      params['regionLayoutId'] = 'default';
    } else if (mechanic == 'lockedCells') {
      params['lockedCount'] = 0;
    } else if (mechanic == 'advancedNoThree') {
      params['patternLevel'] = 1;
    } else if (mechanic == 'hiddenRule') {
      params['revealAfterMistakes'] = 3;
    }
  }
  
  return params;
}

String _getGitCommitHash() {
  try {
    final result = Process.runSync('git', ['rev-parse', '--short', 'HEAD']);
    if (result.exitCode == 0) {
      return result.stdout.toString().trim();
    }
  } catch (e) {
    // Git not available or not a git repo
  }
  return 'unknown';
}

