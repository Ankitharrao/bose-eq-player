import 'dart:async';

import 'package:flutter/material.dart';

import '../../../audio/audio_engine.dart';
import '../../../core/format_duration.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'wavy_track_shape.dart';

/// Progress slider with elapsed and total time. The played part of the
/// track is a gentle wave that flows while audio plays and settles flat when
/// paused or while the thumb is being dragged.
class SeekBar extends StatefulWidget {
  const SeekBar({super.key, required this.engine});

  final AudioEngine engine;

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> with TickerProviderStateMixin {
  static const _waveHeight = 3.0;

  double? _dragMs; // thumb position while the finger is down
  bool _playing = false;
  StreamSubscription<bool>? _playingSub;

  // Scrolls the wave; runs only while the wave is visible.
  late final AnimationController _phase = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  // 0 = flat line, 1 = full wave.
  late final AnimationController _amplitude =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 350),
      )..addStatusListener((status) {
        if (status == AnimationStatus.dismissed) _phase.stop();
      });

  @override
  void initState() {
    super.initState();
    _playingSub = widget.engine.playingStream.listen((playing) {
      _playing = playing;
      _syncWave();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncWave();
  }

  /// Wave on while playing and not dragging (and motion is allowed).
  void _syncWave() {
    if (!mounted) return;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final show = _playing && _dragMs == null && !reduceMotion;
    if (show) {
      if (!_phase.isAnimating) _phase.repeat();
      _amplitude.forward();
    } else {
      _amplitude.reverse(); // the phase stops once the wave is flat
    }
  }

  void _setDrag(double? ms) {
    final changed = (ms == null) != (_dragMs == null);
    setState(() => _dragMs = ms);
    if (changed) _syncWave();
  }

  @override
  void dispose() {
    _playingSub?.cancel();
    _phase.dispose();
    _amplitude.dispose();
    super.dispose();
  }

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
                AnimatedBuilder(
                  animation: Listenable.merge([_phase, _amplitude]),
                  builder: (context, slider) => SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14,
                      ),
                      trackShape: WavyTrackShape(
                        amplitude:
                            _waveHeight *
                            Curves.easeInOut.transform(_amplitude.value),
                        phase: _phase.value,
                      ),
                    ),
                    child: slider!,
                  ),
                  child: Slider(
                    min: 0,
                    max: maxMs,
                    value: valueMs,
                    onChanged: hasDuration ? _setDrag : null,
                    onChangeEnd: hasDuration
                        ? (v) {
                            engine.seek(Duration(milliseconds: v.round()));
                            _setDrag(null);
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
