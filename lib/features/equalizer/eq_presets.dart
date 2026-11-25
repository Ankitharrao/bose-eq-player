import '../../audio/equalizer_controller.dart';

/// A named set of Low / Mid / High gains in dB.
class EqPreset {
  const EqPreset(this.name, this.low, this.mid, this.high);

  final String name;
  final double low;
  final double mid;
  final double high;

  Map<EqBand, double> get gains => {
    EqBand.low: low,
    EqBand.mid: mid,
    EqBand.high: high,
  };

  /// True if the controller's sliders sit on this preset
  /// (after clamping to the device's range).
  bool matches(EqualizerController eq) => gains.entries.every(
    (e) => (eq.gainOf(e.key) - e.value.clamp(eq.minDb, eq.maxDb)).abs() < 0.01,
  );
}

const eqPresets = <EqPreset>[
  EqPreset('Flat', 0, 0, 0),
  EqPreset('Bass', 6, 0, -1),
  EqPreset('Vocal', -2, 4, 1),
  EqPreset('Treble', -1, 0, 6),
  EqPreset('Warm', 3, 1, -2),
];
