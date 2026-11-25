import 'package:flutter/material.dart';

import 'audio/audio_engine.dart';
import 'audio/equalizer_controller.dart';
import 'core/theme/app_theme.dart';
import 'features/player/player_screen.dart';

class BoseApp extends StatelessWidget {
  const BoseApp({super.key, required this.engine, required this.eq});

  final AudioEngine engine;
  final EqualizerController eq;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EQ Player',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: PlayerScreen(engine: engine, eq: eq),
    );
  }
}
