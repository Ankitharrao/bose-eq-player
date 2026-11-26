import 'package:flutter/material.dart';

import 'audio/audio_engine.dart';
import 'audio/equalizer_controller.dart';
import 'core/theme/app_theme.dart';
import 'data/device_tracks.dart';
import 'features/player/player_screen.dart';

class BoseApp extends StatelessWidget {
  const BoseApp({
    super.key,
    required this.engine,
    required this.eq,
    required this.library,
  });

  final AudioEngine engine;
  final EqualizerController eq;
  final DeviceLibrary library;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EQ Player',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: PlayerScreen(engine: engine, eq: eq, library: library),
    );
  }
}
