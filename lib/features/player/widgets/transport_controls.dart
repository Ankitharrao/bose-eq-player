import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../audio/audio_engine.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/press_scale.dart';

/// Previous, play/pause and next.
class TransportControls extends StatelessWidget {
  const TransportControls({super.key, required this.engine});

  final AudioEngine engine;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SkipButton(
          tooltip: 'Previous track',
          icon: Icons.skip_previous_rounded,
          onPressed: engine.previous,
        ),
        const SizedBox(width: 20),
        _PlayButton(engine: engine),
        const SizedBox(width: 20),
        _SkipButton(
          tooltip: 'Next track',
          icon: Icons.skip_next_rounded,
          onPressed: engine.next,
        ),
      ],
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      scale: 0.85,
      child: IconButton(
        iconSize: 36,
        color: AppColors.paper,
        tooltip: tooltip,
        onPressed: () {
          HapticFeedback.selectionClick();
          onPressed();
        },
        icon: Icon(icon),
      ),
    );
  }
}

/// The main lime action. Shows a spinner while a track is loading.
class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.engine});

  final AudioEngine engine;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: engine.playingStream,
      initialData: false,
      builder: (context, playingSnap) {
        final playing = playingSnap.data ?? false;
        return StreamBuilder<bool>(
          stream: engine.loadingStream,
          initialData: false,
          builder: (context, loadingSnap) {
            final loading = loadingSnap.data ?? false;
            return PressScale(
              child: Tooltip(
                message: playing ? 'Pause' : 'Play',
                child: Material(
                  color: AppColors.lime,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      engine.togglePlayPause();
                    },
                    child: SizedBox.square(
                      dimension: 72,
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: loading
                              ? const SizedBox(
                                  key: ValueKey('loading'),
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: AppColors.ink,
                                  ),
                                )
                              : Icon(
                                  playing
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  key: ValueKey(playing),
                                  size: 38,
                                  color: AppColors.ink,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
