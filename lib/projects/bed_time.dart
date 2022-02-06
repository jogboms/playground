import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../extensions.dart';

class BedTime extends StatefulWidget {
  const BedTime({Key? key}) : super(key: key);

  @override
  _BedTimeState createState() => _BedTimeState();
}

class _BedTimeState extends State<BedTime> {
  final Color mutedTextColor = const Color(0xFF9D9EA2);
  final double threshold = 8.0;

  TimeOfDay _bedTime = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 6, minute: 0);

  TimeOfDay get _sleepTime => _bedTime.subtract(_wakeTime);

  String _addZeroes(int value) => value.toString().padLeft(2, '0');

  Widget _buildTopTitle(String title, IconData icon, TimeOfDay time) {
    return Column(
      children: [
        Text.rich(
          TextSpan(children: [
            WidgetSpan(child: Icon(icon, size: 18, color: mutedTextColor)),
            TextSpan(
              text: ' $title',
              style: TextStyle(fontSize: 18, color: mutedTextColor, fontWeight: FontWeight.w500),
            ),
          ]),
        ),
        const SizedBox(height: 4),
        Text(
          '${time.hourOfPeriod == 0 ? 12 : _addZeroes(time.hourOfPeriod)}:${_addZeroes(time.minute)} ${time.periodShort.toUpperCase()}',
          style: const TextStyle(fontSize: 28, color: Color(0xFFFFFFFF), fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C2C2E),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTopTitle('BEDTIME', Icons.king_bed_rounded, _bedTime),
                const SizedBox(width: 32),
                _buildTopTitle('WAKE UP', Icons.notifications, _wakeTime),
              ],
            ),
            const SizedBox(height: 24),
            BedTimeWidget(
              bedTime: _bedTime,
              wakeTime: _wakeTime,
              threshold: threshold,
              onChange: (TimeOfDay bedTime, TimeOfDay wakeTime) {
                setState(() {
                  _bedTime = bedTime;
                  _wakeTime = wakeTime;
                });
              },
            ),
            const SizedBox(height: 24),
            Text(
              '${_sleepTime.hour} hr' + (_sleepTime.minute > 0 ? ' ${_sleepTime.minute} min' : ''),
              style: const TextStyle(fontSize: 24, color: Color(0xFFFFFFFF), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text(
              _sleepTime.hour > threshold
                  ? 'This schedule does not meet your sleep goal.'
                  : 'This schedule meets your sleep goal.',
              style: TextStyle(color: mutedTextColor, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

typedef BedTimeCallback = void Function(TimeOfDay bedTime, TimeOfDay wakeTime);

class BedTimeWidget extends LeafRenderObjectWidget {
  const BedTimeWidget({
    Key? key,
    this.onChange,
    required this.bedTime,
    required this.wakeTime,
    required this.threshold,
  }) : super(key: key);

  final BedTimeCallback? onChange;
  final double threshold;
  final TimeOfDay bedTime;
  final TimeOfDay wakeTime;

  @override
  RenderSlideButton createRenderObject(BuildContext context) {
    return RenderSlideButton(bedTime: bedTime, wakeTime: wakeTime, onChange: onChange, threshold: threshold);
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderSlideButton renderObject) {
    renderObject
      ..bedTime = bedTime
      ..wakeTime = wakeTime
      ..onChange = onChange
      ..threshold = threshold;
  }
}

class RenderSlideButton extends RenderBox {
  RenderSlideButton({
    BedTimeCallback? onChange,
    double? threshold,
    required TimeOfDay bedTime,
    required TimeOfDay wakeTime,
  })  : _onChange = onChange,
        _threshold = threshold,
        _bedTime = bedTime,
        _wakeTime = wakeTime {
    drag = PanGestureRecognizer()
      ..onStart = _onDragStart
      ..onUpdate = _onDragUpdate
      ..onCancel = _onDragCancel
      ..onEnd = _onDragEnd;

    _startAngle = _timeOfDayToAngle(bedTime);
    _sweepAngle = _normalizeSweepAngle((_startAngle - _timeOfDayToAngle(wakeTime) - 360.radians).abs());
    _selectedBedTimeHours = bedTime.fraction;
    _selectedWakeTimeHours = wakeTime.fraction;
    _selectedSleepHours = bedTime.difference(wakeTime);
  }

  late DragGestureRecognizer drag;

  TimeOfDay _bedTime;

  set bedTime(TimeOfDay bedTime) {
    if (bedTime == _bedTime) {
      return;
    }
    _bedTime = bedTime;
  }

  TimeOfDay _wakeTime;

  set wakeTime(TimeOfDay wakeTime) {
    if (wakeTime == _wakeTime) {
      return;
    }
    _wakeTime = wakeTime;
  }

  double? _threshold;

  set threshold(double threshold) {
    if (threshold == _threshold) {
      return;
    }
    _threshold = threshold;
    markNeedsPaint();
  }

  BedTimeCallback? _onChange;

  set onChange(BedTimeCallback? onChange) {
    _onChange = onChange;
  }

  late Path knobPath;
  late Rect startHandleBounds;
  late Rect endHandleBounds;

  double _startAngle = 0.0;
  double _sweepAngle = 0.0;
  double _selectedBedTimeHours = 0.0;
  double _selectedWakeTimeHours = 0.0;
  double _selectedSleepHours = 0.0;

  bool _selectedStartHandle = false;
  bool _selectedEndHandle = false;

  final minRadius = 100.0;
  final maxRadius = 250.0;

  final minSweepAngle = 20.radians;
  final maxSweepAngle = 300.radians;

  Offset _currentDragOffset = Offset.zero;
  Offset _currentStartDragOffset = Offset.zero;
  Offset _currentEndDragOffset = Offset.zero;

  void _onDragStart(DragStartDetails details) {
    _currentDragOffset = globalToLocal(details.globalPosition);
    if (startHandleBounds.contains(_currentDragOffset)) {
      _selectedStartHandle = true;
      _currentStartDragOffset = _currentDragOffset;
    } else if (endHandleBounds.contains(_currentDragOffset)) {
      _selectedEndHandle = true;
      _currentEndDragOffset = _currentDragOffset;
    }
    markNeedsPaint();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_selectedStartHandle) {
      final diffInAngle = _calculateDiffInAngle(_currentStartDragOffset, _currentStartDragOffset + details.delta);
      _startAngle = _startAngle.subtractAngle(diffInAngle);
      _sweepAngle = _normalizeSweepAngle(_sweepAngle.addAngle(diffInAngle));
      _currentStartDragOffset = details.localPosition;
    } else if (_selectedEndHandle) {
      final diffInAngle = _calculateDiffInAngle(_currentEndDragOffset, _currentEndDragOffset + details.delta);
      _sweepAngle = _normalizeSweepAngle(_sweepAngle.subtractAngle(diffInAngle));
      if (_sweepAngle <= minSweepAngle || _sweepAngle >= maxSweepAngle) {
        _startAngle = _startAngle.subtractAngle(diffInAngle);
      }
      _currentEndDragOffset = details.localPosition;
    } else {
      final diffInAngle = _calculateDiffInAngle(_currentDragOffset, _currentDragOffset + details.delta);
      _startAngle = _startAngle.subtractAngle(diffInAngle);
      _currentDragOffset = details.localPosition;
    }
    _onAngleChange();
    markNeedsPaint();
  }

  void _onDragCancel() {
    _selectedStartHandle = false;
    _selectedEndHandle = false;
    _currentDragOffset = Offset.zero;
    _currentStartDragOffset = Offset.zero;
    _currentEndDragOffset = Offset.zero;
    markNeedsPaint();
  }

  void _onDragEnd(DragEndDetails details) {
    _onDragCancel();
  }

  void _onAngleChange() {
    final selectedBedTimeHours = _angleToHours(_startAngle);
    final selectedWakeUpTimeHours = _angleToHours((_startAngle + _sweepAngle).normalizeAngle);
    final selectedHours = _angleToHours(_sweepAngle);

    if (_selectedBedTimeHours != selectedBedTimeHours ||
        _selectedWakeTimeHours != selectedWakeUpTimeHours ||
        _selectedSleepHours != selectedHours) {
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        HapticFeedback.selectionClick();
        _onChange?.call(
          toTimeOfDay(selectedBedTimeHours),
          toTimeOfDay(selectedWakeUpTimeHours),
        );
      });
    }

    _selectedBedTimeHours = selectedBedTimeHours;
    _selectedWakeTimeHours = selectedWakeUpTimeHours;
    _selectedSleepHours = selectedHours;
  }

  @override
  bool hitTestSelf(ui.Offset position) => knobPath.contains(position);

  @override
  bool get isRepaintBoundary => true;

  @override
  void handleEvent(PointerEvent event, covariant BoxHitTestEntry entry) {
    if (event is PointerDownEvent) {
      drag.addPointer(event);
    }
  }

  @override
  void performLayout() {
    final effectiveConstraints = constraints.enforce(BoxConstraints(
      minHeight: minRadius * 2,
      minWidth: minRadius * 2,
      maxHeight: maxRadius * 2,
      maxWidth: maxRadius * 2,
    ));
    size = Size.square(effectiveConstraints.biggest.shortestSide);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final bounds = offset & size;
    final radius = size.width / 2;
    final center = bounds.center;
    final angleOffset = -90.radians;

    // Draw background
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFF000000));

    final knobThickness = size.width / 8;
    final knobPadding = knobThickness / 8;

    // Draw clock
    const clockBackgroundColor = Color(0xFF2C2C2E);
    final clockRadius = radius - (knobPadding * 2) - knobThickness;
    canvas.drawCircle(center, clockRadius, Paint()..color = clockBackgroundColor);
    final tickLength = knobThickness / 40;
    final tickPadding = clockRadius / 16;
    final tickRadius = clockRadius - tickPadding;
    const tickDivisions = 3.75;
    final tickTextFontSize = tickLength * 10;
    final tickTextPadding = tickPadding * 1.25;
    const tickColor = Color(0x50FFFFFF);

    // Draw ticks
    for (var i = 0; i < (360 / tickDivisions); i++) {
      final index = i * tickDivisions;
      final strokeRadius = i % 4 == 0 ? (tickLength * 4) : tickLength;
      final angle = index.radians + angleOffset;
      canvas.drawLine(
        toPolar(center, angle, tickRadius),
        toPolar(center, angle, tickRadius - strokeRadius),
        Paint()
          ..color = tickColor
          ..strokeCap = StrokeCap.round
          ..strokeWidth = tickLength / 1.25,
      );

      // Draw ticks text
      if (i % 8 == 0) {
        final hour = i ~/ 4.0;
        final pair = _hourTextBuilder(hour);
        final textBounds = _drawParagraph(
          canvas,
          '${pair.a}${pair.b}',
          offset: toPolar(
            center,
            angle,
            tickRadius - (pair.b.isNotEmpty ? tickTextPadding : tickTextPadding / 2) - tickTextFontSize,
          ),
          color: pair.b.isNotEmpty ? Colors.white : tickColor,
          fontSize: tickTextFontSize,
          fontWeight: FontWeight.w600,
        );

        // Draw icons
        if (pair.a == TimeOfDay.hoursPerPeriod) {
          final icon = hour == 0 ? Icons.auto_awesome : Icons.wb_sunny_rounded;
          final color = hour == 0 ? const Color(0xFF00D0CC) : const Color(0xFFFED60A);
          _drawParagraph(
            canvas,
            String.fromCharCode(icon.codePoint),
            offset: textBounds.center - Offset(-tickTextFontSize / 2, (hour == 0 ? -1 : 1) * tickTextFontSize * 2),
            color: color,
            fontSize: tickTextFontSize * 1.75,
            fontFamily: icon.fontFamily,
            fontWeight: FontWeight.w100,
          );
        }
      }
    }

    // Draw knobs
    final startAngle = _startAngle + angleOffset;
    final endAngle = startAngle + _sweepAngle;
    final isLargeArc = _sweepAngle > 180.radians;

    final knobRadius = radius - knobPadding;
    final innerKnobRadius = knobRadius - knobThickness;
    final startOffset = toPolar(center, startAngle, knobRadius);
    final innerStartOffset = toPolar(center, startAngle, innerKnobRadius);
    final endOffset = toPolar(center, endAngle, knobRadius);
    final innerEndOffset = toPolar(center, endAngle, innerKnobRadius);
    final knobColor = _selectedSleepHours > _threshold! ? clockBackgroundColor : const Color(0xFFFF9F0A);

    knobPath = Path()
      ..moveTo(startOffset.dx, startOffset.dy)
      ..arcToPoint(endOffset, radius: Radius.circular(knobRadius), largeArc: isLargeArc)
      ..arcToPoint(innerEndOffset, radius: Radius.circular(knobThickness / 2))
      ..arcToPoint(
        innerStartOffset,
        radius: Radius.circular(innerKnobRadius),
        largeArc: isLargeArc,
        clockwise: false,
      )
      ..arcToPoint(startOffset, radius: Radius.circular(knobThickness / 2));
    canvas.drawPath(knobPath, Paint()..color = knobColor);

    final strokeRadius = knobThickness / 3;
    const divisions = 3.0;
    for (var i = 0; i < (360 / divisions); i++) {
      final index = i * divisions;
      canvas.drawLine(
        toPolar(center, index.radians, knobRadius - strokeRadius),
        toPolar(center, index.radians, innerKnobRadius + strokeRadius),
        Paint()
          ..color = const Color(0x30000000)
          ..strokeCap = StrokeCap.round
          ..strokeWidth = strokeRadius / 6,
      );
    }

    // Draw handles
    final handleSize = Size.square(knobThickness);
    final selectedHandleStateColor = Color.lerp(knobColor, const Color(0xFF000000), .25);
    final fontColor = _selectedSleepHours > _threshold! ? tickColor : const Color(0x99000000);
    startHandleBounds = Rect.fromCenter(
      center: Offset.lerp(startOffset, innerStartOffset, .5)!,
      width: handleSize.width,
      height: handleSize.height,
    );
    _drawKnobHandle(
      canvas: canvas,
      icon: Icons.king_bed_rounded,
      offset: startHandleBounds.center,
      radius: handleSize.radius,
      color: _selectedStartHandle ? selectedHandleStateColor! : knobColor,
      fontColor: fontColor,
    );
    endHandleBounds = Rect.fromCenter(
      center: Offset.lerp(endOffset, innerEndOffset, .5)!,
      width: handleSize.width,
      height: handleSize.height,
    );
    _drawKnobHandle(
      canvas: canvas,
      icon: Icons.notifications,
      offset: endHandleBounds.center,
      radius: handleSize.radius,
      color: _selectedEndHandle ? selectedHandleStateColor! : knobColor,
      fontColor: fontColor,
    );
  }

  void _drawKnobHandle({
    required Canvas canvas,
    required IconData icon,
    required Offset offset,
    required double radius,
    required Color color,
    required Color fontColor,
  }) {
    canvas.drawCircle(offset, radius, Paint()..color = color);
    _drawParagraph(
      canvas,
      String.fromCharCode(icon.codePoint),
      offset: offset,
      color: fontColor,
      fontSize: radius,
      fontFamily: icon.fontFamily,
      fontWeight: FontWeight.w300,
    );
  }

  Rect _drawParagraph(
    Canvas canvas,
    String text, {
    required Offset offset,
    required Color color,
    required double fontSize,
    String? fontFamily,
    FontWeight? fontWeight,
  }) {
    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.center))
      ..pushStyle(ui.TextStyle(
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
        letterSpacing: 1.2,
        fontFamily: fontFamily,
      ))
      ..addText(text);
    final paragraph = builder.build();
    final constraints = ui.ParagraphConstraints(width: fontSize * text.length);
    final finalOffset = offset - Offset(constraints.width / 2, fontSize / 2);
    canvas.drawParagraph(paragraph..layout(constraints), finalOffset);
    return Rect.fromLTWH(finalOffset.dx, finalOffset.dy, paragraph.longestLine, paragraph.height);
  }

  Pair<int, String> _hourTextBuilder(int hour) {
    final _hour = hour.normalize(TimeOfDay.hoursPerPeriod);
    final mod = _hour % 6 == 0 ? (hour >= TimeOfDay.hoursPerPeriod ? 'PM' : 'AM') : '';
    return Pair(_hour == 0 ? TimeOfDay.hoursPerPeriod : _hour, mod);
  }

  double _angleToHours(double angle) {
    return double.parse((angle.degrees / 15).toStringAsFixed(1));
  }

  double _timeOfDayToAngle(TimeOfDay time) {
    return ((time.hour + (time.minute / TimeOfDay.minutesPerHour)) * 15).radians;
  }

  double _normalizeSweepAngle(double angle) {
    return math.max(minSweepAngle, math.min(angle, maxSweepAngle));
  }

  double _calculateDiffInAngle(Offset prev, Offset current) {
    final center = Offset(size.radius, size.radius);
    return toAngle(prev, center) - toAngle(current, center);
  }
}

extension on TimeOfDay {
  double get fraction {
    return hour + (minute / TimeOfDay.minutesPerHour);
  }

  String get periodShort {
    return period.toString().split('.').last;
  }

  double difference(TimeOfDay other) {
    return TimeOfDay.hoursPerDay - fraction + other.fraction;
  }

  TimeOfDay subtract(TimeOfDay other) {
    return toTimeOfDay(difference(other));
  }
}

TimeOfDay toTimeOfDay(double hours) {
  final whole = hours ~/ 1;
  return TimeOfDay(hour: whole, minute: ((hours % math.max(1, whole)) * TimeOfDay.minutesPerHour) ~/ 1);
}
