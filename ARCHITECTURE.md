# Architecture Documentation

## Overview

This document describes the architecture and core components of the Sun & Moon Puzzle game.

## Core Components

### 1. Puzzle Generator (`lib/core/utils/puzzle_generator.dart`)

The `PuzzleGenerator` class implements a backtracking algorithm to generate valid Takuzu/Binairo puzzles.

**Key Methods:**
- `generatePuzzle(int size)`: Generates a complete, valid puzzle solution
- `createPlayablePuzzle(int size, {double difficulty})`: Creates a playable puzzle by removing cells
- `generateDailyChallenge(int size)`: Generates a daily challenge puzzle seeded by date

**Usage:**
```dart
final generator = PuzzleGenerator(seed: 12345);
final puzzle = generator.generatePuzzle(6); // 6x6 grid
final playable = generator.createPlayablePuzzle(6, difficulty: 0.5);
```

**Algorithm:**
- Uses backtracking to fill cells one by one
- Validates each placement according to Takuzu rules
- Ensures no three consecutive same values
- Ensures equal counts of Suns and Moons
- Ensures unique rows and columns

### 2. Grid Validator (`lib/core/utils/grid_validator.dart`)

The `GridValidator` class validates puzzle grids according to all Takuzu/Binairo rules.

**Key Methods:**
- `isValidGrid(List<List<int>> grid)`: Validates a complete grid
- `validatePartialGrid(List<List<int>> grid)`: Validates a partial grid and returns violations

**Validation Rules:**
1. Equal number of Suns (1) and Moons (2) in every row and column
2. No more than two of the same symbol adjacent (horizontally or vertically)
3. No two rows can be identical
4. No two columns can be identical

**Usage:**
```dart
final isValid = GridValidator.isValidGrid(grid);
final violations = GridValidator.validatePartialGrid(grid);
```

### 3. Domain Models

All domain models use `freezed` for immutability and `json_serializable` for serialization.

**CellModel** (`lib/features/game/domain/models/cell_model.dart`):
- Represents a single cell in the puzzle
- Contains value (0=empty, 1=Sun, 2=Moon)
- Tracks if cell is given (pre-filled) or user-placed
- Supports pencil marks for note-taking
- Supports highlighting for hints

**PuzzleModel** (`lib/features/game/domain/models/puzzle_model.dart`):
- Represents a complete puzzle
- Contains solution grid and current state
- Tracks difficulty, seed, and metadata

**GameStatus** (`lib/features/game/domain/models/game_status.dart`):
- Tracks game state (playing, paused, completed)
- Tracks game mode (Zen, Speed Run, Daily)
- Tracks statistics (time, moves, hints)

**GameState** (`lib/features/game/domain/models/game_state.dart`):
- Combines PuzzleModel and GameStatus
- Contains undo/redo stacks

### 4. Game Repository (`lib/features/game/data/repositories/game_repository.dart`)

Handles puzzle generation and data operations.

**Key Methods:**
- `generatePuzzle(PuzzleDifficulty difficulty)`: Generates a new puzzle
- `generateDailyChallenge(PuzzleDifficulty difficulty)`: Generates daily challenge

## Folder Structure

```
lib/
├── main.dart                    # App entry point
├── core/                        # Core functionality
│   ├── theme/                   # AppTheme, Colors
│   ├── constants/               # Game constants
│   ├── utils/                   # Puzzle Generator, Validators
│   └── widgets/                 # Common UI components
└── features/                     # Feature modules
    ├── game/                    # Game feature
    │   ├── data/                # Repositories, Hive Adapters
    │   ├── domain/              # Models (PuzzleModel, CellModel)
    │   └── presentation/        # UI (Screens, Widgets, Controllers)
    ├── home/                    # Main menu
    ├── settings/                # Settings
    └── statistics/              # Statistics
```

## State Management

The app uses `flutter_riverpod` with code generation (`@riverpod`).

**Next Steps:**
1. Create Riverpod providers in `lib/features/game/presentation/controllers/game_controller.dart`
2. Use `@riverpod` annotation for providers
3. Generate code with `flutter pub run build_runner build`

## Code Generation

After creating models with `@freezed` and `@riverpod` annotations, run:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This will generate:
- `*.freezed.dart` files for models
- `*.g.dart` files for JSON serialization
- `*.config.dart` files for Riverpod providers

## Testing the Core Logic

See `lib/core/utils/puzzle_generator_test.dart` for example usage of the puzzle generator.

## Next Steps

1. ✅ Folder structure created
2. ✅ Core puzzle generator implemented
3. ✅ Grid validator implemented
4. ✅ Domain models created
5. ⏳ Implement Riverpod state management
6. ⏳ Build UI components
7. ⏳ Add features (hints, pencil mode, undo/redo)
8. ⏳ Add polish (animations, haptics, sound)

