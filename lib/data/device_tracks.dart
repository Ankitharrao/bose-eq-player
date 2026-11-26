import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'track.dart';

/// Tracks picked from the phone's storage, remembered across restarts.
///
/// Picking goes through Android's document picker (see `MainActivity.kt`).
/// Nothing is copied: each track is the original file's content:// URI, with
/// a lasting read permission, so it takes no extra space on the device. The
/// list itself is a small JSON entry in shared preferences.
class DeviceLibrary {
  static const _channel = MethodChannel('bose_eq/device_audio');
  static const _key = 'device_tracks';

  final _prefs = SharedPreferencesAsync();
  Future<void> _writes = Future.value(); // keeps saves in order

  /// Opens the system picker for audio files. Empty if the user cancels.
  Future<List<Track>> pick() async {
    final picked = await _channel.invokeListMethod<Map>('pick') ?? const [];
    return [
      for (final file in picked)
        Track(
          title: titleFromFileName(file['name'] as String),
          path: file['uri'] as String,
          isAsset: false,
        ),
    ];
  }

  /// The saved tracks the app can still read. Entries whose access was lost
  /// are dropped, and access no saved track uses is given back.
  Future<List<Track>> load() async {
    try {
      final granted = await _granted();
      final raw = await _prefs.getString(_key);
      final tracks = raw == null ? <Track>[] : _decode(raw);
      final kept = [
        for (final t in tracks)
          if (granted.contains(t.path)) t,
      ];
      final used = {for (final t in kept) t.path};
      for (final uri in granted.difference(used)) {
        await _release(uri);
      }
      return kept;
    } catch (e) {
      debugPrint('Could not load saved tracks: $e');
      return [];
    }
  }

  /// Saves [tracks] (device tracks only) as the remembered list.
  void save(List<Track> tracks) {
    final json = _encode([
      for (final t in tracks)
        if (!t.isAsset) t,
    ]);
    _writes = _writes
        .then((_) => _prefs.setString(_key, json))
        .catchError((Object e) => debugPrint('Could not save tracks: $e'));
  }

  /// Gives back read access to a removed track. The file itself is the
  /// user's and is never touched.
  void forget(Track track) {
    if (!track.isAsset) unawaited(_release(track.path));
  }

  Future<Set<String>> _granted() async =>
      (await _channel.invokeListMethod<String>('granted') ?? const []).toSet();

  Future<void> _release(String uri) async {
    try {
      await _channel.invokeMethod<void>('release', {'uri': uri});
    } catch (e) {
      debugPrint('Could not release $uri: $e');
    }
  }
}

String _encode(List<Track> tracks) => jsonEncode([
  for (final t in tracks) {'title': t.title, 'uri': t.path},
]);

List<Track> _decode(String raw) => [
  for (final e in (jsonDecode(raw) as List).cast<Map<String, dynamic>>())
    Track(
      title: e['title'] as String,
      path: e['uri'] as String,
      isAsset: false,
    ),
];

/// "My Song.final.mp3" -> "My Song.final"
@visibleForTesting
String titleFromFileName(String fileName) {
  final dot = fileName.lastIndexOf('.');
  return dot > 0 ? fileName.substring(0, dot) : fileName;
}
