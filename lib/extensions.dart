import 'dart:math' as math;
import 'dart:ui' as ui;

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

extension NumX<T extends num> on T {
  double get degrees => (this * 180.0) / math.pi;

  double get radians => (this * math.pi) / 180.0;

  T normalize(T max) => (this % max + max) % max as T;

  double get normalizeAngle => normalize(math.pi * 2.0 as T).toDouble();

  double subtractAngle(T diff) => (this - diff).normalizeAngle;

  double addAngle(T diff) => (this + diff).normalizeAngle;

  double between(double min, double max) {
    return math.max(math.min(max, toDouble()), min);
  }
}

extension SizeX on ui.Size {
  double get radius => shortestSide / 2;

  ui.Size copyWith({double width, double height}) {
    return ui.Size(width ?? this.width, height ?? this.height);
  }
}

extension RectX on ui.Rect {
  double get radius => shortestSide / 2;

  ui.Rect shrink({double top = 0.0, double left = 0.0, double right = 0.0, double bottom = 0.0}) {
    return ui.Rect.fromLTRB(this.left + left, this.top + top, this.right - right, this.bottom - bottom);
  }
}

double toAngle(ui.Offset coords, double radius) {
  return (coords - ui.Offset(radius, radius)).direction;
}

ui.Offset toPolar(ui.Offset center, double radians, double radius) {
  return center + ui.Offset(radius * math.cos(radians), radius * math.sin(radians));
}

double normalizeAngle(double angle) {
  final totalAngle = 360.radians;
  return (angle % totalAngle + totalAngle) % totalAngle;
}

double random(double min, double max) {
  return (math.Random().nextDouble() * max).between(min, max);
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
