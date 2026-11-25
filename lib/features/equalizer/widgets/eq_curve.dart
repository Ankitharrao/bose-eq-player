import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// An approximate frequency-response curve for the three sliders, drawn on
/// a log-frequency axis (20 Hz – 20 kHz). It is an illustration of the
/// slider settings, not a measurement of the device's actual filters.
class EqCurve extends StatefulWidget {
  const EqCurve({
    super.key,
    required this.low,
    required this.mid,
    required this.high,
    required this.minDb,
    required this.maxDb,
  });

  final double low;
  final double mid;
  final double high;
  final double minDb;
  final double maxDb;

  @override
  State<EqCurve> createState() => _EqCurveState();
}

class _EqCurveState extends State<EqCurve> with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
    value: 1,
  );
  late List<double> _from = _current;
  late List<double> _to = _current;

  List<double> get _current => [widget.low, widget.mid, widget.high];

  List<double> get _shown => [
    for (var i = 0; i < 3; i++)
      lerpDouble(_from[i], _to[i], Curves.easeOut.transform(_t.value))!,
  ];

  @override
  void didUpdateWidget(EqCurve oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _current;
    if (next.indexed.every((e) => e.$2 == _to[e.$1])) return;
    _from = _shown; // start from wherever the curve is drawn right now
    _to = next;
    _t.forward(from: 0);
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Equalizer curve',
      excludeSemantics: true,
      child: SizedBox(
        height: 132,
        child: AnimatedBuilder(
          animation: _t,
          builder: (context, _) => CustomPaint(
            size: Size.infinite,
            painter: _CurvePainter(
              gains: _shown,
              maxAbsDb: math.max(widget.maxDb.abs(), widget.minDb.abs()),
            ),
          ),
        ),
      ),
    );
  }
}

class _CurvePainter extends CustomPainter {
  _CurvePainter({required this.gains, required this.maxAbsDb});

  final List<double> gains; // low, mid, high
  final double maxAbsDb;

  // Representative centre for each slider's group of hardware bands.
  static const _bandHz = [150.0, 1000.0, 6000.0];
  static const _gridHz = [(100.0, '100'), (1000.0, '1k'), (10000.0, '10k')];
  static const _labelSpace = 18.0;

  static final _logMin = math.log(20) / math.ln10;
  static final _logMax = math.log(20000) / math.ln10;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTWH(0, 6, size.width, size.height - 6 - _labelSpace);
    double x(double hz) =>
        plot.left +
        (math.log(hz) / math.ln10 - _logMin) / (_logMax - _logMin) * plot.width;
    double y(double db) =>
        plot.center.dy - (maxAbsDb == 0 ? 0 : db / maxAbsDb) * plot.height / 2;

    // Grid: 0 dB line and decade lines with labels.
    final grid = Paint()
      ..color = AppColors.inkLine
      ..strokeWidth = 1;
    canvas.drawLine(Offset(plot.left, y(0)), Offset(plot.right, y(0)), grid);
    for (final (hz, label) in _gridHz) {
      final gx = x(hz);
      canvas.drawLine(Offset(gx, plot.top), Offset(gx, plot.bottom), grid);
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: AppTextStyles.label.copyWith(fontSize: 10, letterSpacing: 0.4),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(gx - tp.width / 2, plot.bottom + 4));
    }

    // Curve: shelf at each end, smooth between band centres.
    final points = [
      Offset(plot.left, y(gains[0])),
      for (var i = 0; i < 3; i++) Offset(x(_bandHz[i]), y(gains[i])),
      Offset(plot.right, y(gains[2])),
    ];
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];
      final mx = (a.dx + b.dx) / 2;
      line.cubicTo(mx, a.dy, mx, b.dy, b.dx, b.dy);
    }

    final fill = Path.from(line)
      ..lineTo(plot.right, y(0))
      ..lineTo(plot.left, y(0))
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.lime.withValues(alpha: 0.22),
            AppColors.lime.withValues(alpha: 0.02),
            AppColors.lime.withValues(alpha: 0.22),
          ],
        ).createShader(plot),
    );
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = AppColors.lime,
    );

    // Handles at the three band centres.
    for (final p in points.sublist(1, 4)) {
      canvas.drawCircle(p, 5, Paint()..color = AppColors.inkRaised);
      canvas.drawCircle(
        p,
        5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = AppColors.lime,
      );
    }
  }

  @override
  bool shouldRepaint(_CurvePainter old) =>
      old.maxAbsDb != maxAbsDb ||
      old.gains.indexed.any((e) => e.$2 != gains[e.$1]);
}
