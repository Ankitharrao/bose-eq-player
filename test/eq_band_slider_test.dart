import 'package:bose_app/features/equalizer/widgets/eq_band_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatDb', () {
    expect(formatDb(0), '0 dB');
    expect(formatDb(3), '+3 dB');
    expect(formatDb(-2.5), '−2.5 dB');
  });

  testWidgets('dragging the slider reports a new gain', (tester) async {
    double? reported;
    var ends = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EqBandSlider(
          label: 'LOW',
          hint: 'Below 500 Hz',
          value: 0,
          min: -15,
          max: 15,
          onChanged: (v) => reported = v,
          onChangeEnd: (_) => ends++,
        ),
      ),
    ));

    expect(find.text('0 dB'), findsOneWidget);
    await tester.drag(find.byType(Slider), const Offset(60, 0));
    expect(reported, isNotNull);
    expect(reported! > 0, isTrue);
    expect(ends, 1, reason: 'hardware is written once per drag');
  });
}
