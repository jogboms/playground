import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import '../extensions.dart';

class EdgeDetection extends StatefulWidget {
  const EdgeDetection({Key? key}) : super(key: key);

  @override
  _EdgeDetectionState createState() => _EdgeDetectionState();
}

class _EdgeDetectionState extends State<EdgeDetection> with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BallsWidget(vsync: this),
    );
  }
}

class BallsWidget extends LeafRenderObjectWidget {
  const BallsWidget({
    Key? key,
    required this.vsync,
  }) : super(key: key);

  final TickerProvider vsync;

  @override
  RenderBalls createRenderObject(BuildContext context) {
    return RenderBalls(vsync: vsync);
  }
}

class RenderBalls extends RenderProxyBox {
  RenderBalls({
    required this.vsync,
  });

  final TickerProvider vsync;

  int _elapsedTimeInMicroSeconds = 0;

  late Ticker _ticker;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _ticker = vsync.createTicker((Duration elapsed) {
      _elapsedTimeInMicroSeconds = elapsed.inMicroseconds;
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

  late List<Ball> balls;

  @override
  void performLayout() {
    final _size = constraints.loosen().biggest;
    if (_size == (hasSize ? size : 0.0)) {
      return;
    }
    balls = [];
    size = _size;

    const minRadius = 15.0;
    const maxRadius = 25.0;

    for (var i = 0; i < 100; i++) {
      final radius = random(minRadius, maxRadius);
      balls.add(Ball(
        bounds: Offset.zero & size,
        radius: radius,
        origin: Offset(size.width / 2, radius * 2),
        velocity: Offset.fromDirection(random(0, math.pi * 2), (maxRadius * 2) / radius),
        color: HSLColor.fromAHSL(random(.85, 1.0), random(0.0, 360.0), .5, .5).toColor(),
      ));
    }
  }

  @override
  void paint(PaintingContext context, ui.Offset offset) {
    for (var i = 0; i < balls.length; i++) {
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
    required this.origin,
    required Rect bounds,
    required this.velocity,
    required this.radius,
    required this.color,
  })  : position = origin,
        bounds = bounds.deflate(radius),
        dy = velocity,
        friction = .98,
        gravity = const Offset(0, .1);

  final Offset origin;
  final Rect bounds;
  final Offset velocity;
  final double friction;
  final double radius;
  final Color color;
  final Offset gravity;

  Offset dy;
  Offset position;

  void animate() {
    if (position.dy >= bounds.bottom || position.dy <= bounds.top) {
      dy = Offset(dy.dx, -dy.dy * friction);
    }

    if (position.dx >= bounds.right || position.dx <= bounds.left) {
      dy = Offset(-dy.dx, dy.dy * friction);
    }

    dy += gravity;

    position += dy;

    if (position.dy >= bounds.bottom) {
      position = Offset(position.dx, bounds.bottom);
    }
  }

  void tick(int elapsedTimeInMicroSeconds) {
    animate();
  }
}
