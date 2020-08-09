import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

const MaterialColor primaryAccent = MaterialColor(
  0xFF121212,
  <int, Color>{
    50: Color(0xFFf7f7f7),
    100: Color(0xFFeeeeee),
    200: Color(0xFFe2e2e2),
    300: Color(0xFFd0d0d0),
    400: Color(0xFFababab),
    500: Color(0xFF8a8a8a),
    600: Color(0xFF636363),
    700: Color(0xFF505050),
    800: Color(0xFF323232),
    900: Color(0xFF121212),
  },
);

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  ValueNotifier<double> animation = ValueNotifier(0.0);
  Ticker ticker;

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
    return MaterialApp(
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: primaryAccent),
      debugShowCheckedModeBanner: false,
      home: Builder(builder: (context) {
        return Scaffold(
          body: Center(
            child: CustomPaint(
              size: Size.square(MediaQuery.of(context).size.shortestSide - 32.0),
              painter: TimesTablePainter(animation: animation),
            ),
          ),
        );
      }),
    );
  }
}

class TimesTablePainter extends CustomPainter {
  TimesTablePainter({@required ValueListenable<double> animation}) : super(repaint: animation);

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
    final strokeWidth = 2.0;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..strokeWidth = strokeWidth
        ..color = color.withOpacity(.24)
        ..style = PaintingStyle.stroke,
    );

    final angleMapper = interpolate(inputMax: count, outputMax: 360);
    for (double i = 0.0; i < count; i++) {
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

// https://stackoverflow.com/a/55088673/8236404
double Function(double input) interpolate({
  double inputMin = 0,
  double inputMax = 1,
  double outputMin = 0,
  double outputMax = 1,
}) {
  //range check
  if (inputMin == inputMax) {
    print("Warning: Zero input range");
    return null;
  }

  if (outputMin == outputMax) {
    print("Warning: Zero output range");
    return null;
  }

  //check reversed input range
  var reverseInput = false;
  final oldMin = math.min(inputMin, inputMax);
  final oldMax = math.max(inputMin, inputMax);
  if (oldMin != inputMin) {
    reverseInput = true;
  }

  //check reversed output range
  var reverseOutput = false;
  final newMin = math.min(outputMin, outputMax);
  final newMax = math.max(outputMin, outputMax);
  if (newMin != outputMin) {
    reverseOutput = true;
  }

  // Hot-rod the most common case.
  if (!reverseInput && !reverseOutput) {
    final dNew = newMax - newMin;
    final dOld = oldMax - oldMin;
    return (double x) {
      return ((x - oldMin) * dNew / dOld) + newMin;
    };
  }

  return (double x) {
    double portion;
    if (reverseInput) {
      portion = (oldMax - x) * (newMax - newMin) / (oldMax - oldMin);
    } else {
      portion = (x - oldMin) * (newMax - newMin) / (oldMax - oldMin);
    }
    double result;
    if (reverseOutput) {
      result = newMax - portion;
    } else {
      result = portion + newMin;
    }

    return result;
  };
}
