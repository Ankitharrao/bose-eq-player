# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Flutter music player with a real-time 3-band (Low/Mid/High) equalizer, built for a Bose Professional frontend intern challenge. **Android only**: the EQ is Android's native `Equalizer` audio effect via `just_audio`'s `AndroidEqualizer`, which `just_audio` supports on no other platform. Primary test device: Samsung SM-S911B, Android 14. EQ behaviour must be judged by ear on a physical device; emulators are not a meaningful check.

`README.md` is a deliverable for the challenge (requirements checklist, EQ write-up, known issues). `docs/NOTES.md` is a dated log of decisions and experiments that feeds the README's "Challenges" section. When a feature lands or an experiment runs, update both.

## Commands

```bash
flutter pub get
flutter run                      # needs a connected Android device
flutter analyze                  # lints: package:flutter_lints/flutter.yaml
flutter test
flutter test test/foo_test.dart  # single file
flutter test --plain-name "name" # single test by name
flutter run --dart-define=EQ_COMPARE=true  # shows the EQ write-mode picker for crackle tests
```

Bundled tracks live in `assets/audio/` (`test.mp3`, `test2.mp3`, listed in `lib/data/track.dart`). They are local placeholders and are not committed.

## Architecture

The layers are strict:

- **`lib/audio/`** is the only code that imports `just_audio`. UI never touches it directly.
  - `AudioEngine` (`ChangeNotifier`) owns the `AudioPlayer`, the track list and current index. It creates the `AndroidEqualizer` and puts it in the player's `AudioPipeline`. Commands (`play`, `seek`, `next`, ...) are fire-and-forget through `_fire`, which logs failures. Position, duration and playing state come back as streams. Load errors go to the `error` `ValueNotifier`. A `_loadToken` lets a newer track load cancel an older one. Pressing previous after 3 s restarts the current track. When a track completes, playback auto-advances.
  - `EqualizerController` (`ChangeNotifier`) takes `engine.equalizer`. It keeps a `_target` gain per slider (what the UI shows) and an `_applied` gain (what the hardware has), and `setGain` only moves the slider. The hardware is written once on drag end (`commit()`), because writing during a drag crackles (see NOTES). `reset()` bumps `_epoch` to cancel in-flight writes, then writes 0 dB to **every** hardware band.
- **`lib/features/`** holds the screens and widgets. They get the engine and controller through their constructors and rebuild with `ListenableBuilder` or `StreamBuilder`. No state-management package is used, and none should be added.
- **`lib/core/`** holds the theme (`AppColors`, `AppTextStyles`, `AppTheme.dark`), shared widgets such as `PressScale` (press-shrink feedback; wrap buttons with it and add `HapticFeedback`), and helpers such as `format_duration.dart`. Stick to the ink/paper/lime palette: use tints and alpha of those colours, never new hues.
- **`main.dart`** builds `AudioEngine` and then `EqualizerController`, awaits `engine.init()` (which loads track 0) **before** `eq.init()`, and passes both into `BoseApp` → `PlayerScreen`. Keep this order: the equalizer is initialised after the first track loads.

### Widget conventions

- Split UI into separate widget classes (e.g. private `_TopBar`, `_WideLayout`, `_EmptyState` in `player_screen.dart`). Don't use helper methods that return `Widget`, like `Widget _buildHeader()`. Widget classes get their own `BuildContext` and `const` constructors, so Flutter can skip rebuilding them. They also show up in DevTools.
- Mark widgets `const` wherever possible. Pass in only the data a widget needs.
- Put reusable or larger pieces in `lib/features/<feature>/widgets/`, one widget per file. Keep small, single-use widgets private in the screen file.

### EQ invariants (non-obvious, device-verified)

- Hardware band count and frequencies vary by device. Sliders map to hardware bands **by centre frequency** (Low < 500 Hz, Mid < 2000 Hz, High ≥ 2000 Hz), not by index. On the test device that gives Low = bands 0+1, Mid = band 2, High = bands 3+4.
- The device does not start flat (bands 0 and 4 read +3 dB at startup), so init must call `reset()`.
- The gain range comes from the device at runtime. If init fails, `isAvailable` is false and the UI must show an "EQ unavailable" state.
- Crackle while dragging: coalescing updates and gain ramping did not fix it. The current fix writes to the hardware only on release (still to be checked by ear). Do not reintroduce writes inside `onChanged`. The experiment log is in `docs/NOTES.md`.

## Status / next steps (from docs/NOTES.md)

The playback engine, player screen, EQ panel (bottom sheet in `lib/features/equalizer/`) are built. Device file picking (`lib/data/device_tracks.dart`, `lib/features/library/`) is built; picked files are cache copies, so play them with `setFilePath`. Audio focus and unplugging are handled by `AudioFocusHandler` (`lib/audio/audio_focus.dart`), wired to `audio_session` in `AudioEngine._initSession`; just_audio's own `handleInterruptions` is off, so don't re-enable it. Internal pauses/plays must bypass the public `play()`/`pause()`, which cancel a pending auto-resume. Still to do: licensed tracks with credits in the README.
