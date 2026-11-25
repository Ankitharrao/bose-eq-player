import 'package:flutter/material.dart';

import '../../../audio/audio_engine.dart';
import '../../../core/format_duration.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Progress slider with elapsed and total time.
class SeekBar extends StatefulWidget {
  const SeekBar({super.key, required this.engine});

  final AudioEngine engine;

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double? _dragMs; // thumb position while the finger is down

  @override
  Widget build(BuildContext context) {
    final engine = widget.engine;
    return StreamBuilder<Duration?>(
      stream: engine.durationStream,
      builder: (context, durSnap) {
        final total = durSnap.data ?? Duration.zero;
        final hasDuration = total > Duration.zero;
        final maxMs = hasDuration ? total.inMilliseconds.toDouble() : 1.0;

        return StreamBuilder<Duration>(
          stream: engine.positionStream,
          builder: (context, posSnap) {
            final pos = posSnap.data ?? Duration.zero;
            final valueMs = (_dragMs ?? pos.inMilliseconds.toDouble())
                .clamp(0.0, maxMs)
                .toDouble();
            final shown = _dragMs == null
                ? pos
                : Duration(milliseconds: valueMs.round());

            return Column(
              children: [
                // A smaller overlay keeps the track ends aligned with the times.
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 14,
                    ),
                  ),
                  child: Slider(
                    min: 0,
                    max: maxMs,
                    value: valueMs,
                    onChanged: hasDuration
                        ? (v) => setState(() => _dragMs = v)
                        : null,
                    onChangeEnd: hasDuration
                        ? (v) {
                            engine.seek(Duration(milliseconds: v.round()));
                            setState(() => _dragMs = null);
                          }
                        : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(formatDuration(shown), style: AppTextStyles.number),
                      Text(
                        hasDuration ? formatDuration(total) : '--:--',
                        style: AppTextStyles.number.copyWith(
                          color: AppColors.paperMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
