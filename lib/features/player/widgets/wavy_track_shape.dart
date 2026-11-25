import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Slider track whose played part is a sine wave, in the style of
/// Android's media seek bar. [amplitude] 0 draws a straight line (paused);
/// [phase] (0..1) scrolls the wave, so animating it makes the wave flow.
///
/// The wave eases to flat just before the thumb so it meets it cleanly.
class WavyTrackShape extends SliderTrackShape with BaseSliderTrackShape {
  const WavyTrackShape({
    required this.amplitude,
    required this.phase,
    this.wavelength = 22,
  });

  /// Peak height of the wave in logical pixels.
  final double amplitude;

  /// Wave offset as a fraction of one wavelength.
  final double phase;

  final double wavelength;

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final canvas = context.canvas;
    final stroke = rect.height;
    final midY = rect.center.dy;
    final thumbX = thumbCenter.dx.clamp(rect.left, rect.right);

    final activeColor = isEnabled
        ? sliderTheme.activeTrackColor
        : sliderTheme.disabledActiveTrackColor;
    final inactiveColor = isEnabled
        ? sliderTheme.inactiveTrackColor
        : sliderTheme.disabledInactiveTrackColor;

    // Upcoming part: a plain line from the thumb to the end.
    if (rect.right > thumbX) {
      canvas.drawLine(
        Offset(thumbX, midY),
        Offset(rect.right, midY),
        Paint()
          ..color = inactiveColor ?? Colors.grey
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    // Played part: the wave, from the start to the thumb.
    final length = thumbX - rect.left;
    if (length <= 0) return;
    final taper = wavelength * 0.75; // flatten near the thumb
    double yAt(double x) {
      final fade = math.min(1.0, (length - x) / taper);
      final angle = 2 * math.pi * (x / wavelength - phase);
      return midY + amplitude * fade * math.sin(angle);
    }

    // Start on the wave itself, so the left end has no hook.
    final path = Path()..moveTo(rect.left, yAt(0));
    for (var x = 1.0; x <= length; x += 1) {
      path.lineTo(rect.left + x, yAt(x));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = activeColor ?? Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }
}
