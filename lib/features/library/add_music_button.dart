import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../audio/audio_engine.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/press_scale.dart';
import '../../data/device_tracks.dart';

/// Opens the system picker, adds the chosen audio files to the track list
/// and plays the first one. Shows a spinner while the files are copied.
///
/// [compact] is the round top-bar version; otherwise a full lime button.
class AddMusicButton extends StatefulWidget {
  const AddMusicButton({super.key, required this.engine, this.compact = true});

  final AudioEngine engine;
  final bool compact;

  @override
  State<AddMusicButton> createState() => _AddMusicButtonState();
}

class _AddMusicButtonState extends State<AddMusicButton> {
  bool _busy = false;

  Future<void> _pick() async {
    if (_busy) return;
    HapticFeedback.selectionClick();
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final tracks = await pickDeviceTracks();
      if (tracks.isEmpty) return; // cancelled
      await widget.engine.addTracks(tracks);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            tracks.length == 1
                ? 'Added "${tracks.first.title}"'
                : 'Added ${tracks.length} tracks',
          ),
        ),
      );
    } catch (e) {
      debugPrint('File picking failed: $e');
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open your music files.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.compact) {
      return PressScale(
        scale: 0.96,
        child: FilledButton.icon(
          onPressed: _busy ? null : _pick,
          icon: _busy
              ? const _Spinner(color: AppColors.ink)
              : const Icon(Icons.add_rounded),
          label: const Text('Add music from device'),
        ),
      );
    }

    return PressScale(
      scale: 0.9,
      child: Tooltip(
        message: 'Add music from device',
        child: Material(
          color: AppColors.inkRaised,
          shape: const CircleBorder(side: BorderSide(color: AppColors.inkLine)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _busy ? null : _pick,
            child: SizedBox.square(
              dimension: 38,
              child: Center(
                child: _busy
                    ? const _Spinner(color: AppColors.lime)
                    : const Icon(Icons.add_rounded, size: 22),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 18,
      child: CircularProgressIndicator(strokeWidth: 2.5, color: color),
    );
  }
}
