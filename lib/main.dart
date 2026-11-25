import 'package:flutter/material.dart';

import 'audio/audio_engine.dart';
import 'audio/equalizer_controller.dart';
import 'data/track.dart';
import 'core/theme/app_theme.dart';

final engine = AudioEngine(bundledTracks);
final eq = EqualizerController(engine.equalizer);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await engine.init();
  await eq.init(); // after the first track loads, as in the spike
  runApp(MaterialApp(theme: AppTheme.dark, home: const TestScreen()));
}

String fmt(Duration d) {
  final m = d.inMinutes.toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  double? _dragMs; // thumb position while the finger is down

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListenableBuilder(
              listenable: engine,
              builder: (context, _) =>
                  Text(engine.currentTrack?.title ?? 'No tracks',
                      style: Theme.of(context).textTheme.headlineSmall),
            ),
            ValueListenableBuilder<String?>(
              valueListenable: engine.error,
              builder: (context, msg, _) =>
              msg == null ? const SizedBox() : Text(msg),
            ),
            StreamBuilder<Duration?>(
              stream: engine.durationStream,
              builder: (context, durSnap) {
                final total = durSnap.data ?? Duration.zero;
                final totalMs = total.inMilliseconds.toDouble();
                return StreamBuilder<Duration>(
                  stream: engine.positionStream,
                  builder: (context, posSnap) {
                    final pos = posSnap.data ?? Duration.zero;
                    final maxMs = totalMs > 0 ? totalMs : 1.0;
                    final valueMs = (_dragMs ?? pos.inMilliseconds.toDouble())
                        .clamp(0.0, maxMs)
                        .toDouble();
                    return Column(children: [
                      Slider(
                        min: 0,
                        max: maxMs,
                        value: valueMs,
                        onChanged: (v) => setState(() => _dragMs = v),
                        onChangeEnd: (v) {
                          engine.seek(Duration(milliseconds: v.round()));
                          setState(() => _dragMs = null);
                        },
                      ),
                      Text('${fmt(pos)} / ${fmt(total)}'),
                    ]);
                  },
                );
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                    onPressed: engine.previous,
                    icon: const Icon(Icons.skip_previous)),
                StreamBuilder<bool>(
                  stream: engine.playingStream,
                  builder: (context, snap) => IconButton(
                    iconSize: 48,
                    onPressed: engine.togglePlayPause,
                    icon: Icon(snap.data == true
                        ? Icons.pause_circle
                        : Icons.play_circle),
                  ),
                ),
                IconButton(
                    onPressed: engine.next, icon: const Icon(Icons.skip_next)),
              ],
            ),
            const Divider(),
            ListenableBuilder(
              listenable: eq,
              builder: (context, _) => Column(children: [
                Text(eq.isAvailable ? 'EQ ready' : 'EQ unavailable'),
                for (final band in EqBand.values)
                  ListTile(
                    title: Text(
                        '${band.name}  ${eq.gainOf(band).toStringAsFixed(1)} dB'),
                    subtitle: Slider(
                      min: eq.minDb,
                      max: eq.maxDb,
                      value: eq.gainOf(band),
                      onChanged: (v) => eq.setGain(band, v),
                    ),
                  ),
                ElevatedButton(
                    onPressed: eq.reset, child: const Text('Reset EQ')),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}