import 'package:bose_app/core/theme/app_theme.dart';
import 'package:bose_app/features/player/widgets/wavy_track_shape.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

Widget slider({required double amplitude, double value = 0.4}) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: SliderTheme(
          data: SliderThemeData(
            trackShape: WavyTrackShape(amplitude: amplitude, phase: 0.3),
          ),
          child: Slider(value: value, onChanged: (_) {}),
        ),
      ),
    );

void main() {
  for (final amplitude in [0.0, 3.0]) {
    testWidgets('wavy track paints at amplitude $amplitude', (tester) async {
      await tester.pumpWidget(slider(amplitude: amplitude));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('thumb at either end paints without error', (tester) async {
    await tester.pumpWidget(slider(amplitude: 3, value: 0));
    await tester.pumpWidget(slider(amplitude: 3, value: 1));
    expect(tester.takeException(), isNull);
  });

  // The seek bar is a real Slider again, so screen readers get complete
  // increase/decrease semantics from Flutter (a hand-built seek control
  // previously tripped a semantics assertion).
  testWidgets('keeps full slider semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(slider(amplitude: 3));
    final data = tester.getSemantics(find.byType(Slider)).getSemanticsData();
    expect(data.hasAction(SemanticsAction.increase), isTrue);
    expect(data.increasedValue, isNotEmpty);
    expect(data.decreasedValue, isNotEmpty);
    handle.dispose();
  });
}
