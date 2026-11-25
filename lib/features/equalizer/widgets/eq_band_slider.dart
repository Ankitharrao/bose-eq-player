import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// One EQ band: name, frequency hint, a slider centred on 0 dB, and its value.
/// Gives a haptic tick when the slider lands on 0 dB; double-tap the value
/// to put the band back to 0 dB.
class EqBandSlider extends StatelessWidget {
  const EqBandSlider({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.onChangeEnd,
    this.onReset,
  });

  final String label;
  final String hint;
  final double value;
  final double min;
  final double max;

  /// Null disables the slider.
  final ValueChanged<double>? onChanged;

  /// Called once when the finger lifts.
  final ValueChanged<double>? onChangeEnd;

  /// Called on double-tap of the value label.
  final VoidCallback? onReset;

  void _changed(double v) {
    if (v == 0 && value != 0) HapticFeedback.selectionClick();
    onChanged?.call(v);
  }

  @override
  Widget build(BuildContext context) {
    // 0.5 dB steps make it easy to land exactly on flat.
    final divisions = ((max - min) * 2).round();

    return Row(
      children: [
        SizedBox(
          width: 104,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.label.copyWith(color: AppColors.paper),
              ),
              const SizedBox(height: 2),
              Text(
                hint,
                style: AppTextStyles.label.copyWith(
                  fontSize: 11,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackShape: const _CentredTrackShape(),
              tickMarkShape: SliderTickMarkShape.noTickMark,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              min: min,
              max: max,
              divisions: divisions > 0 ? divisions : null,
              value: value.clamp(min, max).toDouble(),
              onChanged: onChanged == null ? null : _changed,
              onChangeEnd: onChangeEnd,
              semanticFormatterCallback: (v) => '$label ${formatDb(v)}',
            ),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onDoubleTap: onReset == null || value == 0
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onReset!();
                },
          child: Tooltip(
            message: 'Double-tap to reset',
            child: SizedBox(
              width: 64,
              height: 40,
              child: Align(
                alignment: Alignment.centerRight,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 150),
                  style: AppTextStyles.number.copyWith(
                    color: value == 0 ? AppColors.paperMuted : AppColors.lime,
                  ),
                  child: Text(formatDb(value)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// "+3.5 dB", "−2 dB", "0 dB".
String formatDb(double db) {
  if (db == 0) return '0 dB';
  final sign = db > 0 ? '+' : '−';
  final abs = db.abs();
  final text = abs == abs.roundToDouble()
      ? abs.toStringAsFixed(0)
      : abs.toStringAsFixed(1);
  return '$sign$text dB';
}

/// Fills the active colour from the centre (0 dB) to the thumb, not from the
/// left edge, so boosts and cuts read at a glance. Draws a small centre mark.
class _CentredTrackShape extends SliderTrackShape with BaseSliderTrackShape {
  const _CentredTrackShape();

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
    final radius = Radius.circular(rect.height / 2);
    final canvas = context.canvas;

    final inactive = Paint()
      ..color = sliderTheme.inactiveTrackColor ?? AppColors.inkLine;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), inactive);

    final centreX = rect.center.dx;
    final active = Paint()
      ..color = isEnabled
          ? (sliderTheme.activeTrackColor ?? AppColors.lime)
          : (sliderTheme.disabledActiveTrackColor ?? AppColors.paperMuted);
    final left = thumbCenter.dx < centreX ? thumbCenter.dx : centreX;
    final right = thumbCenter.dx < centreX ? centreX : thumbCenter.dx;
    if (right > left) {
      canvas.drawRRect(
        RRect.fromLTRBR(left, rect.top, right, rect.bottom, radius),
        active,
      );
    }

    // Centre mark at 0 dB.
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(centreX, rect.center.dy),
        width: 2,
        height: rect.height + 8,
      ),
      Paint()..color = AppColors.paperMuted,
    );
  }
}
