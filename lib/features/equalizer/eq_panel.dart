import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../audio/equalizer_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/press_scale.dart';
import 'eq_presets.dart';
import 'widgets/eq_band_slider.dart';
import 'widgets/eq_curve.dart';

/// Opens the EQ panel as a bottom sheet. Music keeps playing underneath,
/// so changes are heard in real time.
Future<void> showEqSheet(BuildContext context, EqualizerController eq) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true, // let it grow past half height if needed
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: EqPanel(eq: eq),
      ),
    ),
  );
}

/// Curve, presets, three sliders (Low, Mid, High) and a Reset button.
class EqPanel extends StatelessWidget {
  const EqPanel({super.key, required this.eq});

  final EqualizerController eq;

  /// Build with --dart-define=EQ_COMPARE=true to show the write-mode picker.
  static const _showCompare = bool.fromEnvironment('EQ_COMPARE');

  static const _bands = [
    (EqBand.low, 'LOW', 'Below 500 Hz'),
    (EqBand.mid, 'MID', '500 Hz – 2 kHz'),
    (EqBand.high, 'HIGH', 'Above 2 kHz'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: eq,
      builder: (context, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(eq),
          const SizedBox(height: 16),
          if (!eq.isAvailable)
            const _Unavailable()
          else ...[
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.inkLine),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: EqCurve(
                  low: eq.gainOf(EqBand.low),
                  mid: eq.gainOf(EqBand.mid),
                  high: eq.gainOf(EqBand.high),
                  minDb: eq.minDb,
                  maxDb: eq.maxDb,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _PresetRow(eq),
            const SizedBox(height: 12),
            for (final (band, label, hint) in _bands)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: EqBandSlider(
                  label: label,
                  hint: hint,
                  value: eq.gainOf(band),
                  min: eq.minDb,
                  max: eq.maxDb,
                  onChanged: (db) => eq.setGain(band, db),
                  // Sound changes on release; writing during a drag crackles.
                  onChangeEnd: (_) => eq.commit(),
                  onReset: () => eq.resetBand(band),
                ),
              ),
          ],
          if (_showCompare && eq.isAvailable) ...[
            const SizedBox(height: 16),
            _WriteModePicker(eq),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.eq);

  final EqualizerController eq;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Text('Equalizer', style: AppTextStyles.title)),
        TextButton.icon(
          onPressed: eq.isAvailable && !eq.isFlat
              ? () {
                  HapticFeedback.mediumImpact();
                  eq.reset();
                }
              : null,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.lime,
            disabledForegroundColor: AppColors.paperMuted,
          ),
          icon: const Icon(Icons.restart_alt_rounded, size: 20),
          label: const Text('Reset'),
        ),
      ],
    );
  }
}

/// Horizontally scrolling preset pills; the matching one is lit.
class _PresetRow extends StatelessWidget {
  const _PresetRow(this.eq);

  final EqualizerController eq;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final preset in eqPresets)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _PresetChip(
                label: preset.name,
                selected: preset.matches(eq),
                onTap: () {
                  HapticFeedback.selectionClick();
                  // Flat goes through reset so every hardware band is zeroed.
                  preset.name == 'Flat'
                      ? eq.reset()
                      : eq.applyGains(preset.gains);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: PressScale(
        scale: 0.94,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: ShapeDecoration(
            color: selected ? AppColors.lime : Colors.transparent,
            shape: StadiumBorder(
              side: BorderSide(
                color: selected ? AppColors.lime : AppColors.inkLine,
              ),
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            shape: const StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                child: Text(
                  label,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.ink : AppColors.paper,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Row(
        children: [
          Icon(Icons.equalizer_rounded, color: AppColors.paperMuted),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'The equalizer is not available on this device.',
              style: AppTextStyles.body,
            ),
          ),
        ],
      ),
    );
  }
}

/// Testing aid: choose how often the hardware is written during a drag,
/// to compare crackle by ear. Only shown with EQ_COMPARE.
class _WriteModePicker extends StatelessWidget {
  const _WriteModePicker(this.eq);

  final EqualizerController eq;

  static const _modes = <(String, Duration?)>[
    ('Release', null),
    ('200 ms', Duration(milliseconds: 200)),
    ('100 ms', Duration(milliseconds: 100)),
    ('Live', Duration.zero),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('WRITE DURING DRAG (TEST)', style: AppTextStyles.label),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: [
            for (var i = 0; i < _modes.length; i++)
              ButtonSegment(value: i, label: Text(_modes[i].$1)),
          ],
          selected: {_modes.indexWhere((m) => m.$2 == eq.liveInterval)},
          onSelectionChanged: (s) => eq.liveInterval = _modes[s.first].$2,
        ),
      ],
    );
  }
}
