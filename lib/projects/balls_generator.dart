import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import '../extensions.dart';

class BallsGenerator extends StatefulWidget {
  const BallsGenerator({Key key}) : super(key: key);

  @override
  _BallsGeneratorState createState() => _BallsGeneratorState();
}

class _BallsGeneratorState extends State<BallsGenerator> with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BallsWidget(vsync: this),
    );
  }
}

class BallsWidget extends LeafRenderObjectWidget {
  const BallsWidget({
    Key key,
    @required this.vsync,
  }) : super(key: key);

  final TickerProvider vsync;

  @override
  RenderBalls createRenderObject(BuildContext context) {
    return RenderBalls(vsync: vsync);
  }
}

class RenderBalls extends RenderProxyBox {
  RenderBalls({
    @required this.vsync,
  });

  final TickerProvider vsync;

  int _elapsedTimeInMicroSeconds = 0;

  Ticker _ticker;

  final _colors = [
    Color(0xFFCCCC22),
    Color(0xFF2266AA),
    Color(0xFFAAEE11),
    Color(0xFFCC6666),
  ];

  final pumpIntervalInSeconds = 10;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _ticker = vsync.createTicker((Duration elapsed) {
      _elapsedTimeInMicroSeconds = elapsed.inMicroseconds;
//      if (_count == pumpIntervalInSeconds && hasSize) {
//        print(["PUMP"]);
//      pump();
//      }
      markNeedsPaint();
    });
    _ticker.start();
  }

  @override
  void detach() {
    _ticker.stop();
    _ticker.dispose();
    super.detach();
  }

  void restartTicker() {
    if (_ticker.isActive) {
      _ticker.stop();
    }
    _ticker.start();
  }

  int maxTimeTaken;
  List<Ball> balls;

  void pump() {
    const radius = 15.0;
    const minDelay = 0.0;
    const maxDelay = 0.0;
    const minVelocity = 1.0;
    const maxVelocity = 50.0;
    const minPixelsPerSecond = minVelocity * 60;
    maxTimeTaken = ((size.height * 2 / minPixelsPerSecond) + maxDelay).ceil();

    final x = random(radius, size.width - radius);
    final dy = random(minVelocity, maxVelocity);
    balls.add(Ball(
      origin: Offset(size.width / 2, size.height - radius * 2),
      bounds: Offset.zero & size,
      velocity: Offset.fromDirection(math.pi / 4, dy),
      delay: random(minDelay, maxDelay),
      radius: radius,
      color: _colors[random(0.0, (_colors.length - 1).toDouble()).round()],
    ));
  }

  @override
  void performLayout() {
    final _size = constraints.loosen().biggest;
    if (_size == (hasSize ? size : 0.0)) {
      return;
    }
    balls = [];
    size = _size;

    for (int i = 0; i < 1; i++) {
      pump();
    }
  }

  @override
  void paint(PaintingContext context, ui.Offset offset) {
    for (int i = 0; i < balls.length; i++) {
      final ball = balls[i]..tick(_elapsedTimeInMicroSeconds);
      drawBall(context.canvas, ball, offset);
    }
  }

  void drawBall(Canvas canvas, Ball ball, Offset offset) {
    canvas.drawCircle(offset + ball.position, ball.radius, Paint()..color = ball.color);
  }
}

class Ball {
  Ball({
    @required this.origin,
    @required Rect bounds,
    @required this.velocity,
    @required this.radius,
    @required this.delay,
    @required this.color,
  })  : position = origin,
        acceleration = Offset(0, .1),
        this.bounds = bounds.deflate(radius),
        dy = velocity,
        gravity = Offset(0, 0.001),
        friction = .98;

  final Offset origin;
  final Rect bounds;
  final Offset velocity;
  final double radius;
  final double delay;
  final double friction;
  final Offset gravity;
  final Color color;
  final Offset acceleration;

  Offset dy;
  Offset position;

  void drop() {
    if (!bounds.contains(position)) {
      dy = Offset.fromDirection(
            dy.direction + math.pi / 2,
            dy.distance,
          ) *
          friction;
    } else {
//      dy += acceleration + gravity;
    }

    position += dy;

//    position = Offset(
//      position.dx.clamp(bounds.left, bounds.right),
////      position.dx.between(bounds.left, bounds.right),
//      position.dy.clamp(bounds.top, bounds.bottom),
//    );

    print([position, bounds, dy, !bounds.contains(position)]);
  }

  double startTimeInSeconds;

  void tick(int elapsedTimeInMicroSeconds) {
    final elapsedTimeInSeconds = elapsedTimeInMicroSeconds / Duration.microsecondsPerSecond;
    startTimeInSeconds ??= elapsedTimeInSeconds;
    if ((elapsedTimeInSeconds - startTimeInSeconds) >= delay) {
      drop();
    }
  }
}
