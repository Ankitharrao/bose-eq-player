import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'audio/audio_engine.dart';
import 'audio/equalizer_controller.dart';
import 'data/track.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

  final engine = AudioEngine(bundledTracks);
  final eq = EqualizerController(engine.equalizer);
  await engine.init();
  await eq.init(); // after the first track loads, as in the spike

  runApp(BoseApp(engine: engine, eq: eq));
}
