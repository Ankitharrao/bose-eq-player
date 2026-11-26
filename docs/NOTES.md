# Engineering notes

A running log of decisions and experiments. Feeds the README's "Challenges" section.

## 2026-11-25

### Package and platform check
- `just_audio` lists equalizer support for Android only. iOS, macOS, web, Windows and Linux are not supported.
- Decision: target Android only. The EQ is Android's native `Equalizer` effect, not a simulation.

### EQ spike (throwaway screen, one test track)
- Boosting the lowest hardware band during playback changed the sound immediately, with no track restart.
- Setting that band back to 0 dB returned it to normal.

### Device facts (Samsung SM-S911B, Android 14)
- Five hardware bands, centres 60, 230, 910, 3600 and 14000 Hz. Range −15 to +15 dB.
- Bands 0 and 4 reported +3 dB at startup, so the device does not start flat.
- Decision: write 0 dB to every band on init, and make Reset do the same.
- 2026-11-26: Reset verified on device; it restores a flat response.

### Mapping decision
- Group hardware bands into Low / Mid / High by centre frequency (below 500 Hz, up to 2000 Hz, above), not by index, so the mapping holds on devices with a different band count.

### Crackle while dragging sliders (open)
- Symptom: crackle only while a slider is moving. None when held still at high boost, none untouched.
- Attempt 1, coalescing updates (latest value wins): no change.
- Attempt 2, ramping the hardware gain toward the target at 0.75 dB per 20 ms: no change.
- Not yet tried: applying the gain only when the finger lifts, smaller step sizes, a release build.
- Cause unconfirmed. Zipper noise is the leading hypothesis.
- Attempt 3, apply on release: sliders move freely in the UI and the hardware is written once, when the finger lifts (one `setGain` per hardware band, no ramp). The ramp from attempt 2 was removed because it adds a write every 20 ms. Trade-off: the sound changes on release, not during the drag. Result by ear (2026-11-26): no crackle; this is the shipped behaviour.
- 2026-11-26, write modes compared by ear (profile build, Three Bands, headphones, Low and High dragged slowly and quickly): Release clean; 200 ms slight crackle; 100 ms worse; Live crackles. Crackle scales with write rate (zipper noise). Decision: keep Release as the default; a throttled live mode is not clean enough to ship.
- 2026-11-26 (review feedback): README now states precisely that a drag updates the UI continuously but writes the native gain on release, while taps, presets, Reset and double-tap apply immediately; the trade-off was judged acceptable by ear on the device.
- Comparison aid: run with `flutter run --profile --dart-define=EQ_COMPARE=true` (blocked in release builds since 2026-11-26) to show a picker in the EQ sheet: Release (default), 200 ms, 100 ms, Live (every movement).

### Device file picking
- `file_picker` 13 on Android uses the Storage Access Framework; by default it copies each picked file into the app cache and returns a `file://` path, so `setFilePath` works and no storage permission is needed.
- Picked tracks are appended and the first plays. Not persisted across restarts (cache copies may be cleared by the OS).
- 2026-11-26: picked tracks vanished after closing the app, and the cache copies doubled the space each track used. Replaced `file_picker` with a platform channel in `MainActivity.kt`: `ACTION_OPEN_DOCUMENT` plus `takePersistableUriPermission`, so the app keeps the original file's `content://` URI and plays it in place (no copy). `DeviceLibrary` saves the list in `shared_preferences`; on launch it drops entries whose permission is gone and releases grants no entry uses. Removal releases the grant. Duplicate picks are skipped. Old `cache/file_picker` copies are deleted at startup. Release APK builds. Result on device: working; tracks survive closing the app.

### Audio focus and headphone unplugging
- just_audio handles interruptions by default, but silently and only after configuring the session on first play.
- Decision: configure `AudioSessionConfiguration.music()` at startup, turn off `handleInterruptions`, and apply our own rules in `AudioFocusHandler` (pure, unit-tested). The UI shows a message when unplugging or another app stops playback.
- Ducking is left to Android (automatic for media on 8+), as just_audio also does for media usage.
- Result on device: working (tested 2026-11-26).

### Removing device tracks, and the seek bar
- Queue sheet lists all tracks; device tracks can be removed (trash or swipe). Bundled assets cannot. Removal forgets the track and releases its URI permission (originally: deleted the picker's cache copy).
- When the last track is removed the player pauses rather than stops, so the equalizer effect in the pipeline survives.
- Tried a waveform seek bar with `just_waveform`, then reverted it in favour of a simpler Material slider whose played part is an animated wave while playing (custom `WavyTrackShape`). The hand-built waveform control also needed its own screen-reader semantics, which had caused an assertion; a real `Slider` gets them from Flutter.
- Result on device (2026-11-26): removal and the wavy seek bar work.

### Bundled track
- 2026-11-26: the two bundled test tracks were local files of unknown licence, not committed, so a fresh clone had no audio. Replaced them with "Three Bands", an original 61 s track synthesized by `tool/make_demo_track.py` (standard-library Python, fixed seed) and encoded to AAC with macOS `afconvert` (1.1 MB). Released as CC0. Kick and bass sit in the Low band, the chord pad in Mid, and hats and bells in High, so each slider is audible. `pubspec.yaml` lists the file rather than the folder, so untracked local audio is never bundled.

## To do next
- 2026-11-26: everything above verified on the device in a release build.
- Record the demo video (5 minutes or less).
