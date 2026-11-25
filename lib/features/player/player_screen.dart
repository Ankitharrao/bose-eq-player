import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../audio/audio_engine.dart';
import '../../audio/equalizer_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'widgets/artwork_card.dart';
import 'widgets/seek_bar.dart';
import 'widgets/transport_controls.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key, required this.engine, required this.eq});

  final AudioEngine engine;

  /// Used by the EQ panel, added in the next step.
  final EqualizerController eq;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  const _TopBar(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListenableBuilder(
                      listenable: engine,
                      builder: (context, _) {
                        if (engine.currentTrack == null) {
                          return const _EmptyState();
                        }
                        return LayoutBuilder(
                          builder: (context, box) => box.maxWidth >= 720
                              ? _WideLayout(engine)
                              : _NarrowLayout(engine),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Text('NOW PLAYING', style: AppTextStyles.label),
    );
  }
}

/// Phone portrait: artwork fills the space left over, controls below.
class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout(this.engine);

  final AudioEngine engine;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          children: [
            Expanded(child: _Artwork(engine)),
            const SizedBox(height: 24),
            _Controls(engine),
          ],
        ),
      ),
    );
  }
}

/// Landscape and tablets: artwork left, controls right.
class _WideLayout extends StatelessWidget {
  const _WideLayout(this.engine);

  final AudioEngine engine;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _Artwork(engine)),
        const SizedBox(width: 40),
        Expanded(
          child: Center(
            child: SingleChildScrollView(child: _Controls(engine)),
          ),
        ),
      ],
    );
  }
}

/// A square artwork sized to the space available.
class _Artwork extends StatelessWidget {
  const _Artwork(this.engine);

  final AudioEngine engine;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final side = math.min(box.maxWidth, box.maxHeight);
        return Center(
          child: SizedBox.square(
            dimension: side,
            child: StreamBuilder<bool>(
              stream: engine.playingStream,
              initialData: false,
              builder: (context, snap) => ArtworkCard(
                seed: engine.currentIndex,
                isPlaying: snap.data ?? false,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls(this.engine);

  final AudioEngine engine;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TrackInfo(engine),
        _ErrorBanner(engine),
        const SizedBox(height: 16),
        SeekBar(engine: engine),
        const SizedBox(height: 8),
        TransportControls(engine: engine),
      ],
    );
  }
}

class _TrackInfo extends StatelessWidget {
  const _TrackInfo(this.engine);

  final AudioEngine engine;

  @override
  Widget build(BuildContext context) {
    final track = engine.currentTrack!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'TRACK ${engine.currentIndex + 1} OF ${engine.tracks.length}',
            style: AppTextStyles.label,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Align(
            key: ValueKey(track.title),
            alignment: Alignment.centerLeft,
            child: Text(
              track.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.display,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner(this.engine);

  final AudioEngine engine;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: engine.error,
      builder: (context, message, _) => AnimatedSize(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.topCenter,
        child: message == null
            ? const SizedBox(width: double.infinity)
            : Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.inkRaised,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.paperMuted),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(message, style: AppTextStyles.body),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.library_music_outlined,
              size: 56, color: AppColors.paperMuted),
          SizedBox(height: 16),
          Text('No tracks yet', style: AppTextStyles.display),
          SizedBox(height: 8),
          Text(
            'Add a track from your device to start listening.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}