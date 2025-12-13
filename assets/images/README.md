# Image Assets

This directory contains SVG icons for the game.

## Files

- `sun.svg` - Sun icon (Orange #FF8C42)
- `moon.svg` - Moon/Crescent icon (Blue #4A90E2)

## Usage

These SVG files can be used with `flutter_svg` package:

```dart
import 'package:flutter_svg/flutter_svg.dart';

SvgPicture.asset('assets/images/sun.svg')
SvgPicture.asset('assets/images/moon.svg')
```

## Notes

- Currently, the app uses Material Icons as fallback
- SVG files are ready for future use
- Colors match the app theme exactly

