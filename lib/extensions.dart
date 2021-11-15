import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/rendering.dart';

extension DoubleX on double {
  double discretize(int divisions) {
    return (this * divisions).round() / divisions;
  }

  double lerp(double min, double max) {
    assert(this >= 0.0);
    assert(this <= 1.0);
    return this * (max - min) + min;
  }

  double unlerp(double min, double max) {
    assert(this <= max);
    assert(this >= min);
    return max > min ? (this - min) / (max - min) : 0.0;
  }
}

const fullAngle = math.pi * 2.0;

extension NumX<T extends num> on T {
  double get degrees => (this * 180.0) / math.pi;

  double get radians => (this * math.pi) / 180.0;

  T normalize(T max) => (this % max + max) % max as T;

  double get normalizeAngle => normalize(fullAngle as T).toDouble();

  double subtractAngle(T diff) => (this - diff).normalizeAngle;

  double addAngle(T diff) => (this + diff).normalizeAngle;

  double shiftAngle(T shift) => toDouble() + ((-this - shift) / fullAngle).ceil() * fullAngle;

  bool between(double min, double max) => this <= max && this >= min;
}

extension SizeX on Size {
  double get radius => shortestSide / 2;

  Size copyWith({double? width, double? height}) {
    return Size(width ?? this.width, height ?? this.height);
  }
}

extension RectX on Rect {
  double get radius => shortestSide / 2;

  Rect shrink({double top = 0.0, double left = 0.0, double right = 0.0, double bottom = 0.0}) {
    return Rect.fromLTRB(this.left + left, this.top + top, this.right - right, this.bottom - bottom);
  }
}

extension OffsetX on Offset {
  Offset shift(double delta) {
    return translate(delta, delta);
  }
}

extension CanvasX on Canvas {
  Rect drawText(
    String text, {
    required Offset center,
    TextStyle style = const TextStyle(fontSize: 14.0, color: Color(0xFF333333), fontWeight: FontWeight.normal),
  }) {
    final textPainter = TextPainter(textAlign: TextAlign.center, textDirection: TextDirection.ltr)
      ..text = TextSpan(text: text, style: style)
      ..layout();
    final bounds = (center & textPainter.size).translate(-textPainter.width / 2, -textPainter.height / 2);
    textPainter.paint(this, bounds.topLeft);
    return bounds;
  }
}

double toAngle(Offset position, Offset center) => (position - center).direction;

Offset toPolar(Offset center, double radians, double radius) => center + Offset.fromDirection(radians, radius);

double normalizeAngle(double angle) {
  final totalAngle = 360.radians;
  return (angle % totalAngle + totalAngle) % totalAngle;
}

double random(double min, double max) {
  return math.max(math.min(max, math.Random().nextDouble() * max), min);
}

class Pair<A, B> {
  const Pair(this.a, this.b);

  final A a;
  final B b;
}

class Pair2<A, B, C> {
  const Pair2(this.a, this.b, this.c);

  final A a;
  final B b;
  final C c;
}

class Range<T> {
  const Range(this.start, this.end);

  final T start;
  final T end;
}

mixin RenderBoxDebugBounds on RenderBox {
  Set<Rect> debugBounds = {};
  Set<Path> debugPaths = {};

  @override
  void debugPaint(PaintingContext context, Offset offset) {
    assert(() {
      super.debugPaint(context, offset);

      if (debugPaintSizeEnabled) {
        for (var bounds in debugBounds) {
          context.canvas.drawRect(
              bounds,
              Paint()
                ..style = PaintingStyle.stroke
                ..color = const Color(0xFF00FFFF));
        }
        for (var path in debugPaths) {
          context.canvas.drawPath(
              path,
              Paint()
                ..style = PaintingStyle.stroke
                ..color = const Color(0xFF00FFFF));
        }
      }

      return true;
    }());
    debugBounds.clear();
    debugPaths.clear();
  }
}
