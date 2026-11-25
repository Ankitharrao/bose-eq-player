import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Rounded card with minimal concentric rings and a soft lime glow.
/// The glow brightens while audio is playing.
class ArtworkCard extends StatelessWidget {
  const ArtworkCard({super.key, required this.seed, required this.isPlaying});

  /// Varies the ring count a little between tracks.
  final int seed;
  final bool isPlaying;

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
              opacity: isPlaying ? 1 : 0.35,
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
              child: CustomPaint(painter: _RingsPainter(seed)),
            ),
          ),
        ),
      ],
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter(this.seed);

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.shortestSide / 2;
    final ringCount = 4 + seed % 3;

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = AppColors.inkLine;
    for (var i = 1; i <= ringCount; i++) {
      canvas.drawCircle(center, maxRadius * (0.18 + 0.78 * i / ringCount), ring);
    }

    final accent = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = AppColors.lime;
    canvas.drawCircle(center, maxRadius * 0.14, accent);
    canvas.drawCircle(center, maxRadius * 0.03, Paint()..color = AppColors.lime);
  }

  @override
  bool shouldRepaint(_RingsPainter oldDelegate) => oldDelegate.seed != seed;
}