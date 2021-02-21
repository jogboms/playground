import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../extensions.dart';
import '../interpolate.dart';

class ProgressDial extends StatefulWidget {
  @override
  _ProgressDialState createState() => _ProgressDialState();
}

class _ProgressDialState extends State<ProgressDial> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2C2F3E),
      body: Center(
        child: ProgressDialWidget(
          onChanged: (value) {
            print(value);
          },
        ),
      ),
    );
  }
}

class ProgressDialWidget extends LeafRenderObjectWidget {
  const ProgressDialWidget({Key key, this.onChanged}) : super(key: key);

  final ValueChanged<int> onChanged;

  @override
  RenderProgressDial createRenderObject(BuildContext context) {
    return RenderProgressDial(onChanged: onChanged);
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderProgressDial renderObject) {
    renderObject..onChanged = onChanged;
  }
}

class RenderProgressDial extends RenderBox {
  RenderProgressDial({
    ValueChanged<int> onChanged,
  }) : _onChanged = onChanged {
    drag = PanGestureRecognizer()
      ..onStart = _onDragStart
      ..onUpdate = _onDragUpdate
      ..onCancel = _onDragCancel
      ..onEnd = _onDragEnd;
    valueBuilder = interpolate(inputMax: totalAngle, outputMin: 0, outputMax: 40);
  }

  DragGestureRecognizer drag;
  Rect knobRect;
  double Function(double input) valueBuilder;

  static final totalAngle = 360.radians;
  static final startAngle = -90.radians;
  static final shadowColor = Color(0xFF272A39);
  static final labelColor = Colors.white30;
  static const titleFontRadius = 30.0;
  static const labelFontRadius = titleFontRadius / 4.5;

  static const minRadius = 100.0;
  static const maxRadius = 180.0;

  ValueChanged<int> _onChanged;

  set onChanged(ValueChanged<int> onChanged) {
    if (_onChanged == onChanged) {
      return;
    }
    _onChanged = onChanged;
  }

  Offset _currentDragOffset = Offset.zero;
  double _currentAngle = 0.0;
  int _value;

  void _onDragStart(DragStartDetails details) {
    _currentDragOffset = globalToLocal(details.globalPosition);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final previousOffset = _currentDragOffset;
    _currentDragOffset += details.delta;
    final center = Offset(size.radius, size.radius);
    final diffInAngle = toAngle(_currentDragOffset, center) - toAngle(previousOffset, center);
    _onAngleChanged((_currentAngle + diffInAngle).normalize(totalAngle).toDouble());
  }

  void _onDragCancel() {
    _currentDragOffset = Offset.zero;
  }

  void _onDragEnd(DragEndDetails details) {
    _onDragCancel();
  }

  void _onAngleChanged(double value) {
    if (value == _currentAngle) {
      return;
    }
    _currentAngle = value;
    _onSelect(valueBuilder(value).round());
    markNeedsPaint();
  }

  void _onSelect(int value) {
    if (value == _value) {
      return;
    }
    _value = value;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      HapticFeedback.selectionClick();
      _onChanged?.call(_value);
    });
  }

  @override
  bool hitTestSelf(ui.Offset position) {
    return knobRect.contains(localToGlobal(position));
  }

  @override
  void handleEvent(PointerEvent event, covariant BoxHitTestEntry entry) {
    if (event is PointerDownEvent) {
      drag.addPointer(event);
    }
  }

  Size computeSize(BoxConstraints constraints) {
    final effectiveConstraints = constraints.enforce(BoxConstraints(
      minHeight: minRadius * 2,
      minWidth: minRadius * 2,
      maxHeight: maxRadius * 2,
      maxWidth: maxRadius * 2,
    ));
    return Size.square(effectiveConstraints.constrainWidth());
  }

  @override
  ui.Size computeDryLayout(BoxConstraints constraints) {
    return computeSize(constraints);
  }

  @override
  void performLayout() {
    size = computeSize(constraints);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final center = size.center(offset);
    final segment = size.radius / 6;

    // Base
    final outerRadius = segment * 6;
    const division = 10;
    for (var i = 0; i < division; i++) {
      final it = (i * totalAngle.degrees / division).radians;
      _drawParagraph(
        canvas,
        valueBuilder(it).round().toString(),
        offset: toPolar(center, it + startAngle, outerRadius),
        color: labelColor,
        fontSize: labelFontRadius * 2,
      );
    }

    // Mid-region
    final midCircleRadius = segment * 5;
    final midRect = Rect.fromCircle(center: center, radius: midCircleRadius);
    _drawShadow(canvas, midRect, shadowColor);
    canvas.drawCircle(center, midCircleRadius, Paint()..color = Color(0xFF323544));

    // Progress
    final angle = _currentAngle;
    final sweepAngle = math.max(angle, 0.001);
    final gradientShader = SweepGradient(
      endAngle: sweepAngle,
      tileMode: TileMode.mirror,
      transform: GradientRotation(startAngle),
      colors: [Color(0xFF626BFC), Colors.purpleAccent],
    ).createShader(midRect);
    final strokeWidth = segment / 3;
    final progressShadowElevation = strokeWidth * .15;
    // Progress arc glow
    canvas.drawArc(
      midRect,
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..imageFilter = ui.ImageFilter.blur(sigmaX: progressShadowElevation, sigmaY: progressShadowElevation)
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..shader = gradientShader,
    );
    // Progress arc
    canvas.drawArc(
      midRect,
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..shader = gradientShader,
    );

    // Progress Indicator
    final progressIndicatorRadius = strokeWidth / 2;
    final progressIndicatorCenter = toPolar(center, startAngle, midRect.radius);
    _drawShadow(
      canvas,
      Rect.fromCircle(center: progressIndicatorCenter, radius: progressIndicatorRadius),
      Colors.white,
      useCenter: true,
      elevation: progressIndicatorRadius * 3,
    );
    canvas.drawCircle(progressIndicatorCenter, progressIndicatorRadius * 2, Paint()..color = Color(0xFF626BFC));
    canvas.drawCircle(progressIndicatorCenter, progressIndicatorRadius, Paint()..color = Colors.white);

    // Knob
    final knobRadius = segment * 3.5;
    knobRect = Rect.fromCircle(center: center, radius: knobRadius);
    _drawShadow(canvas, knobRect, shadowColor);
    canvas.drawCircle(
      center,
      knobRadius,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF4A4C62), Color(0xFF37384B)],
        ).createShader(knobRect),
    );

    // Indicator
    final indicatorRadius = strokeWidth / 3;
    final indicatorCenter = toPolar(center, angle + startAngle, knobRadius - 16.0);
    _drawShadow(
      canvas,
      Rect.fromCircle(center: indicatorCenter, radius: indicatorRadius),
      Colors.white,
      useCenter: true,
      elevation: indicatorRadius * 3,
    );
    canvas.drawCircle(indicatorCenter, indicatorRadius, Paint()..color = Colors.white);

    // Value
    final titleRect = _drawParagraph(
      canvas,
      valueBuilder(angle).round().toString(),
      offset: center - Offset(0, titleFontRadius),
      color: Colors.white,
      fontSize: titleFontRadius * 2,
    );
    _drawParagraph(
      canvas,
      'C',
      offset: titleRect.topRight + Offset(labelFontRadius * 2, labelFontRadius * 2),
      color: labelColor,
      fontSize: labelFontRadius * 2,
    );
    _drawParagraph(
      canvas,
      'ROOM\nTEMPERATURE',
      offset: center + Offset(0, 16.0),
      color: labelColor,
      fontSize: labelFontRadius * 2,
    );
  }

  void _drawShadow(Canvas canvas, Rect rect, Color color, {bool useCenter = false, double elevation}) {
    elevation ??= rect.radius * .25;
    canvas.drawShadow(Path()..addOval(rect.translate(0, useCenter ? -elevation : 0)), color, elevation, false);
  }

  Rect _drawParagraph(Canvas canvas, String text,
      {@required Offset offset, @required Color color, @required double fontSize}) {
    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.center))
      ..pushStyle(ui.TextStyle(fontSize: fontSize, color: color, fontWeight: FontWeight.w600))
      ..addText(text);
    final paragraph = builder.build();
    final constraints = ui.ParagraphConstraints(width: (fontSize / 1.25) * text.length);
    final finalOffset = offset - Offset(constraints.width / 2, fontSize / 2);
    canvas.drawParagraph(paragraph..layout(constraints), finalOffset);
    return Rect.fromLTWH(finalOffset.dx, finalOffset.dy, paragraph.longestLine, paragraph.height);
  }
}
