import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Rounded card with concentric rings and a soft lime glow.
/// While playing, the glow brightens and a lime arc slowly orbits the rings.
class ArtworkCard extends StatefulWidget {
  const ArtworkCard({super.key, required this.seed, required this.isPlaying});

  /// Varies the ring count and arc start between tracks.
  final int seed;
  final bool isPlaying;

  @override
  State<ArtworkCard> createState() => _ArtworkCardState();
}

class _ArtworkCardState extends State<ArtworkCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSpin();
  }

  @override
  void didUpdateWidget(ArtworkCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSpin();
  }

  void _syncSpin() {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (widget.isPlaying && !reduceMotion) {
      if (!_spin.isAnimating) _spin.repeat();
    } else {
      _spin.stop(); // pauses in place, so it resumes where it left off
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Glow: extends past the card on every side.
        Positioned(
          left: -32,
          right: -32,
          top: -32,
          bottom: -32,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: widget.isPlaying ? 1 : 0.35,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      AppColors.lime.withValues(alpha: 0.30),
                      AppColors.lime.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.inkRaised,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.inkLine),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(27),
              child: CustomPaint(
                painter: _RingsPainter(
                  seed: widget.seed,
                  spin: _spin,
                  active: widget.isPlaying,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter({required this.seed, required this.spin, required this.active})
    : super(repaint: spin);

  final int seed;
  final Animation<double> spin;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.shortestSide / 2;
    final ringCount = 4 + seed % 3;
    double radiusOf(int i) => maxRadius * (0.18 + 0.78 * i / ringCount);

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = AppColors.inkLine;
    for (var i = 1; i <= ringCount; i++) {
      canvas.drawCircle(center, radiusOf(i), ring);
    }

    // Orbiting arcs: two rings, opposite directions, different speeds.
    final turn = spin.value * 2 * math.pi;
    final start = seed * 1.3;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5
      ..color = AppColors.lime.withValues(alpha: active ? 0.9 : 0.4);
    final outer = radiusOf(ringCount - 1);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outer),
      start + turn,
      0.9,
      false,
      arc,
    );
    final inner = radiusOf(math.max(1, ringCount - 3));
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: inner),
      start + math.pi - turn * 2,
      0.5,
      false,
      arc..strokeWidth = 2,
    );

    final accent = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = AppColors.lime;
    canvas.drawCircle(center, maxRadius * 0.14, accent);
    canvas.drawCircle(
      center,
      maxRadius * 0.03,
      Paint()..color = AppColors.lime,
    );
  }

  @override
  bool shouldRepaint(_RingsPainter old) =>
      old.seed != seed || old.active != active || old.spin != spin;
}
