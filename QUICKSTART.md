# Quick Start Guide

## Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK (comes with Flutter)
- Android Studio / VS Code with Flutter extensions

## Setup Steps

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Generate Code

The project uses code generation for:
- `freezed` (immutable models)
- `json_serializable` (JSON serialization)
- `riverpod_generator` (state management)

Run the code generator:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Note:** You may see warnings about missing generated files initially. This is expected - the generator will create them.

### 3. Run the App

```bash
flutter run
```

## Project Status

### ✅ Completed

1. **Folder Structure**: Complete feature-first architecture
2. **Core Logic**:
   - ✅ Puzzle Generator (backtracking algorithm)
   - ✅ Grid Validator (all Takuzu rules)
   - ✅ Constraint Validator (for advanced levels)
   - ✅ Grid Helper utilities
3. **Domain Models**:
   - ✅ CellModel (with freezed)
   - ✅ PuzzleModel (with freezed)
   - ✅ GameStatus (with freezed)
   - ✅ GameState (with freezed)
4. **Theme & Constants**:
   - ✅ AppTheme (Paper & Ink aesthetic)
   - ✅ Game Constants
5. **Repository**:
   - ✅ GameRepository (puzzle generation)

### ⏳ Next Steps

1. **State Management**: Implement Riverpod providers
2. **UI Components**: Build GameScreen, GridBoard, CellWidget
3. **Features**: Add hints, pencil mode, undo/redo
4. **Polish**: Add animations, haptics, sound

## Testing the Core Logic

You can test the puzzle generator by running:

```dart
import 'package:sun_moon_puzzle/core/utils/puzzle_generator.dart';
import 'package:sun_moon_puzzle/core/utils/grid_validator.dart';

void main() {
  final generator = PuzzleGenerator(seed: 12345);
  final puzzle = generator.generatePuzzle(6);
  
  print('Generated puzzle:');
  print(GridHelper.gridToString(puzzle));
  
  final isValid = GridValidator.isValidGrid(puzzle);
  print('Is valid: $isValid');
}
```

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed architecture documentation.

## Troubleshooting

### Code Generation Issues

If you encounter errors during code generation:

1. Clean the build cache:
```bash
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

2. Ensure all dependencies are up to date:
```bash
flutter pub upgrade
```

### Missing Generated Files

The first time you run the app, you'll need to generate the code. The `*.freezed.dart` and `*.g.dart` files are gitignored and will be generated automatically.

## Development Workflow

1. Make changes to models/controllers
2. Run code generation: `flutter pub run build_runner build --delete-conflicting-outputs`
3. Test your changes: `flutter run`
4. Check for linting errors: `flutter analyze`

