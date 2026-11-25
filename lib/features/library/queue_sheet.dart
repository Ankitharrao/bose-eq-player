import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../audio/audio_engine.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/track.dart';

/// Opens the track list as a bottom sheet.
Future<void> showQueueSheet(BuildContext context, AudioEngine engine) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scroll) => QueueList(engine: engine, scroll: scroll),
    ),
  );
}

/// Every track in play order. Tap a track to play it. Tracks added from the
/// device can be removed with the trash button or by swiping left; bundled
/// tracks are part of the app and stay.
class QueueList extends StatelessWidget {
  const QueueList({super.key, required this.engine, this.scroll});

  final AudioEngine engine;
  final ScrollController? scroll;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: engine,
      builder: (context, _) {
        final tracks = engine.tracks;
        return CustomScrollView(
          controller: scroll,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              sliver: SliverToBoxAdapter(child: _Header(count: tracks.length)),
            ),
            if (tracks.isEmpty)
              const SliverFillRemaining(hasScrollBody: false, child: _Empty())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList.builder(
                  itemCount: tracks.length,
                  itemBuilder: (context, i) => _QueueTile(
                    // Keyed by path so Dismissible tracks the right row.
                    key: ValueKey(tracks[i].path),
                    track: tracks[i],
                    position: i + 1,
                    isCurrent: i == engine.currentIndex,
                    onPlay: () {
                      HapticFeedback.selectionClick();
                      engine.skipTo(i);
                    },
                    onRemove: tracks[i].isAsset
                        ? null
                        : () {
                            HapticFeedback.mediumImpact();
                            engine.removeTrack(i);
                          },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        const Expanded(child: Text('Queue', style: AppTextStyles.title)),
        Text(
          count == 1 ? '1 TRACK' : '$count TRACKS',
          style: AppTextStyles.label,
        ),
      ],
    );
  }
}

class _QueueTile extends StatelessWidget {
  const _QueueTile({
    super.key,
    required this.track,
    required this.position,
    required this.isCurrent,
    required this.onPlay,
    required this.onRemove,
  });

  final Track track;
  final int position;
  final bool isCurrent;
  final VoidCallback onPlay;

  /// Null for bundled tracks, which cannot be removed.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final tile = Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: isCurrent
            ? AppColors.lime.withValues(alpha: 0.10)
            : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isCurrent
                ? AppColors.lime.withValues(alpha: 0.45)
                : Colors.transparent,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isCurrent ? null : onPlay,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: isCurrent
                      ? const Icon(
                          Icons.graphic_eq_rounded,
                          color: AppColors.lime,
                          size: 20,
                        )
                      : Text(
                          '$position',
                          style: AppTextStyles.number.copyWith(
                            color: AppColors.paperMuted,
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isCurrent ? AppColors.lime : AppColors.paper,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        track.isAsset ? 'BUNDLED' : 'FROM DEVICE',
                        style: AppTextStyles.label.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    tooltip: 'Remove "${track.title}"',
                    onPressed: onRemove,
                    color: AppColors.paperMuted,
                    icon: const Icon(Icons.delete_outline_rounded),
                  )
                else
                  const SizedBox(width: 48),
              ],
            ),
          ),
        ),
      ),
    );

    if (onRemove == null) return tile;
    return Dismissible(
      key: ValueKey('dismiss-${track.path}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove!(),
      background: const _RemoveBackground(),
      child: tile,
    );
  }
}

/// Revealed behind a tile while it is swiped away.
class _RemoveBackground extends StatelessWidget {
  const _RemoveBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        color: AppColors.inkLine,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('REMOVE', style: AppTextStyles.label),
          SizedBox(width: 8),
          Icon(Icons.delete_outline_rounded, color: AppColors.paper),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No tracks. Close this and tap + to add music.',
          textAlign: TextAlign.center,
          style: AppTextStyles.body,
        ),
      ),
    );
  }
}
