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

### Mapping decision
- Group hardware bands into Low / Mid / High by centre frequency (below 500 Hz, up to 2000 Hz, above), not by index, so the mapping holds on devices with a different band count.

### Crackle while dragging sliders (open)
- Symptom: crackle only while a slider is moving. None when held still at high boost, none untouched.
- Attempt 1, coalescing updates (latest value wins): no change.
- Attempt 2, ramping the hardware gain toward the target at 0.75 dB per 20 ms: no change.
- Not yet tried: applying the gain only when the finger lifts, smaller step sizes, a release build.
- Cause unconfirmed. Zipper noise is the leading hypothesis.
- Attempt 3, apply on release: sliders move freely in the UI and the hardware is written once, when the finger lifts (one `setGain` per hardware band, no ramp). The ramp from attempt 2 was removed because it adds a write every 20 ms. Trade-off: the sound changes on release, not during the drag. Result by ear: pending.
- Comparison aid: run with `--dart-define=EQ_COMPARE=true` to show a picker in the EQ sheet: Release (default), 200 ms, 100 ms, Live (every movement). Results by ear per mode: pending.

## To do next
- Playback engine, then player UI, then EQ panel, then device file picking and error states.
- Verify Reset EQ by ear and update the README checklist.
- Add licensed bundled tracks and credits.
