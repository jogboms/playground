import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:playground/extensions.dart';

class CircularColorPicker extends StatefulWidget {
  const CircularColorPicker({Key? key}) : super(key: key);

  @override
  _CircularColorPickerState createState() => _CircularColorPickerState();
}

class _CircularColorPickerState extends State<CircularColorPicker> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final width = math.min(MediaQuery.of(context).size.width, 600.0);
    return Scaffold(
      backgroundColor: RenderColorWheel.backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: SizedBox.square(
            dimension: width,
            child: ColorWheel(
              color: Colors.blue,
              startTime: const TimeOfDay(hour: 21, minute: 30),
              endTime: const TimeOfDay(hour: 1, minute: 0),
              child: Icon(Icons.flutter_dash, size: width / 3, color: Colors.black54),
              onChanged: (Color color) {
                // print(color);
              },
            ),
          ),
        ),
      ),
    );
  }
}

class ColorWheel extends SingleChildRenderObjectWidget {
  const ColorWheel({
    Key? key,
    this.color,
    required this.startTime,
    required this.endTime,
    this.onChanged,
    Widget? child,
  }) : super(key: key, child: child);

  final Color? color;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final ValueChanged<Color>? onChanged;

  @override
  RenderColorWheel createRenderObject(BuildContext context) =>
      RenderColorWheel(color: color, startTime: startTime, endTime: endTime).._onChanged = onChanged;

  @override
  void updateRenderObject(BuildContext context, covariant RenderColorWheel renderObject) => renderObject
    ..color = color
    ..startTime = startTime
    ..endTime = endTime
    .._onChanged = onChanged;
}

class RenderColorWheel extends RenderAligningShiftedBox {
  RenderColorWheel({
    required Color? color,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    RenderBox? child,
  })  : _selectedAngle = color != null ? _resolveHueFromColor(color).radians : 0.0,
        _startTime = startTime,
        _endTime = endTime,
        colorsSpectrum = [for (var i = 0; i < maxColorHue; i++) _resolveColorFromHue(i.toDouble())],
        super(alignment: Alignment.center, textDirection: TextDirection.ltr, child: child) {
    tap = TapGestureRecognizer()..onTapDown = _onTapDown;
    drag = PanGestureRecognizer()
      ..onStart = _onDragStart
      ..onUpdate = _onDragUpdate
      ..onCancel = _onDragCancel
      ..onEnd = _onDragEnd;
  }

  static const backgroundColor = Color(0xFF222222);
  static const maxColorHue = 360;

  late final List<Color> colorsSpectrum;
  late final TapGestureRecognizer tap;
  late final DragGestureRecognizer drag;

  double get selectedAngle => _selectedAngle;
  double _selectedAngle;

  set selectedAngle(double selectedAngle) {
    if (_selectedAngle == selectedAngle) {
      return;
    }

    _selectedAngle = selectedAngle;
    markNeedsPaint();
  }

  Color get _color => _resolveColorFromHue(selectedAngle.degrees);

  set color(Color? color) => selectedAngle = color != null ? _resolveHueFromColor(color).radians : 0.0;

  TimeOfDay get startTime => _startTime;
  TimeOfDay _startTime;

  set startTime(TimeOfDay startTime) {
    if (_startTime == startTime) {
      return;
    }

    _startTime = startTime;
    markNeedsPaint();
  }

  TimeOfDay get endTime => _endTime;
  TimeOfDay _endTime;

  set endTime(TimeOfDay endTime) {
    if (_endTime == endTime) {
      return;
    }

    _endTime = endTime;
    markNeedsPaint();
  }

  ValueChanged<Color>? _onChanged;

  late Path _trackPath;

  Offset _currentDragOffset = Offset.zero;

  void _onDragStart(DragStartDetails details) => _currentDragOffset = globalToLocal(details.globalPosition);

  void _onDragUpdate(DragUpdateDetails details) {
    final previousOffset = _currentDragOffset;
    _currentDragOffset += details.delta;
    final center = size.center(Offset.zero);
    _onChangeAngle(selectedAngle + toAngle(_currentDragOffset, center) - toAngle(previousOffset, center));
  }

  void _onDragCancel() => _currentDragOffset = Offset.zero;

  void _onDragEnd(DragEndDetails details) => _onDragCancel();

  void _onTapDown(TapDownDetails details) => _onChangeAngle(toAngle(details.localPosition, size.center(Offset.zero)));

  void _onChangeAngle(double angle) {
    selectedAngle = angle.normalizeAngle;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      HapticFeedback.selectionClick();
      _onChanged?.call(_color);
    });
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  BoxConstraints get constraints => super.constraints.loosen();

  Size computeSize(BoxConstraints constraints) =>
      Size.square(math.min(constraints.constrainWidth(), constraints.constrainHeight()));

  @override
  void performLayout() {
    size = computeSize(constraints);
    if (child != null) {
      final maxSize = Size.fromRadius(size.radius * .4125);
      child?.layout(BoxConstraints.tight(maxSize), parentUsesSize: true);
      alignChild();
    }
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => computeSize(constraints);

  @override
  bool hitTestSelf(Offset position) => _trackPath.contains(position);

  @override
  void handleEvent(PointerEvent event, covariant BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is PointerDownEvent && _trackPath.contains(event.localPosition)) {
      tap.addPointer(event);
      drag.addPointer(event);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final bounds = offset & size;

    // Outer Ticks
    const outerTickWidth = 2.5;
    final outerTickLength = size.radius * .05;
    final outerTickPaint = Paint()..color = Colors.grey.shade800;
    for (var i = 0; i < 60; i++) {
      final unitVector = Offset.fromDirection(i.radians * 6);
      final center = bounds.center + (unitVector * bounds.radius);
      if (i % 5 == 0) {
        final offset = unitVector * outerTickLength / 2;
        canvas.drawLine(center - offset, center + offset, outerTickPaint..strokeWidth = outerTickWidth * 2.5);
      } else {
        final offset = unitVector * outerTickLength * .65 / 2;
        canvas.drawLine(center - offset, center + offset, outerTickPaint..strokeWidth = outerTickWidth);
      }
    }

    // Track
    final trackThickness = outerTickLength * 3;
    const trackRadius = Radius.circular(1);
    final trackBounds = bounds.deflate(outerTickLength * 1.5);
    _trackPath = Path()
      ..moveTo(trackBounds.topCenter.dx, trackBounds.topCenter.dy + trackThickness)
      ..arcToPoint(trackBounds.bottomCenter.translate(0, -trackThickness), radius: trackRadius)
      ..arcToPoint(trackBounds.topCenter.translate(0, trackThickness), radius: trackRadius)
      ..moveTo(trackBounds.topCenter.dx, trackBounds.topCenter.dy)
      ..arcToPoint(trackBounds.bottomCenter, radius: trackRadius, clockwise: false)
      ..arcToPoint(trackBounds.topCenter, radius: trackRadius, clockwise: false);
    canvas.drawPath(
      _trackPath,
      Paint()..shader = SweepGradient(colors: colorsSpectrum).createShader(_trackPath.getBounds()),
    );

    // Inner Ticks
    final innerTickPadding = outerTickLength * .8;
    final innerTickLength = outerTickLength * .85;
    final innerTickColor = Color.lerp(outerTickPaint.color, Colors.white, .45)!;
    final innerTickRadius = trackBounds.radius - trackThickness - innerTickPadding;
    for (var i = 0; i < 24; i++) {
      final unitVector = Offset.fromDirection(i.radians * 15);
      final center = trackBounds.center + (unitVector * (innerTickRadius - (innerTickLength / 2)));
      final offset = unitVector * innerTickLength / 2;
      canvas.drawLine(
        center - offset,
        center + offset,
        Paint()
          ..color = innerTickColor
          ..strokeWidth = outerTickWidth,
      );
    }
    // Inner Ticks Track
    canvas.drawCircle(
      trackBounds.center,
      innerTickRadius - outerTickWidth,
      Paint()
        ..color = outerTickPaint.color
        ..strokeWidth = outerTickWidth * 2
        ..style = PaintingStyle.stroke,
    );

    // Inner Progress
    canvas.drawArc(
      Rect.fromCircle(center: trackBounds.center, radius: innerTickRadius - (outerTickWidth * 2)),
      (((startTime.fraction - 12).abs() * 30) - 90).radians,
      ((24 - startTime.fraction + endTime.fraction) * 30).radians,
      false,
      Paint()
        ..color = innerTickColor
        ..strokeWidth = outerTickWidth * 4
        ..style = PaintingStyle.stroke,
    );

    // Knob
    final knobCenter =
        trackBounds.center + Offset.fromDirection(selectedAngle, (trackBounds.width - trackThickness) / 2);
    canvas
      ..drawCircle(knobCenter, trackThickness + (outerTickWidth * 2.5), Paint()..color = backgroundColor)
      ..drawCircle(knobCenter, trackThickness, Paint()..color = _color);

    // Indicator
    if (child != null) {
      final childOffset = (child!.parentData! as BoxParentData).offset;
      final childBounds = childOffset & child!.size;
      canvas
        ..save()
        ..clipPath(Path()
          ..moveTo(childOffset.dx, childOffset.dy)
          ..addOval(childBounds))
        ..drawRect(childBounds, Paint()..color = _color);
      super.paint(context, offset);
      canvas.restore();
    }
  }
}

Color _resolveColorFromHue(double value) => HSLColor.fromAHSL(1, value, .85, .6).toColor();

double _resolveHueFromColor(Color color) => HSLColor.fromColor(color).hue;

extension on TimeOfDay {
  double get fraction => hour + (minute / TimeOfDay.minutesPerHour);
}
