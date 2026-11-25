# Bose EQ Player

A Flutter music player with a real-time 3-band equalizer, built for the
Bose Professional *Software Development Intern – Frontend Applications* challenge.

> **Status: work in progress.** The equalizer engine is built and verified on a
> physical device. The player UI, track playback and device file picking are
> not implemented yet. See the checklist below for exactly what works today.

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
| Play bundled tracks or tracks picked from the device | Not implemented yet |
| Play / pause, seek, next, previous | Not implemented yet |
| Show track name, elapsed time and total duration | Not implemented yet |
| Three EQ bands (Low, Mid, High), each with a slider | Controller done; styled UI not built yet |
| EQ audibly changes the sound in real time | Verified on device |
| Reset EQ restores a flat response | Implemented; verification pending |
| Clearly documented target platform | Done (this file) |
| Demo video (5 minutes or less) | Not recorded yet |

## Packages

| Package | Purpose | Used in code yet? |
|---|---|---|
| `just_audio` | Playback and the Android equalizer effect | Yes (equalizer) |
| `audio_session` | Audio focus: phone calls, headphone unplug | Installed, not wired up yet |
| `file_picker` | Choose tracks from device storage via the system picker | Installed, not wired up yet |

Fonts (Space Grotesk and Inter, from Google Fonts) are bundled as assets rather
than fetched at runtime, so the app renders identically offline. See each
font's license on Google Fonts.

No state-management package is used. State is held in plain `ChangeNotifier`
classes consumed with `ListenableBuilder`.

## Architecture

```
lib/
  main.dart                       # currently a temporary EQ test harness
  core/theme/                     # colour palette, text styles, ThemeData
  audio/
    equalizer_controller.dart     # 3-band EQ logic (no UI)
assets/
  audio/                          # bundled tracks (to be added, licensed)
  fonts/                          # Space Grotesk, Inter
```

The separation of concerns:

- **UI** only talks to controllers and never imports `just_audio` directly.
- **`audio/`** is the only place that touches `just_audio`.
- **`EqualizerController`** owns the three slider values and applies them to the hardware.

A playback engine, a player controller, and the player and EQ screens are planned
and will be added in `lib/audio/` and `lib/features/`.

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
is the leading hypothesis. See `docs/NOTES.md` for the experiment log.

**Device not starting flat.** See "Flat start and reset" above.

## Run instructions

Requirements: Flutter SDK, Android Studio, an Android device with USB debugging
enabled (a physical device is recommended for judging the equalizer).

```bash
git clone https://github.com/<your-username>/bose-eq-player.git
cd bose-eq-player
flutter pub get
flutter run
```

Place a test track at `assets/audio/test.mp3` (it is not committed to this repository).
Use headphones to hear equalizer changes clearly.

## AI tools used

- **Claude (Anthropic)** was used as a mentor and pair programmer: requirements
  analysis, package and platform research, architecture planning, code drafts
  and debugging help. Package capabilities were checked against official
  documentation, and all code was run and tested by the author on a physical device.



## Credits

Bundled audio tracks and their licenses will be listed here when added.
