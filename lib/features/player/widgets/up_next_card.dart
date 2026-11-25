import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../audio/audio_engine.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/press_scale.dart';

/// "Up next" row showing the following track. Tap to skip to it.
class UpNextCard extends StatelessWidget {
  const UpNextCard({super.key, required this.engine});

  final AudioEngine engine;

  @override
  Widget build(BuildContext context) {
    final next = engine.nextTrack;
    if (next == null) return const SizedBox.shrink();

    return PressScale(
      scale: 0.97,
      child: Material(
        color: AppColors.inkRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.inkLine),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            engine.next();
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.inkLine, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.queue_music_rounded,
                    size: 18,
                    color: AppColors.lime,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('UP NEXT', style: AppTextStyles.label),
                      const SizedBox(height: 2),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: Text(
                          next.title,
                          key: ValueKey(next.title),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.paperMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
