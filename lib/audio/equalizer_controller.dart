import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// The three user-facing controls.
enum EqBand { low, mid, high }

/// Owns the 3-band EQ state and applies it to the Android equalizer.
/// The UI listens to this object; it never touches just_audio directly.
class EqualizerController extends ChangeNotifier {
  EqualizerController(this._equalizer);

  // Smoothing: how often we nudge the hardware, and the largest change
  // (in dB) allowed per nudge. Smaller step = smoother but slower to follow.
  static const _tick = Duration(milliseconds: 20);
  static const _maxStepDb = 0.75;

  final AndroidEqualizer _equalizer;
  AndroidEqualizerParameters? _params;

  // Where each slider currently is (what the UI shows).
  final Map<EqBand, double> _target = {
    for (final band in EqBand.values) band: 0.0,
  };

  // What the hardware currently has; it ramps toward _target.
  final Map<EqBand, double> _applied = {
    for (final band in EqBand.values) band: 0.0,
  };

  Timer? _timer;
  bool _ticking = false; // stops overlapping ticks if the phone is slow
  int _epoch = 0; // bumped by reset() so an in-flight tick stops writing

  /// False if the device has no usable equalizer (or init failed).
  bool get isAvailable => _params != null;

  // The device reports its own range; these are fallbacks for the UI
  // before init completes.
  double get minDb => _params?.minDecibels ?? -15;
  double get maxDb => _params?.maxDecibels ?? 15;

  /// The slider position, which the UI displays immediately.
  double gainOf(EqBand band) => _target[band] ?? 0;

  /// Call once after the player is created.
  Future<void> init() async {
    try {
      await _equalizer.setEnabled(true);
      _params = await _equalizer.parameters;
      await reset(); // the device may not start flat
    } catch (e) {
      debugPrint('Equalizer unavailable: $e');
      _params = null;
    }
    notifyListeners();
  }

  /// Moves a slider. The UI updates now; the hardware follows in small steps.
  void setGain(EqBand band, double db) {
    final params = _params;
    if (params == null) return;

    _target[band] = db.clamp(params.minDecibels, params.maxDecibels).toDouble();
    notifyListeners();

    _timer ??= Timer.periodic(_tick, (_) => _onTick());
  }

  /// One smoothing step: nudge each band's real gain toward its target.
  Future<void> _onTick() async {
    final params = _params;
    if (params == null || _ticking) return;
    _ticking = true;
    final epoch = _epoch;

    try {
      var stillMoving = false;

      for (final band in EqBand.values) {
        final target = _target[band]!;
        final current = _applied[band]!;
        if (current == target) continue;

        final diff = target - current;
        final next = diff.abs() <= _maxStepDb
            ? target // close enough: land exactly on the target
            : current + (diff > 0 ? _maxStepDb : -_maxStepDb);
        _applied[band] = next;

        for (final b in params.bands.where((b) => _bandFor(b) == band)) {
          if (epoch != _epoch) return; // reset() happened; stop writing
          await b.setGain(next);
        }
        if (next != target) stillMoving = true;
      }

      if (!stillMoving) {
        _timer?.cancel();
        _timer = null;
      }
    } catch (e) {
      debugPrint('Failed to apply gain: $e');
      _timer?.cancel(); // avoid repeating the same error every 20 ms
      _timer = null;
    } finally {
      _ticking = false;
    }
  }

  /// Restores a flat response: 0 dB on EVERY hardware band, immediately.
  Future<void> reset() async {
    final params = _params;
    if (params == null) return;

    _epoch++; // cancel any in-flight smoothing writes
    _timer?.cancel();
    _timer = null;
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
      debugPrint('Failed to reset equalizer: $e');
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
    _timer?.cancel();
    super.dispose();
  }
}