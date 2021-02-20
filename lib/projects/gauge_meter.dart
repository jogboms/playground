import 'package:flutter/material.dart';

import '../extensions.dart';
import '../interpolate.dart';

class GaugeMeter extends StatefulWidget {
  @override
  _GaugeMeterState createState() => _GaugeMeterState();
}

class _GaugeMeterState extends State<GaugeMeter> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CustomPaint(
          painter: GaugeMeterPainter(
            value: 30,
            min: 0,
            max: 100,
            divisions: [
              Pair2(0.33, 'Bad', Color(0xFFFF524F)),
              Pair2(0.56, 'Average', Color(0xFFFAD64C)),
              Pair2(0.8, 'Good', Color(0xFFB2FF59)),
              Pair2(1.0, 'Excellent', Color(0xFF51AD54)),
            ],
          ),
          child: SizedBox.expand(),
        ),
      ),
    );
  }
}

class GaugeMeterPainter extends CustomPainter {
  GaugeMeterPainter({
    @required this.value,
    @required this.min,
    @required this.max,
    this.divisions = const [],
  })  : assert(value >= min && value <= max),
        assert(divisions.isNotEmpty),
        currentPercentage = _valueToPercentage(value, min: min, max: max);

  final double value;
  final double min;
  final double max;
  final List<Pair2<double, String, Color>> divisions;
  final double currentPercentage;

  static const cursorColor = Color(0xFF303030);
  static const selectionColor = Color(0xFFFF524F);
  static const trackColor = Color(0xFFD8D8DA);
  static const labelFontColor = Color(0xFFFFFFFF);

  static final angleOffset = -180.radians;
  static final maxSweepAngle = 180.radians;

  @override
  void paint(Canvas canvas, Size size) {
    final preferredWidth = (size.shortestSide * .9).clamp(200.0, 800.0);
    final bounds = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: preferredWidth,
      height: preferredWidth / 2,
    );

    // Draw background arc with spacing
    final gaugeBounds = bounds.topLeft & Size(bounds.size.width, bounds.size.height * 2);
    final strokeWidth = gaugeBounds.radius / 24;
    final spacingAngle = (strokeWidth / 2.5).clamp(4.0, 8.0).radians;
    final backgroundPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    var prevFraction = 0.0;
    for (var i = 0; i < divisions.length; i++) {
      final fraction = divisions[i].a;
      final offset = i == 0.0 ? 0.0 : spacingAngle;
      canvas.drawArc(
        gaugeBounds,
        angleOffset + (prevFraction * maxSweepAngle) + offset,
        (maxSweepAngle * (fraction - prevFraction)) - offset,
        false,
        backgroundPaint,
      );

      prevFraction = fraction;
    }

    // Draw selection arc
    final currentAngle = currentPercentage * maxSweepAngle;
    final selectedPair = _deriveSelectedPair(currentPercentage);
    final selectedColor = selectedPair.b;
    canvas.drawArc(
      gaugeBounds,
      angleOffset,
      currentAngle,
      false,
      Paint()
        ..color = selectedColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Draw cursor
    final cursorRadius = strokeWidth * 1.75;
    final cursorOffset = toPolar(gaugeBounds.center, angleOffset + currentAngle, bounds.width / 2);
    canvas.drawCircle(cursorOffset, cursorRadius, Paint()..color = cursorColor);
    canvas.drawCircle(
      cursorOffset,
      cursorRadius,
      Paint()
        ..color = selectedColor
        ..strokeWidth = strokeWidth * .7
        ..style = PaintingStyle.stroke,
    );

    // Draw min and max labels
    final labelFontSize = strokeWidth * 2.5;
    final labelOffset = Offset(0, labelFontSize * 1.85);
    _drawLabel(
      canvas,
      min.toInt().toString(),
      fontSize: labelFontSize,
      center: gaugeBounds.centerLeft + labelOffset,
      color: labelFontColor,
    );
    _drawLabel(
      canvas,
      max.toInt().toString(),
      fontSize: labelFontSize,
      center: gaugeBounds.centerRight + labelOffset,
      color: labelFontColor,
    );

    // Draw status label
    final statusFontSize = labelFontSize * 1.75;
    _drawLabel(
      canvas,
      selectedPair.a,
      fontSize: statusFontSize,
      center: gaugeBounds.center.translate(0, statusFontSize / 1.25),
      color: selectedColor,
    );

    // Draw value label
    _drawLabel(
      canvas,
      value.round().toString(),
      fontSize: gaugeBounds.radius / 2.25,
      center: gaugeBounds.center.translate(0, -gaugeBounds.radius / 3.5),
      color: labelFontColor,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  static double _valueToPercentage(double value, {double min, double max}) {
    return interpolate(inputMin: min, inputMax: max)(value);
  }

  Pair<String, Color> _deriveSelectedPair(double value) {
    for (final item in divisions) {
      if (item.a >= value) {
        return Pair(item.b, item.c);
      }
      continue;
    }
    return Pair(divisions[0].b, divisions[0].c);
  }

  void _drawLabel(Canvas canvas, String text, {double fontSize, Offset center, Color color}) {
    final textPainter = TextPainter(textAlign: TextAlign.center, textDirection: TextDirection.rtl)
      ..text = TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize))
      ..layout();
    final bounds = (center & textPainter.size).translate(-textPainter.width / 2, -textPainter.height / 2);
    textPainter.paint(canvas, bounds.topLeft);
  }
}
