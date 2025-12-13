# Level Packs Directory

This directory contains pre-generated level packs for release builds.

## Structure

- `index.json` - Metadata for all chapters (grid sizes, difficulty labels, file paths)
- `chapter_01.json` ... `chapter_15.json` - Individual chapter level data
- `golden_levels.json` - Hard-coded golden puzzles for regression testing

## Generating Level Packs

Use the build-time tool to generate level packs:

```bash
dart tool/build_level_packs.dart --chapters=1..15 --levelsPerChapter=20
```

This will:
1. Generate puzzles for each chapter using `LevelGenerator`
2. Save each chapter to `chapter_XX.json`
3. Create/update `index.json` with metadata

## Level Pack Format

### index.json
```json
{
  "version": "1.0.0",
  "generatedAt": "2025-12-13T04:35:00.000Z",
  "gitCommitHash": "abc123",
  "chapters": [
    {
      "chapter": 1,
      "gridSize": 4,
      "levelCount": 20,
      "difficultyLabel": "Beginner Logic",
      "file": "chapter_01.json"
    }
  ]
}
```

### chapter_XX.json
```json
{
  "chapter": 1,
  "version": "1.0.0",
  "generatedAt": "2025-12-13T04:35:00.000Z",
  "levels": [
    {
      "id": 1,
      "chapter": 1,
      "level": 1,
      "size": 4,
      "givens": [[...], [...]],
      "solution": [[...], [...]],
      "difficultyScore": 2.5
    }
  ]
}
```

## Runtime Loading

Use `LevelLoader` to load levels at runtime:

```dart
// Load index
final index = await LevelLoader.loadIndex();

// Load a chapter
final levels = await LevelLoader.loadChapter(1);

// Load a specific level
final level = await LevelLoader.loadLevel(1, 5);

// Validate a level (optional, expensive)
final validation = await LevelLoader.validateLevel(level, checkUniqueness: true);
```

## Golden Puzzles

`golden_levels.json` contains a curated set of puzzles for regression testing:
- 5 easy puzzles (score ~2-3)
- 5 medium puzzles (score ~5-6)
- 5 hard puzzles (score ~8-9)

These are used in `test/golden_puzzles_test.dart` to ensure difficulty scores remain stable.

## Notes

- Level packs are generated **offline** (build-time), not on-device
- Generation uses deterministic seeds for reproducibility
- Failed generations are logged but don't stop the build process
- Validation is optional at runtime (can be expensive for uniqueness checks)

