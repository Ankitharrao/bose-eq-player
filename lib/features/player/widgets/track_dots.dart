import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../audio/audio_engine.dart';
import '../../../core/theme/app_colors.dart';

/// Page-style indicator for the track list. The current track is a lime
/// pill; tapping a dot jumps to that track. Hidden for 0–1 or many tracks.
class TrackDots extends StatelessWidget {
  const TrackDots({super.key, required this.engine});

  final AudioEngine engine;

  static const _maxDots = 12;

  @override
  Widget build(BuildContext context) {
    final count = engine.tracks.length;
    if (count < 2 || count > _maxDots) return const SizedBox(height: 24);

    return SizedBox(
      height: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            _Dot(
              active: i == engine.currentIndex,
              label: 'Track ${i + 1}: ${engine.tracks[i].title}',
              onTap: () {
                HapticFeedback.selectionClick();
                engine.skipTo(i);
              },
            ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active, required this.label, required this.onTap});

  final bool active;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          // Generous padding gives a usable touch target around a tiny dot.
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            width: active ? 22 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: active ? AppColors.lime : AppColors.inkLine,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    );
  }
}
