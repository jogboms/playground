import 'package:flutter/material.dart';

import './extensions.dart';

void main() => runApp(
      MaterialApp(
        theme: ThemeData.dark(),
        debugShowCheckedModeBanner: false,
        home: Playground(),
      ),
    );

class Playground extends StatefulWidget {
  @override
  _PlaygroundState createState() => _PlaygroundState();
}

class _PlaygroundState extends State<Playground> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: Container(
        child: Center(
          child: CustomPaint(
            painter: P(),
            size: Size.square(600.0),
          ),
        ),
      ),
    );
  }
}

class P extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius2 = size.radius;
    final bounds = Rect.fromCircle(center: center, radius: radius2);

    canvas.drawCircle(
      center,
      radius2,
      Paint()..color = Color(0xFF242E39),
    );

    canvas.save();
    canvas.clipPath(Path()..addOval(bounds));
    canvas.drawCircle(
      center,
      radius2 - 4.0,
      Paint()
        ..color = Color(0xAA111111)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0,
    );
    canvas.drawCircle(center, radius2 - 4.0, Paint()..color = Color(0x66111111));
    canvas.drawPath(
      Path.combine(
        PathOperation.xor,
        Path()..addOval(bounds),
        Path()..addOval(bounds.translate(-10, -10)),
      ),
      Paint()
        ..color = Colors.black
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 25),
    );
    canvas.restore();

    for (var i = 0; i < 100; i++) {
      final angle = (i / 100 * 360).radians;
      final start = center + Offset.fromDirection(angle, radius2 + 12.0);
      final end = start + Offset.fromDirection(angle, 24.0);
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = Colors.deepOrange.shade300.withOpacity(.25)
          ..strokeWidth = 2.0,
      );
    }

    canvas.drawCircle(
      center,
      size.radius,
      Paint()
        ..color = Colors.deepOrange.shade300
        ..strokeWidth = 4.0
        ..style = PaintingStyle.stroke,
    );
    final radius3 = size.radius * .575;
    _drawOuter(canvas, center, radius3);
    _drawKnob(canvas, center, radius3 * .65);

    _drawRing(canvas, center, radius3 * 1.45, 10);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  void _drawOuter(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center.translate(2.5, 15),
      radius * 1.005,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color(0xDDF1F7F4),
            Color(0xDD999999),
            Color(0xDD11111A),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = Colors.grey,
    );

    final radius2 = radius * .85;
    canvas.drawCircle(
      center,
      radius2,
      Paint()..color = Colors.grey,
    );

    canvas.drawCircle(
      center,
      radius2,
      Paint()
        ..shader = SweepGradient(
          colors: [
            Colors.white,
            Color(0xFFCCCCCC),
            Color(0xFF666666),
          ],
          endAngle: 90.radians,
          tileMode: TileMode.mirror,
        ).createShader(Rect.fromCircle(center: center, radius: radius2)),
    );
    canvas.drawCircle(
      center,
      radius2,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawRing(Canvas canvas, Offset center, double radius, double padding) {
    final startOffset = -210.radians;
    final sweepAngle = 80.radians;
    final height = radius * .125;
    final tickWidth = height * .25;
    final tickPadding = tickWidth * .75;
    const angles = 240.0;

    final tickCount = (((angles.radians / 2) * radius * 1.75) - 1) ~/ (tickWidth + 1);

    for (var i = 0; i < tickCount; i++) {
      final angle = (i * angles / tickCount).radians + startOffset;
      final start = center + Offset.fromDirection(angle, radius - height);
      final end = start + Offset.fromDirection(angle, height);
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = Color(0xFF111111)
          ..strokeWidth = tickWidth,
      );
    }

    for (var i = 0; i < tickCount; i++) {
      final angle = (i * angles / tickCount).radians + startOffset;
      if (angle > sweepAngle + startOffset) {
        continue;
      }

      final padding = tickPadding / 2;

      final start = center + Offset.fromDirection(angle, radius - height + padding / 2);
      final end = start + Offset.fromDirection(angle, height - padding);
      final color = Colors.deepOrange;

      canvas
        ..drawLine(
          start,
          end,
          Paint()
            ..color = color.withOpacity(.75)
            ..strokeWidth = tickWidth * 2.0
            ..blendMode = BlendMode.lighten
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, tickWidth * 2),
        )
        ..drawLine(
          start,
          end,
          Paint()
            ..color = color
            ..blendMode = BlendMode.colorDodge
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, tickWidth)
            ..strokeWidth = tickWidth * 2.0,
        )
        ..drawLine(
          start,
          end,
          Paint()
            ..color = Colors.white30
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, tickWidth)
            ..strokeWidth = tickWidth * 2.0,
        )
        ..drawLine(
          start,
          end,
          Paint()
            ..color = color.shade300
            ..strokeWidth = tickWidth,
        )
        ..drawLine(
          start,
          end,
          Paint()
            ..color = color.shade100
            ..strokeWidth = tickWidth - padding,
        );
    }
  }

  void _drawKnob(Canvas canvas, Offset center, double radius) {
    final radius2 = radius - 4.0;
    canvas.drawCircle(
      center.translate(2.5, 15),
      radius2 * 1.25,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color(0xDDF1F7F4),
            Color(0xDD999999),
            Color(0xDD11111A),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius2))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10),
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.black54
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = SweepGradient(
          colors: [
            Color(0xFFF1F7F4),
            Color(0xFF11111A),
          ],
          endAngle: 36.radians,
          tileMode: TileMode.mirror,
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    canvas.drawCircle(
      center,
      radius2,
      Paint()
        ..shader = SweepGradient(
          colors: [
            Color(0xFFF1F7F4),
            Color(0xFF999999),
            Color(0xFF11111A),
          ],
          endAngle: 90.radians,
          tileMode: TileMode.mirror,
          stops: [.125, .6, .925],
          transform: GradientRotation(45.radians),
        ).createShader(Rect.fromCircle(center: center, radius: radius2)),
    );
    canvas.drawCircle(
      center,
      radius2,
      Paint()
        ..color = Colors.black26
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke,
    );

    final c = 50;
    for (var i = 0; i < c; i++) {
      canvas.drawCircle(
        center,
        i / c * radius2,
        Paint()
          ..color = Colors.grey.withOpacity(.25)
          ..style = PaintingStyle.stroke
          ..blendMode = BlendMode.screen,
      );
    }
  }
}
