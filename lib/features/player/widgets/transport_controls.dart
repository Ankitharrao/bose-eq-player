import 'package:flutter/material.dart';

import '../../../audio/audio_engine.dart';
import '../../../core/theme/app_colors.dart';

/// Previous, play/pause and next.
class TransportControls extends StatelessWidget {
  const TransportControls({super.key, required this.engine});

  final AudioEngine engine;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          iconSize: 36,
          color: AppColors.paper,
          tooltip: 'Previous track',
          onPressed: engine.previous,
          icon: const Icon(Icons.skip_previous_rounded),
        ),
        const SizedBox(width: 20),
        _PlayButton(engine: engine),
        const SizedBox(width: 20),
        IconButton(
          iconSize: 36,
          color: AppColors.paper,
          tooltip: 'Next track',
          onPressed: engine.next,
          icon: const Icon(Icons.skip_next_rounded),
        ),
      ],
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
            return Tooltip(
              message: playing ? 'Pause' : 'Play',
              child: Material(
                color: AppColors.lime,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: engine.togglePlayPause,
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
            );
          },
        );
      },
    );
  }
}