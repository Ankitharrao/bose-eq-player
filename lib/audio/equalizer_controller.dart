import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../core/log.dart';

/// The three user-facing controls.
enum EqBand { low, mid, high }

/// Owns the 3-band EQ state and applies it to the Android equalizer.
/// The UI listens to this object; it never touches just_audio directly.
///
/// Writing to the Android equalizer while a slider is being dragged causes
/// an audible crackle on the test device: every gain change is a step the
/// effect does not smooth out, and a drag produces dozens of them per second.
/// So by default slider movement only updates what the UI shows ([setGain]),
/// and the hardware is written once when the drag ends ([commit]).
///
/// [liveInterval] trades that off for comparison on a device: when set, the
/// hardware is also written during a drag, at most once per interval.
///
/// just_audio rebuilds the native equalizer whenever Android gives the
/// player a new audio session, from the settings it captured when the
/// player was created, and does not tell the Dart side. So the effect is
/// marked enabled before the player exists (the constructor), and on every
/// session change it is enabled again and all gains are rewritten
/// ([audioSessionIds]).
class EqualizerController extends ChangeNotifier {
  EqualizerController(this._equalizer, {Stream<int?>? audioSessionIds}) {
    // Before the player is created this only records the flag, so the
    // effect is created enabled, including when just_audio rebuilds it.
    unawaited(_equalizer.setEnabled(true));
    _sessionSub = audioSessionIds?.distinct().listen(_onAudioSession);
  }

  final AndroidEqualizer _equalizer;
  StreamSubscription<int?>? _sessionSub;
  int? _session;
  AndroidEqualizerParameters? _params;

  // Where each slider currently is (what the UI shows).
  final Map<EqBand, double> _target = {
    for (final band in EqBand.values) band: 0.0,
  };

  // What the hardware currently has.
  final Map<EqBand, double> _applied = {
    for (final band in EqBand.values) band: 0.0,
  };

  Timer? _liveTimer;
  Duration? _liveInterval;

  /// How often to write during a drag. Null: only on release (default).
  /// [Duration.zero]: on every slider movement.
  Duration? get liveInterval => _liveInterval;
  set liveInterval(Duration? value) {
    _liveInterval = value;
    _liveTimer?.cancel();
    _liveTimer = null;
    notifyListeners();
  }

  bool _writing = false; // one write loop at a time
  int _epoch = 0; // bumped by reset() so an in-flight write stops

  /// False if the device has no usable equalizer (or init failed).
  bool get isAvailable => _params != null;

  // The device reports its own range; these are fallbacks for the UI
  // before init completes.
  double get minDb => _params?.minDecibels ?? -15;
  double get maxDb => _params?.maxDecibels ?? 15;

  /// The slider position, which the UI displays immediately.
  double gainOf(EqBand band) => _target[band] ?? 0;

  /// True when every slider is at 0 dB.
  bool get isFlat => _target.values.every((db) => db == 0);

  /// A new audio session means a fresh native equalizer at device defaults:
  /// enable it and write every band again.
  Future<void> _onAudioSession(int? id) async {
    final previous = _session;
    _session = id;
    logDebug('Equalizer: audio session $previous -> $id');
    if (id == null || previous == null || _params == null) return;
    try {
      await _equalizer.setEnabled(true);
    } catch (e) {
      logDebug('Could not re-enable equalizer: $e');
    }
    for (final band in EqBand.values) {
      _applied[band] = double.nan; // unknown: force a write
    }
    commit();
  }

  /// Call once after the player is created.
  Future<void> init() async {
    try {
      await _equalizer.setEnabled(true);
      _params = await _equalizer.parameters;
      logDebug('Equalizer ready: ${_params!.bands.length} bands');
      await reset(); // the device may not start flat
    } catch (e) {
      logDebug('Equalizer unavailable: $e');
      _params = null;
    }
    notifyListeners();
  }

  /// Moves a slider. The UI updates now; the hardware only follows during
  /// the drag if [liveInterval] is set. Call [commit] when the drag ends.
  void setGain(EqBand band, double db) {
    final params = _params;
    if (params == null) return;
    _target[band] = db.clamp(params.minDecibels, params.maxDecibels).toDouble();
    notifyListeners();

    final interval = _liveInterval;
    if (interval == null) return;
    if (interval == Duration.zero) {
      commit();
    } else if (_liveTimer == null) {
      // Throttle: write now, then once more at the end of the interval
      // so the latest position is not lost.
      commit();
      _liveTimer = Timer(interval, () {
        _liveTimer = null;
        commit();
      });
    }
  }

  /// Sets all three sliders at once (a preset) and applies them.
  void applyGains(Map<EqBand, double> gains) {
    final params = _params;
    if (params == null) return;
    for (final MapEntry(key: band, value: db) in gains.entries) {
      _target[band] = db
          .clamp(params.minDecibels, params.maxDecibels)
          .toDouble();
    }
    notifyListeners();
    commit();
  }

  /// Puts one slider back to 0 dB and applies it.
  void resetBand(EqBand band) => applyGains({band: 0});

  /// Applies the current slider positions to the hardware, in one write per
  /// changed band. Safe to call repeatedly; only the latest values are sent.
  void commit() {
    if (_params == null || _writing) return;
    unawaited(_writeLoop());
  }

  Future<void> _writeLoop() async {
    final params = _params;
    if (params == null) return;
    _writing = true;
    final epoch = _epoch;
    try {
      // Loop in case a slider was released again while we were writing.
      var changed = true;
      while (changed) {
        changed = false;
        for (final band in EqBand.values) {
          final db = _target[band]!;
          if (_applied[band] == db) continue;
          for (final b in params.bands.where((b) => _bandFor(b) == band)) {
            if (epoch != _epoch) return; // reset() happened; stop writing
            await b.setGain(db);
          }
          _applied[band] = db;
          changed = true;
        }
      }
    } catch (e) {
      logDebug('Failed to apply gain: $e');
    } finally {
      _writing = false;
    }
  }

  /// Restores a flat response: 0 dB on EVERY hardware band, immediately.
  Future<void> reset() async {
    final params = _params;
    if (params == null) return;

    _epoch++; // cancel any in-flight writes
    _liveTimer?.cancel();
    _liveTimer = null;
    for (final band in EqBand.values) {
      _target[band] = 0;
      _applied[band] = 0;
    }
    notifyListeners(); // sliders snap to 0 now

    try {
      for (final b in params.bands) {
        await b.setGain(0);
      }
    } catch (e) {
      logDebug('Failed to reset equalizer: $e');
    }
  }

  /// Assigns a hardware band to a slider by its centre frequency.
  EqBand _bandFor(AndroidEqualizerBand band) {
    final hz = band.centerFrequency;
    if (hz < 500) return EqBand.low;
    if (hz < 2000) return EqBand.mid;
    return EqBand.high;
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    _liveTimer?.cancel();
    super.dispose();
  }
}
