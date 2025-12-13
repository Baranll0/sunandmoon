# Audio Assets

This directory contains the audio files for game sound effects:

## Current Files

- `mouseclick1.ogg` - Sound for normal cell taps (volume: 0.3)
- `mouserelease1.ogg` - Sound for invalid moves/errors (volume: 0.4)
- `rollover6.ogg` - Sound for puzzle completion (volume: 0.6)
- `switch1.ogg` - Sound for undo/redo actions (volume: 0.3)
- `rollover1.ogg` - Sound for hint usage (volume: 0.3)

## File Mapping

- **Tıklama sesi**: `mouseclick1.ogg` → `playTap()`
- **Hata sesi**: `mouserelease1.ogg` → `playError()`
- **Kazanma sesi**: `rollover6.ogg` → `playWin()`
- **Geri alma sesi**: `switch1.ogg` → `playUndo()`
- **İpucu sesi**: `rollover1.ogg` → `playHint()`

## Notes

- All audio files are in OGG format (web compatible)
- Volume levels are pre-configured in `SoundService`
- The app will work without these files (silent failure)
- All sounds are designed to be subtle and relaxing (Zen theme)

