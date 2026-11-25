import 'package:audio_session/audio_session.dart';
import 'package:bose_app/audio/audio_focus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late bool playing;
  late List<String> calls;
  late List<String> notices;
  late AudioFocusHandler focus;

  setUp(() {
    playing = true;
    calls = [];
    notices = [];
    focus = AudioFocusHandler(
      isPlaying: () => playing,
      pause: () {
        calls.add('pause');
        playing = false;
      },
      play: () {
        calls.add('play');
        playing = true;
      },
      onNotice: notices.add,
    );
  });

  AudioInterruptionEvent begin(AudioInterruptionType t) =>
      AudioInterruptionEvent(true, t);
  AudioInterruptionEvent end(AudioInterruptionType t) =>
      AudioInterruptionEvent(false, t);

  test('unplugging headphones pauses and tells the user', () {
    focus.onBecomingNoisy();
    expect(calls, ['pause']);
    expect(notices, ['Paused: headphones disconnected']);
  });

  test('unplugging while paused does nothing', () {
    playing = false;
    focus.onBecomingNoisy();
    expect(calls, isEmpty);
    expect(notices, isEmpty);
  });

  test('a call pauses, then playback resumes when it ends', () {
    focus.onInterruption(begin(AudioInterruptionType.pause));
    expect(calls, ['pause']);
    expect(focus.willResume, isTrue);
    focus.onInterruption(end(AudioInterruptionType.pause));
    expect(calls, ['pause', 'play']);
    expect(notices, isEmpty, reason: 'a call explains itself');
  });

  test('pressing play or pause during a call cancels the auto-resume', () {
    focus.onInterruption(begin(AudioInterruptionType.pause));
    focus.onUserAction();
    focus.onInterruption(end(AudioInterruptionType.pause));
    expect(calls, ['pause']);
  });

  test('an interruption while paused does not resume afterwards', () {
    playing = false;
    focus.onInterruption(begin(AudioInterruptionType.pause));
    focus.onInterruption(end(AudioInterruptionType.pause));
    expect(calls, isEmpty);
  });

  test('another app taking focus pauses for good', () {
    focus.onInterruption(begin(AudioInterruptionType.unknown));
    focus.onInterruption(end(AudioInterruptionType.unknown));
    expect(calls, ['pause']);
    expect(notices, ['Paused: another app is playing audio']);
  });

  test('duck requests are left to the system', () {
    focus.onInterruption(begin(AudioInterruptionType.duck));
    focus.onInterruption(end(AudioInterruptionType.duck));
    expect(calls, isEmpty);
  });

  test('unplugging during a call cancels the auto-resume', () {
    focus.onInterruption(begin(AudioInterruptionType.pause));
    focus.onBecomingNoisy();
    focus.onInterruption(end(AudioInterruptionType.pause));
    expect(calls, ['pause']);
  });
}
