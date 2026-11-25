import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../data/track.dart';
import 'audio_focus.dart';

/// Owns the player, the track list and the equalizer effect.
/// Commands are fire-and-forget; state comes back through streams.
class AudioEngine extends ChangeNotifier {
  AudioEngine(List<Track> tracks) : _tracks = List.of(tracks) {
    _stateSub = _player.playerStateStream.listen(_onPlayerState);
  }

  /// Handed to EqualizerController. It must be in the player's pipeline.
  final AndroidEqualizer equalizer = AndroidEqualizer();

  late final AudioPlayer _player = AudioPlayer(
    audioPipeline: AudioPipeline(androidAudioEffects: [equalizer]),
    // Focus changes and unplugging are handled by [_focus] below, so the
    // rules live in this app and the UI can be told why playback stopped.
    // just_audio still requests audio focus whenever playback starts.
    handleInterruptions: false,
  );

  late final AudioFocusHandler _focus = AudioFocusHandler(
    isPlaying: () => _player.playing,
    pause: () => _fire(_player.pause()),
    play: () => _fire(_player.play()),
    onNotice: _notices.add,
  );
  final _notices = StreamController<String>.broadcast();
  final List<StreamSubscription<void>> _sessionSubs = [];

  final List<Track> _tracks;
  int _index = 0;
  int _loadToken = 0; // lets a newer load cancel an older one
  int _lastStep = 1; // +1 after next, -1 after previous; drives UI motion
  StreamSubscription<PlayerState>? _stateSub;

  /// One-off messages for the UI, e.g. "Paused: headphones disconnected".
  Stream<String> get notices => _notices.stream;

  /// Latest playback problem for the UI to show; null when all is well.
  final ValueNotifier<String?> error = ValueNotifier(null);

  List<Track> get tracks => List.unmodifiable(_tracks);
  int get currentIndex => _index;
  Track? get currentTrack => _tracks.isEmpty ? null : _tracks[_index];

  /// The track [next] would play, or null with fewer than two tracks.
  Track? get nextTrack =>
      _tracks.length < 2 ? null : _tracks[(_index + 1) % _tracks.length];

  /// +1 if the last track change moved forward, -1 if backward.
  int get lastStep => _lastStep;

  /// True if [previous] would restart the current track instead of
  /// changing track.
  bool get previousRestarts => _player.position > const Duration(seconds: 3);

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<bool> get playingStream => _player.playingStream;
  Stream<bool> get loadingStream => _player.processingStateStream.map(
    (s) => s == ProcessingState.loading || s == ProcessingState.buffering,
  );

  /// Sets up the audio session and loads the first track, paused.
  /// Call once, then init the equalizer.
  Future<void> init() async {
    await _initSession();
    await _load(0);
  }

  /// Declares this app as a music player (media usage, full focus), then
  /// listens for focus changes and for headphones being unplugged.
  Future<void> _initSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      _sessionSubs
        ..add(
          session.becomingNoisyEventStream.listen(
            (_) => _focus.onBecomingNoisy(),
          ),
        )
        ..add(session.interruptionEventStream.listen(_focus.onInterruption));
    } catch (e) {
      // Playback still works; it just won't react to focus changes.
      debugPrint('Audio session unavailable: $e');
    }
  }

  // play/pause are user commands: they cancel any pending auto-resume.
  void play() {
    _focus.onUserAction();
    _fire(_player.play());
  }

  void pause() {
    _focus.onUserAction();
    _fire(_player.pause());
  }

  void togglePlayPause() => _player.playing ? pause() : play();
  void seek(Duration position) => _fire(_player.seek(position));
  void next() => _fire(_next());
  void previous() => _fire(_previous());

  /// Appends [tracks] to the list and starts playing the first of them.
  Future<void> addTracks(List<Track> tracks) async {
    if (tracks.isEmpty) return;
    final first = _tracks.length;
    _tracks.addAll(tracks);
    _lastStep = 1;
    await _load(first);
    if (error.value == null) play();
  }

  /// Jumps straight to the track at [index].
  void skipTo(int index) {
    if (index < 0 || index >= _tracks.length || index == _index) return;
    _lastStep = index > _index ? 1 : -1;
    _fire(_load(index));
  }

  Future<void> _next() async {
    if (_tracks.isEmpty) return;
    _lastStep = 1;
    await _load((_index + 1) % _tracks.length);
  }

  Future<void> _previous() async {
    if (_tracks.isEmpty) return;
    // Past 3 seconds, "previous" restarts the current track instead.
    if (previousRestarts) {
      await _player.seek(Duration.zero);
      return;
    }
    _lastStep = -1;
    await _load((_index - 1 + _tracks.length) % _tracks.length);
  }

  Future<void> _load(int index) async {
    if (_tracks.isEmpty) return;
    final token = ++_loadToken;
    _index = index;
    error.value = null;
    notifyListeners();

    final track = _tracks[index];
    try {
      if (track.isAsset) {
        await _player.setAsset(track.path);
      } else {
        await _player.setFilePath(track.path);
      }
      // If the player was already playing it carries on with the new track.
    } catch (e) {
      if (token != _loadToken) return; // a newer request replaced this one
      debugPrint('Could not load ${track.title}: $e');
      error.value = 'Could not play "${track.title}".';
    }
  }

  void _onPlayerState(PlayerState state) {
    if (state.processingState != ProcessingState.completed) return;
    if (_tracks.length > 1) {
      next();
    } else {
      pause();
      seek(Duration.zero);
    }
  }

  /// Starts a command and logs any failure instead of letting it escape.
  void _fire(Future<void> work) {
    unawaited(
      work.catchError((Object e) {
        debugPrint('Audio command failed: $e');
      }),
    );
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    for (final sub in _sessionSubs) {
      sub.cancel();
    }
    _notices.close();
    _player.dispose();
    error.dispose();
    super.dispose();
  }
}
