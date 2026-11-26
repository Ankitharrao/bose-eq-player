import 'package:bose_app/audio/audio_engine.dart';
import 'package:bose_app/data/device_tracks.dart';
import 'package:bose_app/data/track.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

const _channel = MethodChannel('bose_eq/device_audio');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Stands in for Android's persisted URI permissions.
  late Set<String> granted;
  late List<String> released;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    granted = {};
    released = [];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    // No real player in tests: accept just_audio's setup calls; loading a
    // track then fails inside the engine, which only logs it.
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.ryanheise.just_audio.methods'),
      (call) async => <String, Object?>{},
    );
    messenger.setMockMethodCallHandler(_channel, (call) async {
      switch (call.method) {
        case 'granted':
          return granted.toList();
        case 'release':
          final uri = (call.arguments as Map)['uri'] as String;
          granted.remove(uri);
          released.add(uri);
          return null;
        case 'pick':
          return [
            {'uri': 'content://a', 'name': 'Song A.mp3'},
          ];
      }
      return null;
    });
  });

  Track device(String uri) => Track(title: uri, path: uri, isAsset: false);

  test('picked files become device tracks named without extension', () async {
    final tracks = await DeviceLibrary().pick();
    expect(tracks.single.title, 'Song A');
    expect(tracks.single.path, 'content://a');
    expect(tracks.single.isAsset, isFalse);
  });

  test('saved tracks come back on the next launch', () async {
    granted = {'content://a', 'content://b'};
    DeviceLibrary().save([
      const Track(title: 'Bundled', path: 'assets/audio/test.mp3'),
      device('content://a'),
      device('content://b'),
    ]);
    await Future<void>.delayed(Duration.zero);

    final loaded = await DeviceLibrary().load();
    expect(loaded.map((t) => t.path), ['content://a', 'content://b']);
    expect(released, isEmpty);
  });

  test(
    'load drops tracks whose access was lost and frees unused access',
    () async {
      granted = {'content://a', 'content://b'};
      DeviceLibrary().save([device('content://a'), device('content://gone')]);
      await Future<void>.delayed(Duration.zero);

      final loaded = await DeviceLibrary().load();
      expect(loaded.map((t) => t.path), ['content://a']);
      expect(released, ['content://b']);
    },
  );

  test('removing a track forgets it and gives its access back', () async {
    granted = {'content://a', 'content://b'};
    final library = DeviceLibrary();
    final engine = AudioEngine([
      device('content://a'),
      device('content://b'),
    ], library: library);

    engine.removeTrack(1); // not the current one, so nothing loads
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(released, ['content://b']);
    expect((await DeviceLibrary().load()).map((t) => t.path), ['content://a']);
  });

  test('adding a file already in the queue does not duplicate it', () async {
    final engine = AudioEngine([device('content://a')]);
    final added = await engine.addTracks([
      device('content://a'),
      device('content://b'),
    ]);
    expect(added, 1);
    expect(engine.tracks.map((t) => t.path), ['content://a', 'content://b']);
    expect(await engine.addTracks([device('content://b')]), 0);
    expect(engine.tracks.length, 2);
  });
}
