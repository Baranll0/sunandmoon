# Sun & Moon Puzzle

A production-ready, highly polished logic puzzle game based on Takuzu/Binairo rules, built with Flutter.

## Features

- **Smart Puzzle Generation**: Backtracking algorithm generates valid puzzles on-the-fly
- **Multiple Difficulty Levels**: 6x6 (Easy), 8x8 (Medium), 10x10 (Hard), 12x12 (Expert)
- **Smart Hint System**: Highlights violating rows/columns to teach players
- **Pencil Mode**: Draft candidate values without committing
- **Unlimited Undo/Redo**: Full history support
- **Game Modes**: Zen Mode, Speed Run, Daily Challenge
- **Polished UI**: Minimalist "Paper & Ink" aesthetic with smooth animations
- **Haptics & Sound**: Tactile feedback and soothing sound effects

## Architecture

- **Framework**: Flutter (Latest Stable)
- **State Management**: flutter_riverpod with code generation
- **Immutability**: freezed & json_serializable
- **Navigation**: go_router
- **Local Storage**: hive & shared_preferences
- **Assets**: flutter_svg for crisp, scalable icons

## Project Structure

```
lib/
├── main.dart
├── core/
│   ├── theme/          # AppTheme, Colors
│   ├── constants/      # Game constants
│   ├── utils/          # Puzzle Generator, Grid Validator
│   └── widgets/        # Common UI components
└── features/
    ├── game/           # Game feature
    │   ├── data/       # Repositories, Hive Adapters
    │   ├── domain/      # Models (PuzzleModel, CellModel, GameStatus)
    │   └── presentation/
    │       ├── controllers/  # Riverpod providers
    │       ├── screens/      # GameScreen
    │       └── widgets/      # GridBoard, CellWidget, etc.
    ├── home/           # MainMenu, LevelSelector
    ├── settings/       # Settings screen
    └── statistics/     # Statistics screen
```

## Getting Started

1. Install dependencies:
```bash
flutter pub get
```

2. Generate code (freezed, json_serializable, riverpod):
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

3. Run the app:
```bash
flutter run
```

## Game Rules

1. **Equal Counts**: Every row and column must have an equal number of Suns (1) and Moons (2)
2. **No Three Consecutive**: No more than two of the same symbol can be adjacent (horizontally or vertically)
3. **Unique Rows/Columns**: No two rows can be identical, and no two columns can be identical

## License

This project is proprietary and confidential.

