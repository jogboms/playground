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
      body: Container(
        child: Center(
          child: CustomPaint(
            painter: P(),
            size: Size.square(400.0),
          ),
        ),
      ),
    );
  }
}

class P extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final startOffset = -210.radians;
    final sweepAngle = 100.radians;
    final center = size.center(Offset.zero);
    final height = 20.0;
    final tickPadding = 4.0;
    final tickWidth = 6.0;
    final angles = 240.0;

    final count = (((angles.radians / 2) * size.width) - 1) ~/ (tickWidth + 1);

    for (var i = 0; i < count; i++) {
      final angle = (i * angles / count).radians + startOffset;
      final start = center + Offset.fromDirection(angle, size.radius);
      final end = start + Offset.fromDirection(angle, height);
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = Colors.black
          ..strokeWidth = tickWidth,
      );
    }

    for (var i = 0; i < count; i++) {
      final angle = (i * angles / count).radians + startOffset;
      if (angle > sweepAngle + startOffset) {
        continue;
      }

      final padding = tickPadding / 2;

      final start = center + Offset.fromDirection(angle, size.radius + padding / 2);
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
            ..color = Color(0xFFFC9B8D)
            ..blendMode = BlendMode.colorDodge
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, tickWidth)
            ..strokeWidth = tickWidth - padding,
        )
        ..drawLine(
          start,
          end,
          Paint()
            ..color = Colors.white30
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, tickWidth)
            ..strokeWidth = tickWidth - padding,
        )
        ..drawLine(
          start,
          end,
          Paint()
            ..color = Colors.deepOrange.shade300
            ..strokeWidth = tickWidth - padding,
        )
        ..drawLine(
          start,
          end,
          Paint()
            ..color = Color(0xFFFC9B8D)
            ..strokeWidth = tickWidth - padding,
        );
    }

    canvas.drawCircle(
      center,
      size.radius - 48,
      Paint()
        ..shader = SweepGradient(
          colors: [
            Color(0xFFF1F7F4),
            Color(0xFF11111A),
          ],
          startAngle: 0,
          endAngle: 90.radians,
          tileMode: TileMode.mirror,
          stops: [0, .75],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
