// Renders the launcher icon artwork to assets/icon/. Not part of the test
// suite (it lives outside test/); run it on purpose, then regenerate icons:
//
//   flutter test tool/icon/render_icon_test.dart
//   dart run flutter_launcher_icons
//
// The design is three EQ sliders (Low, Mid, High) with lime knobs at
// different heights, in the app's ink/lime palette. Original artwork; it
// uses no Bose marks.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const _size = 1024.0;
const _ink = Color(0xFF080A08);
const _lime = Color(0xFFC5F542);
const _track = Color(0xFF2E332C);
const _white = Color(0xFFFFFFFF);

/// Knob positions, 0 = bottom of the track, 1 = top.
const _levels = [0.38, 0.78, 0.55];

/// Draws the three sliders centred in the canvas. [scale] 1 fits the
/// adaptive-icon safe zone (a circle of ~61% of the canvas).
void _paintSliders(
  Canvas canvas, {
  required double scale,
  required Color active,
  Color? inactive,
}) {
  const c = _size / 2;
  final spacing = 150.0 * scale;
  final half = 212.0 * scale; // half the track length
  final width = 40.0 * scale;
  final knob = 54.0 * scale;

  for (var i = 0; i < 3; i++) {
    final x = c + (i - 1) * spacing;
    final top = c - half, bottom = c + half;
    final y = bottom - (bottom - top) * _levels[i];
    final cap = Radius.circular(width / 2);

    if (inactive != null) {
      canvas.drawRRect(
        RRect.fromLTRBR(x - width / 2, top, x + width / 2, bottom, cap),
        Paint()..color = inactive,
      );
    }
    canvas.drawRRect(
      RRect.fromLTRBR(x - width / 2, y, x + width / 2, bottom, cap),
      Paint()..color = active,
    );
    canvas.drawCircle(Offset(x, y), knob, Paint()..color = active);
    if (inactive != null) {
      // A small ink centre, like the knobs in the app.
      canvas.drawCircle(Offset(x, y), knob * 0.34, Paint()..color = _ink);
    }
  }
}

Future<void> _save(String path, void Function(Canvas) paint) async {
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder, const Rect.fromLTWH(0, 0, _size, _size)));
  final image = await recorder.endRecording().toImage(
    _size.toInt(),
    _size.toInt(),
  );
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(path)..createSync(recursive: true);
  file.writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  testWidgets('render launcher icon artwork', (tester) async {
    await tester.runAsync(() async {
      // Full-bleed icon for launchers without adaptive icons.
      await _save('assets/icon/icon.png', (canvas) {
        canvas.drawRect(
          const Rect.fromLTWH(0, 0, _size, _size),
          Paint()..color = _ink,
        );
        _paintSliders(canvas, scale: 1.3, active: _lime, inactive: _track);
      });
      // Adaptive foreground: transparent, artwork inside the safe zone.
      await _save('assets/icon/icon_foreground.png', (canvas) {
        _paintSliders(canvas, scale: 1, active: _lime, inactive: _track);
      });
      // Android 13+ themed icon: a single-colour silhouette.
      await _save('assets/icon/icon_monochrome.png', (canvas) {
        _paintSliders(canvas, scale: 1, active: _white);
      });
    });
  });
}
