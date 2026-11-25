# Bose EQ Player

A Flutter music player with a real-time 3-band equalizer, built for the
Bose Professional *Software Development Intern – Frontend Applications* challenge.

> **Status: work in progress.** Implemented: playback of bundled tracks and
> tracks picked from the device, a queue where device tracks can be removed,
> the player screen (swipe gestures, animated wavy seek bar), the EQ sheet
> (three sliders, presets and a response curve), and audio focus handling
> (phone calls, other apps, headphone unplugging). The equalizer engine is
> verified on a physical device; the latest UI, the crackle fix, file picking,
> track removal and audio focus still need checking on the device. See the
> checklist below for exactly what works today.

## Target platform

**Android only.**

The equalizer uses Android's platform `Equalizer` audio effect, exposed through
`just_audio`'s `AndroidEqualizer`. The `just_audio` platform-support table lists
the equalizer for Android and for no other platform, so Android is the target.
The project was created for Android only and has not been tested on iOS, web or desktop.

Tested by ear on one device: **Samsung SM-S911B, Android 14**.

## Requirements checklist

| Requirement | Status |
|---|---|
| Play bundled tracks or tracks picked from the device | Done (device picking not yet checked on device) |
| Play / pause, seek, next, previous | Done |
| Show track name, elapsed time and total duration | Done |
| Three EQ bands (Low, Mid, High), each with a slider | Done (EQ sheet, plus presets and a response curve); not yet re-checked on device |
| EQ audibly changes the sound in real time | Verified on device |
| Reset EQ restores a flat response | Implemented; verification pending |
| Audio focus: pause for calls and other apps, pause on headphone unplug (extra) | Done, unit-tested; not yet checked on device |
| Clearly documented target platform | Done (this file) |
| Demo video (5 minutes or less) | Not recorded yet |

## Packages

| Package | Purpose | Used in code yet? |
|---|---|---|
| `just_audio` | Playback and the Android equalizer effect | Yes |
| `audio_session` | Audio focus: phone calls, headphone unplug | Yes |
| `file_picker` | Choose tracks from device storage via the system picker | Yes |
| `path_provider` | Locate the app cache, so removing a track deletes only its cached copy | Yes |

Fonts (Space Grotesk and Inter, from Google Fonts) are bundled as assets rather
than fetched at runtime, so the app renders identically offline. See each
font's license on Google Fonts.

No state-management package is used. State is held in plain `ChangeNotifier`
classes consumed with `ListenableBuilder`.

## Architecture

```
lib/
  main.dart                       # creates the audio engine and EQ, then runs the app
  app.dart                        # MaterialApp and theme
  core/
    theme/                        # colour palette, text styles, ThemeData
    widgets/press_scale.dart      # shared press-shrink feedback for buttons
    format_duration.dart          # mm:ss / h:mm:ss time labels
  data/
    track.dart                    # Track model and the bundled track list
    device_tracks.dart            # system file picker -> tracks
  audio/
    audio_engine.dart             # player, track list, next/previous, errors
    audio_focus.dart              # rules for calls, other apps, unplugging
    equalizer_controller.dart     # 3-band EQ logic (no UI)
  features/player/
    player_screen.dart            # now-playing screen (phone and wide layouts)
    widgets/                      # swipeable artwork, track dots, seek bar,
                                  # transport controls, "up next" card
  features/equalizer/
    eq_panel.dart                 # EQ bottom sheet: curve, presets, sliders, Reset
    eq_presets.dart               # Flat, Bass, Vocal, Treble, Warm
    widgets/                      # band slider, response curve, top-bar EQ pill
  features/library/
    add_music_button.dart         # "+" button / empty-state button for picking
    queue_sheet.dart              # track list; remove device tracks
test/                             # widget tests
assets/
  audio/                          # bundled tracks (placeholders, not committed)
  fonts/                          # Space Grotesk, Inter
```

The separation of concerns:

- **UI** only talks to controllers and never imports `just_audio` directly.
- **`audio/`** is the only place that touches `just_audio`.
- **`AudioEngine`** owns the `just_audio` player, the track list and the
  equalizer effect. UI commands (play, pause, seek, next, previous) never
  throw: failures are logged, and load errors are shown in an on-screen banner.
  "Previous" restarts the current track if it has played for more than 3
  seconds. When a track ends, the next one starts.
- **`EqualizerController`** owns the three slider values and applies them to
  the hardware. Moving a slider only updates the UI; the hardware is written
  when the slider is released (see "Challenges"). Presets set all three
  sliders at once.
- **`features/player/`** listens to the engine with `ListenableBuilder` and
  `StreamBuilder`. Widgets are split into small classes rather than
  build-helper methods. The layout switches to artwork beside the controls at widths of 720 px and up.

**Device file picking.** The "+" button opens Android's system picker
(Storage Access Framework) filtered to audio, with multi-select. The picker
copies each chosen file into the app's cache and hands back that copy's path,
so the app needs no storage permission. Removing a device track from the
queue deletes only that cache copy; the original file on the phone is never
touched. Bundled tracks cannot be removed. Picked tracks are appended to the list
and the first one starts playing; they are labelled "From device". They are
not remembered after the app is closed.

**Audio focus and headphones.** At startup the app declares itself a music
player to Android (`AudioSessionConfiguration.music()`), and playback requests
audio focus. `AudioFocusHandler` applies these rules:

| Event | What happens |
|---|---|
| Headphones unplugged or Bluetooth disconnected | Pause, with a "headphones disconnected" message. No auto-resume. |
| Short interruption (e.g. a phone call) | Pause, then resume when it ends, unless the user pressed play/pause meanwhile |
| Another app starts playing music | Pause for good, with a message |
| Short "duck" request (e.g. a navigation prompt) | Left to Android, which lowers media volume itself on Android 8+ |

just_audio's built-in interruption handling is turned off so these rules live
in one place and are unit-tested (`test/audio_focus_test.dart`).

**Seek bar.** A standard Material slider with a custom track shape
(`wavy_track_shape.dart`): the played part is a small sine wave that flows
while audio plays and eases flat when paused, while dragging, or when the
system "remove animations" setting is on.

## Using the app

| Gesture | Where | Does |
|---|---|---|
| Swipe left / right | Artwork | Next / previous track |
| Tap | Artwork | Play / pause |
| Tap a dot | Under the artwork | Jump to that track |
| Tap | "Up next" card | Skip to the next track |
| Tap "+" | Top bar | Add audio files from the device |
| Tap the queue button | Top bar | Open the track list; tap a track to play it |
| Tap the trash icon, or swipe left | Queue | Remove a track added from the device |
| Drag or tap | Seek bar | Seek |
| Tap the EQ pill, or swipe up on "Swipe up for EQ" | Top bar / bottom of the screen | Open the equalizer |
| Tap a preset | EQ sheet | Flat, Bass, Vocal, Treble or Warm |
| Double-tap a dB value | EQ sheet | Reset that band to 0 dB |

The EQ pill's three mini bars mirror the current Low / Mid / High gains. The
curve in the EQ sheet is an illustration of the slider settings, not a
measurement of the device's filters. Controls give haptic feedback, and the
artwork's motion stops when the system "remove animations" setting is on.

## EQ implementation

The EQ is **not simulated**. It is Android's native `Equalizer` audio effect,
attached to the player's audio pipeline and controlled per frequency band.

**Hardware bands.** The number and frequencies of bands are chosen by the device.
The test device reports five bands over a −15 to +15 dB range:

| Band | Range | Centre |
|---|---|---|
| 0 | 30–120 Hz | 60 Hz |
| 1 | 120–460 Hz | 230 Hz |
| 2 | 460–1800 Hz | 910 Hz |
| 3 | 1800–7000 Hz | 3600 Hz |
| 4 | 7000–20000 Hz | 14000 Hz |

**Mapping five bands to three sliders.** Each slider controls a group of hardware
bands, assigned by centre frequency rather than by index so it stays correct on
devices with a different number of bands:

| Slider | Rule | On the test device |
|---|---|---|
| Low | centre below 500 Hz | bands 0 and 1 |
| Mid | 500–2000 Hz | band 2 |
| High | above 2000 Hz | bands 3 and 4 |

Because Mid maps to a single hardware band, its range is narrower than Low or
High. Neighbouring bands also overlap slightly, so the three sliders are not
perfectly isolated.

**Flat start and reset.** On the test device the equalizer did **not** start
flat: bands 0 and 4 reported +3 dB before any gain was set. The controller
therefore writes 0 dB to every hardware band on startup, and Reset does the
same, so a flat response never depends on the device's initial state.

**Limits.** The gain range is read from the device at runtime. If the device
has no usable equalizer, the controller reports `isAvailable == false` so the
UI can show an "EQ unavailable" state instead of crashing.

## Challenges and known issues

**Audible crackle while dragging an EQ slider (open).** On the test device,
dragging a slider produces a crackling sound during movement. It does **not**
occur when a slider is held still, including at high boosts, and does not occur
with all sliders untouched. Two mitigations have been tried and neither removed it:

1. Coalescing updates so only the latest value per slider is sent to the phone.
2. Ramping the hardware gain towards the target in small steps.

The cause has not been confirmed. Zipper noise from abrupt filter-gain changes
is the leading hypothesis.

Current fix (verification by ear pending): the hardware is no longer written
during a drag. The slider moves freely and the new gain is applied once when the
finger lifts, so the sound changes on release rather than continuously.

To compare write strategies by ear, run with
`flutter run --dart-define=EQ_COMPARE=true`. The EQ sheet then shows a picker:
Release (default), every 200 ms, every 100 ms, or on every movement. See
`docs/NOTES.md` for the experiment log.

**Device not starting flat.** See "Flat start and reset" above.

## Run instructions

Requirements: Flutter SDK, Android Studio, an Android device with USB debugging
enabled (a physical device is recommended for judging the equalizer).

```bash
git clone https://github.com/Ankitharrao/bose-eq-player.git
cd bose-eq-player
flutter pub get
flutter run            # add --release for the most accurate audio behaviour
flutter test           # widget tests
```

Place two test tracks at `assets/audio/test.mp3` and `assets/audio/test2.mp3`
(they are not committed to this repository; the list lives in `lib/data/track.dart`).
Use headphones to hear equalizer changes clearly.

## AI tools used

- **Claude (Anthropic)** was used as a mentor and pair programmer: requirements
  analysis, package and platform research, architecture planning, code drafts
  and debugging help. Package capabilities were checked against official
  documentation, and all code was run and tested by the author on a physical device.

## Credits

Bundled audio tracks and their licenses will be listed here when added.
