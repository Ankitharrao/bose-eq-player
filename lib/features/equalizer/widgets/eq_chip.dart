import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../audio/equalizer_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/press_scale.dart';

/// Top-bar pill that opens the EQ. Its three mini bars mirror the
/// current Low / Mid / High gains, so the EQ state is visible at a glance.
class EqChip extends StatelessWidget {
  const EqChip({super.key, required this.eq, required this.onPressed});

  final EqualizerController eq;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: eq,
      builder: (context, _) {
        final active = eq.isAvailable && !eq.isFlat;
        return Semantics(
          button: true,
          label: active ? 'Equalizer, adjusted' : 'Equalizer, flat',
          excludeSemantics: true,
          child: PressScale(
            scale: 0.94,
            child: Material(
              color: active
                  ? AppColors.lime.withValues(alpha: 0.12)
                  : AppColors.inkRaised,
              shape: StadiumBorder(
                side: BorderSide(
                  color: active
                      ? AppColors.lime.withValues(alpha: 0.5)
                      : AppColors.inkLine,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onPressed();
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final band in EqBand.values)
                        _MiniBar(fraction: _fraction(eq, band), active: active),
                      const SizedBox(width: 8),
                      Text(
                        'EQ',
                        style: AppTextStyles.label.copyWith(
                          color: active ? AppColors.lime : AppColors.paper,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 0..1 bar height for a band, with 0 dB at the middle.
  static double _fraction(EqualizerController eq, EqBand band) {
    final range = eq.maxDb - eq.minDb;
    if (range <= 0) return 0.5;
    return ((eq.gainOf(band) - eq.minDb) / range).clamp(0.0, 1.0);
  }
}

class _MiniBar extends StatelessWidget {
  const _MiniBar({required this.fraction, required this.active});

  final double fraction;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.5),
      child: SizedBox(
        width: 3,
        height: 14,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: 3,
            height: 3 + 11 * fraction,
            decoration: BoxDecoration(
              color: active ? AppColors.lime : AppColors.paperMuted,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ),
      ),
    );
  }
}
