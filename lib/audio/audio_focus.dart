import 'package:audio_session/audio_session.dart';

/// Decides what playback should do when Android's audio focus changes or
/// the audio output becomes "noisy" (headphones unplugged, Bluetooth
/// disconnected). Pure logic: the engine wires it to the audio session and
/// the player, which keeps it unit-testable.
///
/// Rules:
/// - Headphones unplugged while playing: pause, never auto-resume
///   (plugging back in should not blast audio unexpectedly).
/// - Short focus loss (e.g. a phone call): pause, then resume when focus
///   returns, unless the user pressed play or pause in the meantime.
/// - Permanent focus loss (another music app started): pause, no resume.
/// - "Duck" requests (e.g. a navigation prompt): nothing to do here; on
///   Android 8+ the system lowers the volume of media apps itself.
class AudioFocusHandler {
  AudioFocusHandler({
    required this.isPlaying,
    required this.pause,
    required this.play,
    required this.onNotice,
  });

  final bool Function() isPlaying;
  final void Function() pause;
  final void Function() play;

  /// Short message for the UI explaining why playback stopped.
  final void Function(String message) onNotice;

  bool _resumeWhenFocusReturns = false;

  /// True while waiting to resume after a short interruption.
  bool get willResume => _resumeWhenFocusReturns;

  void onBecomingNoisy() {
    _resumeWhenFocusReturns = false;
    if (!isPlaying()) return;
    pause();
    onNotice('Paused: headphones disconnected');
  }

  void onInterruption(AudioInterruptionEvent event) {
    if (event.type == AudioInterruptionType.duck) return;

    if (event.begin) {
      if (!isPlaying()) return;
      pause();
      if (event.type == AudioInterruptionType.pause) {
        _resumeWhenFocusReturns = true;
      } else {
        _resumeWhenFocusReturns = false;
        onNotice('Paused: another app is playing audio');
      }
    } else {
      if (event.type == AudioInterruptionType.pause &&
          _resumeWhenFocusReturns) {
        play();
      }
      _resumeWhenFocusReturns = false;
    }
  }

  /// The user pressed play or pause: their choice wins over auto-resume.
  void onUserAction() => _resumeWhenFocusReturns = false;
}
