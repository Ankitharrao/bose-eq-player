import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'audio/audio_engine.dart';
import 'audio/equalizer_controller.dart';
import 'data/device_tracks.dart';
import 'data/track.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

  final library = DeviceLibrary();
  final saved = await library.load(); // tracks picked in earlier sessions
  final engine = AudioEngine([...bundledTracks, ...saved], library: library);
  final eq = EqualizerController(engine.equalizer);
  await engine.init();
  await eq.init(); // after the first track loads, as in the spike

  runApp(BoseApp(engine: engine, eq: eq, library: library));
}
