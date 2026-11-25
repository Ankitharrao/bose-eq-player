import 'package:bose_app/audio/audio_engine.dart';
import 'package:bose_app/core/theme/app_theme.dart';
import 'package:bose_app/data/track.dart';
import 'package:bose_app/features/library/queue_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('indexAfterRemoval', () {
    test('removing before the current track shifts it down', () {
      expect(indexAfterRemoval(current: 3, removed: 1, newLength: 4), 2);
    });
    test('removing after the current track leaves it alone', () {
      expect(indexAfterRemoval(current: 1, removed: 3, newLength: 4), 1);
    });
    test('removing the current track moves to the following one', () {
      expect(indexAfterRemoval(current: 1, removed: 1, newLength: 3), 1);
    });
    test('removing the current last track wraps to the start', () {
      expect(indexAfterRemoval(current: 3, removed: 3, newLength: 3), 0);
    });
    test('removing the only track gives 0', () {
      expect(indexAfterRemoval(current: 0, removed: 0, newLength: 0), 0);
    });
  });

  testWidgets('device tracks can be removed, bundled tracks cannot',
      (tester) async {
    final engine = AudioEngine(const [
      Track(title: 'Bundled one', path: 'assets/audio/test.mp3'),
      Track(title: 'Picked one', path: '/tmp/picked.mp3', isAsset: false),
    ]);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: QueueList(engine: engine)),
    ));

    expect(find.text('2 TRACKS'), findsOneWidget);
    expect(find.byTooltip('Remove "Bundled one"'), findsNothing);
    expect(find.byTooltip('Remove "Picked one"'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove "Picked one"'));
    await tester.pump();

    expect(find.text('Picked one'), findsNothing);
    expect(find.text('1 TRACK'), findsOneWidget);
    expect(engine.tracks.length, 1);
  });

  testWidgets('swiping a device track left removes it', (tester) async {
    final engine = AudioEngine(const [
      Track(title: 'Bundled one', path: 'assets/audio/test.mp3'),
      Track(title: 'Picked one', path: '/tmp/picked.mp3', isAsset: false),
    ]);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: QueueList(engine: engine)),
    ));

    await tester.drag(find.text('Picked one'), const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(find.text('Picked one'), findsNothing);
    expect(engine.tracks.map((t) => t.title), ['Bundled one']);
  });
}
