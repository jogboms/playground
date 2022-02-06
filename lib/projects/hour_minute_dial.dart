import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../extensions.dart';

class HourMinuteDial extends StatefulWidget {
  const HourMinuteDial({Key? key}) : super(key: key);

  @override
  _HourMinuteDialState createState() => _HourMinuteDialState();
}

class _HourMinuteDialState extends State<HourMinuteDial> with TickerProviderStateMixin {
  static const initialTime = TimeValue(12, 15);
  final valueNotifier = ValueNotifier(initialTime);
  TimeOfDayType _timeOfDay = TimeOfDayType.am;

  final DecorationTween decorationTween = DecorationTween(
    begin: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.orangeAccent, Color(0xFFBF360C)],
      ),
    ),
    end: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.blueAccent, Color(0xFF16263A)],
      ),
    ),
  );

  late AnimationController _controller;

  void _animate(int index) {
    if (index == 0) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  @override
  void initState() {
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _animate(_timeOfDay.index);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBoxTransition(
        decoration: decorationTween.animate(_controller),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DialWidget(
              vsync: this,
              time: initialTime,
              onChanged: (time) {
                valueNotifier.value = time;
              },
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ValueListenableBuilder(
                  valueListenable: valueNotifier,
                  builder: (_, TimeValue time, __) {
                    return Text(
                      '${time.hour}'.padLeft(2, '0') + ':' + '${time.minute}'.padLeft(2, '0'),
                      style: Theme.of(context)
                          .textTheme
                          .headline3!
                          .copyWith(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2),
                    );
                  },
                ),
                const SizedBox(width: 24),
                TimeOfDayWidget(
                  vsync: this,
                  value: _timeOfDay,
                  onChanged: (value) {
                    _timeOfDay = value;
                    _animate(value.index);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TimeOfDayWidget extends LeafRenderObjectWidget {
  const TimeOfDayWidget({Key? key, required this.vsync, required this.value, required this.onChanged})
      : super(key: key);

  final TickerProvider vsync;
  final TimeOfDayType value;
  final ValueChanged<TimeOfDayType> onChanged;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return TimeOfDayRenderBox(vsync: vsync, value: value, onChanged: onChanged);
  }

  @override
  void updateRenderObject(BuildContext context, covariant TimeOfDayRenderBox renderObject) {
    renderObject
      ..value = value
      ..onChanged = onChanged;
  }
}

enum TimeOfDayType { am, pm }

class TimeOfDayRenderBox extends RenderBox {
  TimeOfDayRenderBox({
    required this.vsync,
    required TimeOfDayType value,
    required ValueChanged<TimeOfDayType> onChanged,
  })  : _value = value,
        _onChanged = onChanged {
    gesture = TapGestureRecognizer()..onTapUp = _onTapUp;
    _selectedIndex = value.index;
  }

  final TickerProvider vsync;

  ValueChanged<TimeOfDayType> _onChanged;

  set onChanged(ValueChanged<TimeOfDayType> onChanged) {
    _onChanged = onChanged;
  }

  TimeOfDayType _value;

  set value(TimeOfDayType value) {
    if (_value == value) {
      return;
    }
    markNeedsPaint();
    _value = value;
  }

  late TapGestureRecognizer gesture;

  static Color fontColor = Colors.white;
  static Color selectedFontColor = Colors.black;

  int? _selectedIndex;
  Offset? _selectedCenter;

  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void attach(covariant PipelineOwner owner) {
    super.attach(owner);

    _controller = AnimationController(vsync: vsync);
    _controller.addListener(() {
      _selectedCenter = _animation.value;
      markNeedsPaint();
    });
  }

  @override
  void detach() {
    _controller.dispose();
    super.detach();
  }

  @override
  BoxConstraints get constraints => super.constraints.copyWith(maxHeight: 40, maxWidth: 80);

  @override
  void performLayout() {
    size = constraints.biggest;
    _selectedCenter = _deriveCenterFromType(_value);
  }

  @override
  bool hitTestSelf(ui.Offset position) {
    return true;
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is PointerDownEvent) {
      gesture.addPointer(event);
    }
  }

  TimeOfDayType _deriveValueFromIndex(int index) {
    return index == 0 ? TimeOfDayType.am : TimeOfDayType.pm;
  }

  double _deriveHorizontalCenterFromIndex(int index) {
    return (size.width / 4) * ((index * 2) + 1);
  }

  Offset _deriveCenterFromIndex(int index) {
    return Offset(_deriveHorizontalCenterFromIndex(index), size.height / 2);
  }

  Offset _deriveCenterFromType(TimeOfDayType type) {
    return _deriveCenterFromIndex(type.index);
  }

  void _onTapUp(TapUpDetails details) {
    final offset = globalToLocal(details.globalPosition);
    _animate(Offset.zero, offset.dx ~/ (size.width / 2));
  }

  void _animate(Offset pixelsPerSecond, int index) {
    final finalOffset = _deriveCenterFromIndex(index);
    final tween = Tween(begin: _selectedCenter, end: finalOffset).chain(CurveTween(curve: Curves.easeIn));
    _animation = _controller.drive(tween);

    final unitsPerSecond = Offset(
      pixelsPerSecond.dx / size.width,
      pixelsPerSecond.dy / size.height,
    );

    _controller
        .animateWith(
          SpringSimulation(
            SpringDescription(mass: size.width, stiffness: 1.0, damping: 1.0),
            0,
            1,
            -unitsPerSecond.distance,
          ),
        )
        .whenCompleteOrCancel(() => _onSelect(index));
  }

  void _onSelect(int index) {
    _selectedIndex = index;
    final value = _deriveValueFromIndex(index);
    if (value == _value) {
      return;
    }
    _value = value;
    HapticFeedback.selectionClick();
    _onChanged(_value);
  }

  @override
  void paint(PaintingContext context, ui.Offset offset) {
    final radius = size.height / 2;
    const deltaDy = -2;
    final rect = offset & size;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTRB(rect.left, rect.top - deltaDy, rect.right, rect.bottom + deltaDy),
      Radius.circular(radius),
    );
    context.canvas.drawRRect(rrect, Paint()..color = const Color(0x2C000000));

    context.canvas.drawCircle(
      _selectedCenter!,
      radius,
      Paint()..color = fontColor,
    );

    final derivedFontSize = size.height * 1 / 3;
    _drawParagraph(
      context.canvas,
      'AM',
      offset: _deriveCenterFromIndex(0),
      fontSize: derivedFontSize,
      color: _selectedIndex == 0 ? selectedFontColor : fontColor,
    );
    _drawParagraph(
      context.canvas,
      'PM',
      offset: _deriveCenterFromIndex(1),
      fontSize: derivedFontSize,
      color: _selectedIndex == 1 ? selectedFontColor : fontColor,
    );
  }

  void _drawParagraph(Canvas canvas, String text,
      {required Offset offset, required Color color, required double fontSize}) {
    final paragraphConstraints = ui.ParagraphConstraints(width: fontSize * text.length);
    final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.center))
      ..pushStyle(ui.TextStyle(fontSize: fontSize, color: color, fontWeight: FontWeight.bold))
      ..addText(text);
    canvas.drawParagraph(
      paragraphBuilder.build()..layout(paragraphConstraints),
      offset - Offset(paragraphConstraints.width / 2, fontSize / 2),
    );
  }
}

class DialWidget extends LeafRenderObjectWidget {
  const DialWidget({Key? key, required this.onChanged, required this.vsync, required this.time}) : super(key: key);

  final TimeValueChanged onChanged;
  final TickerProvider vsync;
  final TimeValue time;

  @override
  DialRenderBox createRenderObject(BuildContext context) {
    return DialRenderBox(onChanged: onChanged, time: time, vsync: vsync);
  }

  @override
  void updateRenderObject(BuildContext context, covariant DialRenderBox renderObject) {
    renderObject
      ..onChanged = onChanged
      ..time = time;
  }
}

enum KnobIndicatorAlignment {
  top,
  bottom,
}

typedef TimeValueChanged = void Function(TimeValue time);

class DialParentData extends ContainerBoxParentData<DialItemRenderBox> {}

class DialItemRenderBox extends RenderBox {
  DialItemRenderBox({
    required int value,
    required this.vsync,
    required this.color,
    required this.debugLabel,
    required this.padding,
    required this.alignment,
    required this.start,
    required this.interval,
    required this.onChanged,
  }) {
    drag = PanGestureRecognizer()
      ..onStart = _onDragStart
      ..onEnd = _onDragEnd
      ..onCancel = _onDragCancel
      ..onUpdate = _onDragUpdate;

    _currentAngle = _deriveRestingAngleFromValue(value);
    _value = value;
  }

  final TickerProvider vsync;
  final String debugLabel;
  final double padding;
  final KnobIndicatorAlignment alignment;
  final int start;
  final int interval;
  final ValueChanged<int> onChanged;
  final Color color;

  late DragGestureRecognizer drag;

  late AnimationController _controller;
  late Animation<double> _animation;

  late Offset center;
  late double height;
  late double radius;
  late Path circularPath;

  Offset _currentDragOffset = Offset.zero;
  double _currentAngle = 0.0;
  int? _value;

  static double fontSize = 20.0;
  static Color fontColor = Colors.white;
  static double indicatorHeight = 16.0;

  static int divisions = 12;
  final totalAngle = 360.radians;

  @override
  void attach(covariant PipelineOwner owner) {
    super.attach(owner);

    _controller = AnimationController(vsync: vsync);
    _controller.addListener(() {
      _currentAngle = _animation.value;
      markNeedsPaint();
    });
  }

  @override
  void detach() {
    _controller.dispose();
    super.detach();
  }

  @override
  bool get sizedByParent => true;

  @override
  ui.Size computeDryLayout(BoxConstraints constraints) {
    return constraints.biggest;
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  bool hitTestSelf(Offset position) {
    return circularPath.contains(globalToLocal(position));
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is PointerDownEvent) {
      drag.addPointer(event);
    }
  }

  int get _selectedIndexSegment {
    return (_currentAngle / (totalAngle / divisions)).round();
  }

  int _normalizeSelectedIndex(int segment) {
    return (divisions - (segment % divisions)) % divisions;
  }

  int _deriveValueFromIndex(int index) {
    return (index * interval) + start;
  }

  double _deriveRestingAngleFromValue(int value) {
    final index = _normalizeSelectedIndex(((value - start) / interval).round());
    return _deriveRestingAngleFromSegment(index);
  }

  double _deriveRestingAngleFromSegment(int segment) {
    return segment * (totalAngle / divisions);
  }

  void _animate(Offset pixelsPerSecond) {
    final restingAngle = _deriveRestingAngleFromSegment(_selectedIndexSegment);
    final tween = Tween(begin: _currentAngle, end: restingAngle).chain(CurveTween(curve: Curves.easeIn));
    _animation = _controller.drive(tween);

    final unitsPerSecond = Offset(
      pixelsPerSecond.dx / size.width,
      pixelsPerSecond.dy / size.height,
    );

    _controller
        .animateWith(
      SpringSimulation(
        const SpringDescription(mass: 30.0, stiffness: 1.0, damping: 1.0),
        0,
        1,
        -unitsPerSecond.distance,
      ),
    )
        .whenCompleteOrCancel(() {
      _onDragCancel();
      _onAngleChanged(restingAngle);
    });
  }

  void _onDragStart(DragStartDetails details) {
    _currentDragOffset = globalToLocal(details.globalPosition);
  }

  void _onDragEnd(DragEndDetails details) {
    _animate(details.velocity.pixelsPerSecond);
  }

  void _onDragCancel() {
    _currentDragOffset = Offset.zero;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final previousOffset = _currentDragOffset;
    _currentDragOffset += details.delta;
    final center = Offset(size.radius, size.radius);
    final diffInAngle = toAngle(previousOffset, center) - toAngle(_currentDragOffset, center);
    _onAngleChanged(normalizeAngle(_currentAngle + diffInAngle));
  }

  void _onAngleChanged(double value) {
    if (value == _currentAngle) {
      return;
    }
    _currentAngle = value;
    final index = _normalizeSelectedIndex(_selectedIndexSegment);
    _onSelect(_deriveValueFromIndex(index));
    markNeedsPaint();
  }

  void _onSelect(int value) {
    if (value == _value) {
      return;
    }
    _value = value;
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      HapticFeedback.selectionClick();
      onChanged(_value!);
    });
  }

  void onLayout(ui.Size size, ui.Offset offset) {
    center = size.center(offset) - offset;
    height = fontSize + padding * 2;
    radius = size.height / 2;
    final innerRadius = radius - height;
    circularPath = Path()
      ..moveTo(center.dx + radius, center.dy)
      ..relativeArcToPoint(Offset(-radius * 2, 0), radius: Radius.circular(radius))
      ..relativeArcToPoint(Offset(radius * 2, 0), radius: Radius.circular(radius))
      ..relativeMoveTo(-height, 0)
      ..relativeArcToPoint(Offset(-innerRadius * 2, 0), radius: Radius.circular(innerRadius), clockwise: false)
      ..relativeArcToPoint(Offset(innerRadius * 2, 0), radius: Radius.circular(innerRadius), clockwise: false);

    // NOTE: circularPath could also be calculated as thus but
    // no support for Path.combine on the web as it when this was first written
    // circularPath = Path.combine(
    //   PathOperation.difference,
    //   Path()
    //     ..moveTo(center.dx, center.dy)
    //     ..addOval(Rect.fromCircle(center: center, radius: radius)),
    //   Path()
    //     ..moveTo(center.dx, center.dy)
    //     ..addOval(Rect.fromCircle(center: center, radius: radius - height)),
    // );
  }

  @override
  void paint(PaintingContext context, ui.Offset offset) {
    final canvas = context.canvas;
    canvas.drawPath(circularPath, Paint()..color = color);

    final rotationAngleOffset = 270.radians;
    final startingAngleOffset = 90.radians;
    for (var i = 0; i < divisions; i++) {
      canvas.save();

      final currentAngle = startingAngleOffset - ((i * totalAngle / divisions) + _currentAngle);
      final startingOffset = toPolar(center, currentAngle, radius - fontSize - padding);
      final rotationAngle = currentAngle + rotationAngleOffset;
      canvas.translate(startingOffset.dx, startingOffset.dy);
      canvas.rotate(rotationAngle);
      canvas.translate(-startingOffset.dx, -startingOffset.dy);

      _drawParagraph(
        canvas,
        _deriveValueFromIndex(i).toString().padLeft(2, '0'),
        offset: startingOffset,
      );

      canvas.restore();
    }

    canvas.drawPath(_createIndicatorPath(), Paint()..color = fontColor);
  }

  Path _createIndicatorPath() {
    final indicatorSize = Size(indicatorHeight * 3 / 4, indicatorHeight);
    final indicatorRadius = indicatorSize / 2;
    final indicatorOffset = indicatorHeight / 2;
    switch (alignment) {
      case KnobIndicatorAlignment.top:
        return Path()
          ..moveTo(
            center.dx - indicatorRadius.width,
            center.dy + radius - height - indicatorSize.height - indicatorOffset,
          )
          ..relativeLineTo(indicatorSize.width, 0)
          ..relativeLineTo(-indicatorRadius.width, indicatorSize.height)
          ..relativeLineTo(-indicatorRadius.width, -indicatorSize.height)
          ..close();
      case KnobIndicatorAlignment.bottom:
      default:
        return Path()
          ..moveTo(center.dx, center.dy + radius + indicatorOffset)
          ..relativeLineTo(indicatorRadius.width, indicatorSize.height)
          ..relativeLineTo(-indicatorSize.width, 0)
          ..relativeLineTo(indicatorRadius.width, -indicatorSize.height)
          ..close();
    }
  }

  void _drawParagraph(Canvas canvas, String text, {required Offset offset}) {
    final paragraphConstraints = ui.ParagraphConstraints(width: fontSize * text.length);
    final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.center))
      ..pushStyle(ui.TextStyle(fontSize: fontSize, color: fontColor, fontWeight: FontWeight.bold))
      ..addText(text);
    canvas.drawParagraph(
      paragraphBuilder.build()..layout(paragraphConstraints),
      offset - Offset(paragraphConstraints.width / 2, 0),
    );
  }
}

class DialRenderBox extends RenderBox with ContainerRenderObjectMixin<DialItemRenderBox, DialParentData> {
  DialRenderBox({
    required TimeValueChanged onChanged,
    required TickerProvider vsync,
    required TimeValue time,
  }) : _onChanged = onChanged {
    add(DialItemRenderBox(
      debugLabel: 'Hour',
      vsync: vsync,
      padding: 16,
      color: const Color(0x00000000),
      alignment: KnobIndicatorAlignment.top,
      value: time.hour,
      start: 1,
      interval: 1,
      onChanged: _onChangedHour,
    ));
    add(DialItemRenderBox(
      debugLabel: 'Minute',
      vsync: vsync,
      padding: 24,
      color: const Color(0x1C000000),
      alignment: KnobIndicatorAlignment.bottom,
      value: time.minute,
      start: 0,
      interval: 5,
      onChanged: _onChangedMinute,
    ));
  }

  TimeValueChanged _onChanged;

  set onChanged(TimeValueChanged value) {
    if (_onChanged == value) {
      return;
    }
    _onChanged = value;
  }

  TimeValue _time = const TimeValue(0, 0);

  set time(TimeValue value) {
    if (_time == value) {
      return;
    }
    _time = value;
  }

  void _onChangedHour(int value) {
    _time = TimeValue(value, _time.minute);
    _onChanged(_time);
  }

  void _onChangedMinute(int value) {
    _time = TimeValue(_time.hour, value);
    _onChanged(_time);
  }

  @override
  void setupParentData(DialItemRenderBox child) {
    if (child.parentData is! DialParentData) {
      child.parentData = DialParentData();
    }
  }

  Size computeSize(BoxConstraints constraints) {
    final tempFirstChildRadius = constraints.biggest.width / 2;
    final firstChildRadius = math.min(tempFirstChildRadius, 240.0);
    const horizontalOffset = 16.0;

    var child = firstChild;
    double? previousRadius;
    double? firstRadius;
    Offset? firstCenter;
    while (child != null) {
      final childHeight = DialItemRenderBox.fontSize + (child.padding * 2);
      final childRadius = previousRadius != null ? previousRadius + childHeight : firstChildRadius - horizontalOffset;
      final childSize = Size.fromRadius(childRadius);
      final center = Offset(firstChildRadius, firstRadius ?? childRadius);

      final childParentData = child.parentData! as DialParentData;
      childParentData.offset = Offset(center.dx - childRadius, center.dy - childRadius);

      child.layout(BoxConstraints.tight(childSize));
      child.onLayout(childSize, childParentData.offset);
      child = childParentData.nextSibling;
      previousRadius = childRadius;
      firstCenter ??= center;
      firstRadius ??= childRadius;
    }

    return Size(firstChildRadius * 2, firstRadius! + previousRadius! + (DialItemRenderBox.indicatorHeight * 5 / 2));
  }

  @override
  ui.Size computeDryLayout(BoxConstraints constraints) {
    return computeSize(constraints);
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  bool hitTestChildren(BoxHitTestResult result, {Offset? position}) {
    var child = lastChild;
    while (child != null) {
      if (child.hitTest(result, position: position!)) {
        return true;
      }
      child = (child.parentData! as DialParentData).previousSibling;
    }
    return false;
  }

  @override
  void performLayout() {
    size = computeSize(constraints);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.canvas.drawCircle(
      firstChild!.center + (firstChild!.parentData! as DialParentData).offset,
      firstChild!.radius,
      Paint()..color = Colors.black26,
    );

    var child = firstChild;
    while (child != null) {
      final childParentData = child.parentData! as DialParentData;
      final childOffset = childParentData.offset + offset;
      context.paintChild(child, childOffset);

      child = childParentData.nextSibling;
    }
  }
}

class TimeValue {
  const TimeValue(this.hour, this.minute);

  final int hour;
  final int minute;
}
