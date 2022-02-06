import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../interpolate.dart';

class HeartOfMaths extends StatefulWidget {
  const HeartOfMaths({Key? key}) : super(key: key);

  @override
  _HeartOfMathsState createState() => _HeartOfMathsState();
}

class _HeartOfMathsState extends State<HeartOfMaths> with SingleTickerProviderStateMixin {
  ValueNotifier<double> animation = ValueNotifier(0.0);
  late Ticker ticker;

  @override
  void initState() {
    super.initState();

    ticker = createTicker((elapsed) {
      animation.value += elapsed.inMicroseconds;
    });

    ticker.start();
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CustomPaint(
          size: Size.square(MediaQuery.of(context).size.shortestSide - 32.0),
          painter: TimesTablePainter(animation: animation),
        ),
      ),
    );
  }
}

class TimesTablePainter extends CustomPainter {
  TimesTablePainter({required ValueListenable<double> animation}) : super(repaint: animation);

  double multiplier = 0.0;
  double count = 0.0;
  Color color = Colors.white;

  static double multiplierStep = .001;
  static double countStep = .1;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final bounds = Offset.zero & size;
    final radius = bounds.width / 2;
    final center = bounds.center;
    const strokeWidth = 2.0;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..strokeWidth = strokeWidth
        ..color = color.withOpacity(.24)
        ..style = PaintingStyle.stroke,
    );

    final angleMapper = interpolate(inputMax: count, outputMax: 360);
    for (var i = 0.0; i < count; i++) {
      final position = _polarOffset(angleMapper(i), center, radius);
      canvas.drawCircle(position, strokeWidth, Paint()..color = Color.alphaBlend(color, Colors.grey));

      final end = _polarOffset(angleMapper((i * multiplier) % count), center, radius);
      canvas.drawLine(
        position,
        end,
        Paint()
          ..color = color.withOpacity(.4)
          ..strokeWidth = strokeWidth,
      );
    }

    if ((multiplier + multiplierStep).toInt() > multiplier.toInt()) {
      color = Color(math.Random().nextInt(0xFFFFFFFF));
    }
    multiplier += multiplierStep;
    count += countStep;
  }

  Offset _polarOffset(double angle, Offset center, double radius) {
    return Offset.fromDirection((angle * math.pi / 180) - math.pi / 2, radius) + center;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
