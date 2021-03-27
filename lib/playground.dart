import 'dart:async' as async;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:playground/extensions.dart';
import 'package:playground/interpolate.dart';

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
      backgroundColor: Color(0xFF1D232F),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox.fromSize(
                size: Size(75, 450),
                child: LevelSliderWidget(value: 10, min: -10, max: 25),
              ),
              SizedBox(width: 16),
              SizedBox.fromSize(
                size: Size.square(450),
                child: KnobControlWidget(value: 25, min: 0, max: 70),
              ),
              SizedBox(width: 32),
              SizedBox.fromSize(
                size: Size(75, 450),
                child: LevelWidget(value: -14, min: -60, max: 0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LevelWidget extends LeafRenderObjectWidget {
  const LevelWidget({Key? key, required this.value, required this.min, required this.max, this.step = 10})
      : assert(value <= max && value >= min),
        super(key: key);

  final double value;
  final double max;
  final double min;
  final int step;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderLevelWidget(value: value, min: min, max: max, step: step);
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderLevelWidget renderObject) {
    renderObject
      ..value = value
      ..min = min
      ..max = max
      ..step = step;
  }
}

class RenderLevelWidget extends RenderBox with RenderBoxDebugBounds {
  RenderLevelWidget({required double value, required double min, required double max, required int step})
      : _value = valueToPercentageBuilder(min, max)(value),
        _min = min,
        _max = max,
        _step = step;

  double _value;

  set value(double value) {
    final percentage = valueToPercentageBuilder(_min, _max)(value);
    if (_value == percentage) {
      return;
    }

    _value = percentage;
    markNeedsPaint();
  }

  double _max;

  set max(double value) {
    if (_max == value) {
      return;
    }

    _max = value;
    _value = valueToPercentageBuilder(_min, _max)(_value);
    markNeedsPaint();
  }

  double _min;

  set min(double value) {
    if (_min == value) {
      return;
    }

    _min = value;
    _value = valueToPercentageBuilder(_min, _max)(_value);
    markNeedsPaint();
  }

  int _step;

  set step(int value) {
    if (_step == value) {
      return;
    }

    _step = value;
    markNeedsPaint();
  }

  late async.Timer _timer;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);

    _timer = async.Timer.periodic(Duration(milliseconds: 1000 ~/ 24), (timer) {
      _value = random(0, .25);
      markNeedsPaint();
    });
    async.Timer(Duration(seconds: 5), _timer.cancel);
  }

  @override
  void detach() {
    _timer.cancel();

    super.detach();
  }

  static final selectedColor = Color(0xFFFF6E40);
  static final thumbColor = Color(0xFF29323F);
  static final tickColor = Color(0xFF374153);
  static final labelColor = Color(0xFF69707C);
  static final backgroundColor = Color(0xFF151C24);

  static const tickDivisions = 10.0;

  int get tickCount => ((_max - _min) ~/ _step) + 1;

  double get tickLineCount => (tickCount - 1) * tickDivisions;

  static double Function(double) percentageToValueBuilder(double min, double max, int tickCount) {
    return interpolate(inputMax: tickCount - 1, outputMax: max, outputMin: min);
  }

  static double Function(double) valueToPercentageBuilder(double min, double max) {
    return interpolate(inputMax: max, inputMin: min, outputMin: 1, outputMax: 0);
  }

  @override
  bool get sizedByParent => true;

  @override
  bool get isRepaintBoundary => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return constraints.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    debugBounds.add(offset & size);

    final canvas = context.canvas;
    final width = size.width;
    final trackWidth = width * .55;
    final labelColumnWidth = width - trackWidth;
    final height = size.height * .925;
    final bounds = Rect.fromCenter(center: size.center(offset), width: size.width, height: height);
    debugBounds.add(bounds);

    final selectedHeight = _value * height;
    final selectedOffset = bounds.topLeft.translate(0, selectedHeight);
    final selectedCenterOffset = selectedOffset.translate(trackWidth / 2, 0);

    final tickThickness = trackWidth * .025;
    final tickSpacing = height / tickLineCount;
    final labelFontSize = labelColumnWidth * .3;
    final labelTopRightOffset = bounds.topRight + Offset(labelColumnWidth * -.5, 0);

    for (var i = 0; i < tickLineCount + 1; i++) {
      final isOnBorders = i == 0 || i == tickLineCount;
      final verticalPosition = i * tickSpacing;
      final verticalOffset = Offset(0, verticalPosition);
      final startOffset = bounds.topLeft + verticalOffset;
      final endOffset = startOffset + Offset(trackWidth, 0);
      final inBetween =
          verticalPosition >= selectedHeight || (selectedHeight - verticalPosition <= precisionErrorTolerance);
      canvas.drawLine(
        startOffset,
        endOffset,
        Paint()
          ..color = inBetween ? selectedColor : tickColor
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = isOnBorders ? tickThickness * 1 : tickThickness,
      );

      if (i % tickDivisions != 0) {
        continue;
      }

      final labelBounds = canvas.drawText(
        '${percentageToValueBuilder(_min, _max, tickCount)(tickCount - 1 - (i / tickDivisions)).toInt()}',
        center: labelTopRightOffset + verticalOffset,
        style: TextStyle(color: labelColor, fontSize: labelFontSize),
      );
      debugBounds.add(labelBounds);
    }

    final trackStrokeWidth = trackWidth / 10;
    final trackBounds = bounds.topLeft & Size(trackWidth, height);
    canvas.drawLine(
      trackBounds.topCenter,
      trackBounds.bottomCenter,
      Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.square
        ..strokeWidth = trackStrokeWidth,
    );
    debugBounds.add(trackBounds);

    canvas.drawLine(
      selectedCenterOffset.translate(0, -tickThickness / 2),
      trackBounds.bottomCenter.translate(0, tickThickness / 2),
      Paint()
        ..color = selectedColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = trackStrokeWidth,
    );
  }
}

class LevelSliderWidget extends LeafRenderObjectWidget {
  const LevelSliderWidget({Key? key, required this.value, required this.min, required this.max, this.step = 5})
      : assert(value <= max && value >= min),
        super(key: key);

  final double value;
  final double max;
  final double min;
  final int step;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderLevelSlider(value: value, min: min, max: max, step: step);
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderLevelSlider renderObject) {
    renderObject
      ..value = value
      ..min = min
      ..max = max
      ..step = step;
  }
}

class RenderLevelSlider extends RenderBox with RenderBoxDebugBounds {
  RenderLevelSlider({required double value, required double min, required double max, required int step})
      : _value = valueToPercentageBuilder(min, max)(value),
        _min = min,
        _max = max,
        _step = step {
    drag = VerticalDragGestureRecognizer()
      ..onStart = _onDragStart
      ..onUpdate = _onDragUpdate;
    tap = TapGestureRecognizer()..onTapDown = _onTapDown;
  }

  double _value = 0.0;

  set value(double value) {
    final percentage = valueToPercentageBuilder(_min, _max)(value);
    if (_value == percentage) {
      return;
    }

    _value = percentage;
    markNeedsPaint();
  }

  double _max;

  set max(double value) {
    if (_max == value) {
      return;
    }

    _max = value;
    _value = valueToPercentageBuilder(_min, _max)(_value);
    markNeedsPaint();
  }

  double _min;

  set min(double value) {
    if (_min == value) {
      return;
    }

    _min = value;
    _value = valueToPercentageBuilder(_min, _max)(_value);
    markNeedsPaint();
  }

  int _step;

  set step(int value) {
    if (_step == value) {
      return;
    }

    _step = value;
    markNeedsPaint();
  }

  late final VerticalDragGestureRecognizer drag;
  late final TapGestureRecognizer tap;

  static final selectedColor = Color(0xFFFF6E40);
  static final thumbColor = Color(0xFF29323F);
  static final tickColor = Color(0xFF374153);
  static final labelColor = Color(0xFF69707C);
  static final backgroundColor = Color(0xFF151C24);
  static final thumbGradient = [tickColor, thumbColor];

  static const tickDivisions = 10.0;

  int get tickCount => ((_max - _min) ~/ _step) + 1;

  double get tickLineCount => (tickCount - 1) * tickDivisions;

  late var offsetToPercentageValueBuilder = interpolate(inputMax: trackBounds.height);

  static double Function(double) percentageToValueBuilder(double min, double max, int tickCount) {
    return interpolate(inputMax: tickCount - 1, outputMax: max, outputMin: min);
  }

  static double Function(double) valueToPercentageBuilder(double min, double max) {
    return interpolate(inputMax: max, inputMin: min, outputMin: 1, outputMax: 0);
  }

  late double thumbHeight;
  late Rect thumbBounds;
  late Rect trackBounds;

  double _verticalDragOffset = 0.0;

  void _onTapDown(TapDownDetails details) {
    _verticalDragOffset = details.localPosition.dy;
    _onChangeOffset();
  }

  void _onDragStart(DragStartDetails details) {
    _verticalDragOffset = details.localPosition.dy;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _verticalDragOffset += details.primaryDelta ?? 0.0;
    _onChangeOffset();
  }

  void _onChangeOffset() {
    _value = offsetToPercentageValueBuilder(
      (_verticalDragOffset - (thumbBounds.height / 2)).clamp(0.0, trackBounds.height),
    );
    markNeedsPaint();
  }

  @override
  bool get sizedByParent => true;

  @override
  bool get isRepaintBoundary => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return constraints.biggest;
  }

  @override
  bool hitTestSelf(Offset position) {
    return thumbBounds.contains(position) || trackBounds.contains(position);
  }

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    debugHandleEvent(event, entry);
    if (event is PointerDownEvent) {
      if (thumbBounds.contains(event.localPosition)) {
        drag.addPointer(event);
      } else {
        tap.addPointer(event);
      }
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    debugBounds.add(offset & size);

    final canvas = context.canvas;
    final trackWidth = size.width * .55;
    final labelColumnWidth = size.width - trackWidth;

    thumbHeight = size.height * .1;
    final height = size.height - thumbHeight;

    final bounds = Rect.fromCenter(center: size.center(offset), width: size.width, height: height);
    debugBounds.add(bounds);

    trackBounds = bounds.topLeft & Size(trackWidth, height);
    debugBounds.add(trackBounds);

    thumbBounds = Rect.fromCenter(
      center: Offset(trackBounds.center.dx, bounds.top + _value * height),
      width: trackWidth * 1.25,
      height: thumbHeight,
    );
    debugBounds.add(thumbBounds);

    final tickThickness = trackWidth * .025;
    final tickSpacing = height / tickLineCount;
    final labelFontSize = labelColumnWidth * .3;
    final labelTopRightOffset = bounds.topRight + Offset(labelColumnWidth * -.5, 0);

    for (var i = 0; i < tickLineCount + 1; i++) {
      final isOnBorders = i == 0 || i == tickLineCount;
      final verticalPosition = i * tickSpacing;
      final verticalOffset = Offset(0, verticalPosition);
      final startOffset = bounds.topLeft + verticalOffset;
      final endOffset = startOffset + Offset(trackWidth, 0);
      final inBetween = verticalPosition.between(thumbBounds.center.dy, height);
      canvas.drawLine(
        startOffset,
        endOffset,
        Paint()
          ..color = inBetween ? selectedColor : tickColor
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = isOnBorders ? tickThickness * 2 : tickThickness,
      );

      if (i % tickDivisions != 0) {
        continue;
      }

      final labelBounds = canvas.drawText(
        '${percentageToValueBuilder(_min, _max, tickCount)(tickCount - 1 - (i / tickDivisions)).toInt()}',
        center: labelTopRightOffset + verticalOffset,
        style: TextStyle(
          color: thumbBounds.contains(startOffset) ? selectedColor : labelColor,
          fontSize: labelFontSize,
        ),
      );
      debugBounds.add(labelBounds);
    }

    final trackStrokeWidth = trackWidth * .3;
    canvas.drawLine(
      trackBounds.topCenter,
      trackBounds.bottomCenter,
      Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = trackStrokeWidth,
    );

    canvas.drawLine(
      thumbBounds.center,
      trackBounds.bottomCenter,
      Paint()
        ..color = selectedColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = trackStrokeWidth,
    );

    canvas.drawRect(
      thumbBounds.translate(0, thumbBounds.radius * .65),
      Paint()
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, thumbBounds.radius * .5)
        ..color = Colors.black87,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(thumbBounds, Radius.circular(tickSpacing)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: thumbGradient,
        ).createShader(thumbBounds),
    );

    canvas.drawLine(
      thumbBounds.centerLeft,
      thumbBounds.centerRight,
      Paint()
        ..color = selectedColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = tickThickness * 2,
    );
  }
}

class KnobControlWidget extends LeafRenderObjectWidget {
  const KnobControlWidget({Key? key, required this.value, required this.min, required this.max}) : super(key: key);

  final double value;
  final double max;
  final double min;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderKnobControl(value: value, min: min, max: max);
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderKnobControl renderObject) {
    renderObject
      ..value = value
      ..min = min
      ..max = max;
  }
}

class RenderKnobControl extends RenderBox with RenderBoxDebugBounds {
  RenderKnobControl({required double value, required double min, required double max})
      : _value = valueToAngleBuilder(min, max)(value),
        _min = min,
        _max = max {
    drag = PanGestureRecognizer()
      ..onStart = _onDragStart
      ..onUpdate = _onDragUpdate
      ..onCancel = _onDragCancel
      ..onEnd = (_) => _onDragCancel();
  }

  double _value;

  set value(double value) {
    final angle = valueToAngleBuilder(_min, _max)(value);
    if (_value == angle) {
      return;
    }

    _value = angle;
    markNeedsPaint();
  }

  double _max;

  set max(double value) {
    if (_max == value) {
      return;
    }

    _max = value;
    _value = valueToAngleBuilder(_min, _max)(_value);
    markNeedsPaint();
  }

  double _min;

  set min(double value) {
    if (_min == value) {
      return;
    }

    _min = value;
    _value = valueToAngleBuilder(_min, _max)(_value);
    markNeedsPaint();
  }

  late DragGestureRecognizer drag;

  static final totalAngle = 360.radians;
  static final startAngle = -90.radians;

  static final selectedColor = Color(0xFFFF6E40);
  static final tickColor = Color(0xFF374153);
  static final thumbColor = Color(0xFF29323F);
  static final backgroundColor = Color(0xFF151C24);
  static final thumbGradient = [tickColor, thumbColor];

  static const tickDivisions = 4.0;

  static double Function(double) angleToValueBuilder(double min, double max) {
    return interpolate(inputMax: totalAngle, outputMin: min, outputMax: max);
  }

  static double Function(double) valueToAngleBuilder(double min, double max) {
    return (value) => interpolate(inputMin: min, inputMax: max)(value) * totalAngle;
  }

  late Rect knobBounds;

  Offset _currentDragOffset = Offset.zero;

  void _onDragStart(DragStartDetails details) {
    _currentDragOffset = details.localPosition;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final previousOffset = _currentDragOffset;
    _currentDragOffset += details.delta;
    final diffInAngle = toAngle(_currentDragOffset, knobBounds.center) - toAngle(previousOffset, knobBounds.center);
    final angle = (_value + diffInAngle).normalizeAngle;
    if (angle == _value) {
      return;
    }
    _value = angle;
    markNeedsPaint();
  }

  void _onDragCancel() {
    _currentDragOffset = Offset.zero;
  }

  @override
  bool hitTestSelf(Offset position) {
    return knobBounds.contains(position);
  }

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    if (event is PointerDownEvent) {
      drag.addPointer(event);
    }
  }

  @override
  bool get sizedByParent => true;

  @override
  bool get isRepaintBoundary => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return constraints.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final bounds = offset & size;
    final radius = bounds.radius;
    final center = bounds.center;
    debugBounds.add(bounds);

    canvas.drawCircle(center, radius, Paint()..color = backgroundColor);

    final sweepAngle = _value;
    final endAngle = startAngle + sweepAngle;

    final outerPadding = radius * .045;
    final trackRadius = radius - outerPadding;
    final knobRadius = trackRadius * .8;
    final trackHeight = trackRadius - knobRadius;

    final tickHeight = trackHeight / 2;
    final tickStrokeWidth = trackHeight * .075;
    for (var i = 0; i < totalAngle.degrees / tickDivisions; i++) {
      final angle = startAngle + (i * tickDivisions).radians;
      final isLongTick = startAngle == angle || (angle - endAngle).abs() < 0.01;
      final heightOffset = isLongTick ? 0 : tickHeight * .3;
      final startOffset = center + Offset.fromDirection(angle, trackRadius);
      final endOffset = startOffset + Offset.fromDirection(angle, -tickHeight + heightOffset);
      final inBetween = angle.between(startAngle, endAngle);
      canvas.drawLine(
        startOffset,
        endOffset,
        Paint()
          ..color = inBetween ? selectedColor : tickColor
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = inBetween ? tickStrokeWidth : tickStrokeWidth * .75,
      );
    }

    final trackRingStrokeWidth = trackHeight * .125;
    final trackRingRadius = trackRadius - (trackHeight / 2);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: trackRingRadius - (trackRingStrokeWidth / 2)),
      startAngle,
      totalAngle,
      false,
      Paint()
        ..color = tickColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = trackRingStrokeWidth,
    );

    final selectedArcPath = Path()
      ..moveTo(center.dx, center.dy)
      ..addArc(Rect.fromCircle(center: center, radius: trackRingRadius), startAngle, sweepAngle)
      ..lineTo(center.dx, center.dy)
      ..close();
    debugPaths.add(selectedArcPath);
    canvas.drawPath(selectedArcPath, Paint()..color = selectedColor);
    canvas.drawPath(
      selectedArcPath,
      Paint()
        ..color = selectedColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = tickStrokeWidth,
    );

    knobBounds = Rect.fromCircle(center: center, radius: knobRadius);
    canvas.drawCircle(
      center + Offset.fromDirection(endAngle, knobRadius * .275),
      knobRadius,
      Paint()
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, knobRadius * .25)
        ..color = Colors.black,
    );
    canvas.drawCircle(
      center,
      knobRadius,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: thumbGradient,
          transform: GradientRotation(endAngle - 90.radians),
        ).createShader(knobBounds),
    );

    final indicatorCenter = center + Offset.fromDirection(endAngle, knobRadius * .85);
    canvas.drawCircle(indicatorCenter, knobRadius * .0375, Paint()..color = selectedColor);
    canvas.drawCircle(
      indicatorCenter,
      knobRadius * .05,
      Paint()
        ..color = backgroundColor.withOpacity(.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = knobRadius * .015,
    );

    final value = angleToValueBuilder(_min, _max)(sweepAngle);
    final valueTextSize = knobRadius * .75;
    final captionTextSize = knobRadius * .1;
    final valueTextRect = canvas.drawText(
      '${value.toInt()}',
      center: center.translate(0, -captionTextSize / 2),
      style: TextStyle(color: Colors.white, fontSize: valueTextSize),
    );
    debugBounds.add(valueTextRect);

    final captionTextRect = canvas.drawText(
      'Processing',
      center: center.translate(0, valueTextSize / 2),
      style: TextStyle(
        color: selectedColor.withOpacity(.85),
        fontSize: captionTextSize,
        fontWeight: FontWeight.w500,
        letterSpacing: 1,
      ),
    );
    debugBounds.add(captionTextRect);
  }
}
