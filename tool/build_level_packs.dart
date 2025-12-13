import 'dart:io';
import 'dart:convert';
import 'package:sun_moon_puzzle/core/utils/level_generator.dart';

/// Build-time tool to generate level packs for release
/// 
/// Usage:
///   dart tool/build_level_packs.dart --chapters=1..15 --levelsPerChapter=20
/// 
/// Outputs:
///   - assets/levels/chapter_01.json ... chapter_15.json
///   - assets/levels/index.json (metadata)
void main(List<String> args) async {
  // Parse arguments
  int startChapter = 1;
  int endChapter = 15;
  int levelsPerChapter = 20;
  
  for (final arg in args) {
    if (arg.startsWith('--chapters=')) {
      final range = arg.substring('--chapters='.length);
      if (range.contains('..')) {
        final parts = range.split('..');
        startChapter = int.parse(parts[0]);
        endChapter = int.parse(parts[1]);
      } else {
        startChapter = endChapter = int.parse(range);
      }
    } else if (arg.startsWith('--levelsPerChapter=')) {
      levelsPerChapter = int.parse(arg.substring('--levelsPerChapter='.length));
    }
  }
  
  print('=== Building Level Packs ===');
  print('Chapters: $startChapter to $endChapter');
  print('Levels per chapter: $levelsPerChapter\n');
  
  final generator = LevelGenerator(seed: 42);
  final indexData = <String, dynamic>{
    'version': '1.0.0',
    'generatedAt': DateTime.now().toIso8601String(),
    'gitCommitHash': _getGitCommitHash(),
    'chapters': <Map<String, dynamic>>[],
  };
  
  int totalGenerated = 0;
  int totalFailed = 0;
  
  for (int chapter = startChapter; chapter <= endChapter; chapter++) {
    print('Generating Chapter $chapter...');
    final chapterLevels = <Map<String, dynamic>>[];
    int chapterGenerated = 0;
    int chapterFailed = 0;
    
    for (int level = 1; level <= levelsPerChapter; level++) {
      try {
        final generatedLevel = generator.generateLevel(chapter, level);
        
        chapterLevels.add({
          'id': generatedLevel.id,
          'chapter': generatedLevel.chapter,
          'level': generatedLevel.level,
          'size': generatedLevel.size,
          'givens': generatedLevel.givens,
          'solution': generatedLevel.solution,
          'difficultyScore': generatedLevel.difficultyScore,
        });
        
        chapterGenerated++;
        if (level % 5 == 0) {
          print('  Level $level/$levelsPerChapter (Score: ${generatedLevel.difficultyScore.toStringAsFixed(2)})');
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
  await indexFile.writeAsString(indexJson);
  
  print('=== Summary ===');
  print('Total generated: $totalGenerated levels');
  if (totalFailed > 0) {
    print('Total failed: $totalFailed levels');
  }
  print('Index saved to: ${indexFile.path}');
  print('Chapter files saved to: assets/levels/');
}

/// Get grid size for a chapter
int _getGridSizeForChapter(int chapter) {
  if (chapter <= 2) return 4;
  if (chapter <= 12) return 6;
  return 8;
}

/// Get difficulty label for a chapter
String _getDifficultyLabel(int chapter) {
  if (chapter == 1) return 'Beginner Logic';
  if (chapter <= 3) return 'Intermediate Logic';
  if (chapter <= 12) return 'Advanced Logic';
  return 'Expert Logic';
}

/// Get git commit hash if available
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

