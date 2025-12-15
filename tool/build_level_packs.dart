import 'dart:io';
import 'dart:convert';
import 'package:sun_moon_puzzle/core/utils/level_generator.dart';
import 'package:sun_moon_puzzle/core/services/level_manager.dart';

/// Build-time tool to generate level packs for release
/// 
/// Usage:
///   dart tool/build_level_packs.dart --chapters=1..5 --levelsPerChapter=20
/// 
/// Outputs:
///   - assets/levels/chapter_01.json ... chapter_05.json
///   - assets/levels/index.json (metadata)
void main(List<String> args) async {
  // Parse arguments
  int startChapter = 1;
  int endChapter = 5; // Chapters 1-5 (Master Spec)
  int? levelsPerChapterOverride;
  
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
      levelsPerChapterOverride = int.parse(arg.substring('--levelsPerChapter='.length));
    }
  }
  
  print('=== Building Level Packs (Master Spec) ===');
  print('Chapters: $startChapter to $endChapter\n');
  
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
    // Get levels per chapter based on LevelManager
    final levelsPerChapter = levelsPerChapterOverride ?? LevelManager.getLevelsPerChapter(chapter);
    
    print('Generating Chapter $chapter ($levelsPerChapter levels)...');
    final chapterLevels = <Map<String, dynamic>>[];
    int chapterGenerated = 0;
    int chapterFailed = 0;
    
    for (int level = 1; level <= levelsPerChapter; level++) {
      try {
        final generatedLevel = generator.generateLevel(chapter, level);
        
        chapterLevels.add(generatedLevel.toJson());
        
        chapterGenerated++;
        if (level % 5 == 0 || level == 1) {
          final mechanicsStr = generatedLevel.mechanics.map((m) => m.name).join(", ");
          print('  Level $level/$levelsPerChapter (Score: ${generatedLevel.difficultyScore.toStringAsFixed(2)}, Mechanics: [$mechanicsStr])');
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
    if (!await chapterFile.parent.exists()) {
      await chapterFile.parent.create(recursive: true);
    }
    await chapterFile.writeAsString(chapterJson);
    
    // Add to index
    // Use first level size as representative, or LevelManager
    final gridSize = LevelManager.getGridSizeForChapter(chapter, 1);
    
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

/// Get difficulty label for a chapter
String _getDifficultyLabel(int chapter) {
  if (chapter == 1) return 'Beginner (4x4)';
  if (chapter == 2) return 'Intermediate (6x6)';
  if (chapter == 3) return 'Advanced (6x6)';
  if (chapter == 4) return 'Expert (6x6)';
  if (chapter == 5) return 'Master (6x6)';
  return 'Custom';
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
