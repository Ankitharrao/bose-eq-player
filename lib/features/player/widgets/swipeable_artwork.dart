import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../audio/audio_engine.dart';
import 'artwork_card.dart';

/// The artwork as a gesture surface:
/// swipe left for the next track, right for the previous one, tap to
/// play or pause. The card follows the finger and flies off on a swipe.
class SwipeableArtwork extends StatefulWidget {
  const SwipeableArtwork({super.key, required this.engine});

  final AudioEngine engine;

  @override
  State<SwipeableArtwork> createState() => _SwipeableArtworkState();
}

class _SwipeableArtworkState extends State<SwipeableArtwork>
    with SingleTickerProviderStateMixin {
  // Horizontal offset of the card in logical pixels.
  late final AnimationController _dx = AnimationController.unbounded(
    vsync: this,
  );

  static const _flyOut = Duration(milliseconds: 160);
  static const _settle = Duration(milliseconds: 280);

  double _width = 300; // set from layout; used for swipe thresholds

  AudioEngine get _engine => widget.engine;
  bool get _canSwipe => _engine.tracks.length > 1;

  void _onDragUpdate(DragUpdateDetails d) {
    // With one track there is nowhere to go: resist the drag.
    _dx.value += d.delta.dx * (_canSwipe ? 1 : 0.25);
  }

  Future<void> _onDragEnd(DragEndDetails d) async {
    final width = _width;
    final velocity = d.primaryVelocity ?? 0;
    final offset = _dx.value;
    final goNext = offset < -width * 0.25 || velocity < -700;
    final goPrevious = offset > width * 0.25 || velocity > 700;

    if (!_canSwipe || !(goNext || goPrevious)) {
      await _springBack();
      return;
    }
    if (goPrevious && _engine.previousRestarts) {
      // "Previous" restarts the current track here; don't fake a change.
      HapticFeedback.selectionClick();
      _engine.previous();
      await _springBack();
      return;
    }

    HapticFeedback.lightImpact();
    final direction = goNext ? -1.0 : 1.0;
    await _dx.animateTo(
      direction * width * 1.2,
      duration: _flyOut,
      curve: Curves.easeIn,
    );
    goNext ? _engine.next() : _engine.previous();
    // The new card slides in from the opposite side (AnimatedSwitcher below).
    _dx.value = 0;
  }

  Future<void> _springBack() =>
      _dx.animateTo(0, duration: _settle, curve: Curves.easeOutBack);

  void _onTap() {
    HapticFeedback.lightImpact();
    _engine.togglePlayPause();
  }

  @override
  void dispose() {
    _dx.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final index = _engine.currentIndex;
    final step = _engine.lastStep.toDouble();

    return LayoutBuilder(
      builder: (context, box) {
        _width = box.maxWidth.isFinite ? box.maxWidth : 300;
        return Semantics(
          label:
              'Artwork. Swipe left for next track, right for previous. '
              'Tap to play or pause.',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _onTap,
            onHorizontalDragStart: (_) => _dx.stop(),
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
            child: AnimatedBuilder(
              animation: _dx,
              builder: (context, child) {
                final t = (_dx.value / _width).clamp(-1.5, 1.5);
                return Transform.translate(
                  offset: Offset(_dx.value, 0),
                  child: Transform.rotate(angle: t * 0.08, child: child),
                );
              },
              child: AnimatedSwitcher(
                duration: _settle,
                switchInCurve: Curves.easeOutCubic,
                // Only the incoming card animates; the outgoing one already
                // flew off (swipe) or should simply be replaced (buttons).
                transitionBuilder: (child, animation) {
                  final incoming = child.key == ValueKey(index);
                  if (!incoming) return const SizedBox.shrink();
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(
                        begin: Offset(0.35 * step, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: StreamBuilder<bool>(
                  key: ValueKey(index),
                  stream: _engine.playingStream,
                  initialData: false,
                  builder: (context, snap) =>
                      ArtworkCard(seed: index, isPlaying: snap.data ?? false),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
