import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:playground/extensions.dart';

const primaryColor = Color(0xFF080B21);

class LifeDIY extends StatefulWidget {
  const LifeDIY({Key? key}) : super(key: key);

  @override
  _LifeDIYState createState() => _LifeDIYState();
}

class _LifeDIYState extends State<LifeDIY> with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.lerp(primaryColor, Colors.black12, .15),
      body: Center(
        child: Container(
          decoration: BoxDecoration(
            color: primaryColor,
            border: Border.all(color: Color.lerp(primaryColor, Colors.white, .15)!, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 128),
          child: SizedBox.fromSize(
            size: const Size(500, 400),
            child: MoodSpinner(
              vsync: this,
              moods: const <Mood>[
                Mood('Anger', '😡', [
                  Pair('Frustrated', 'Frustrated - Lorem ipsum dolor set it gap'),
                  Pair('Resentful', 'Resentful - Lorem ipsum dolor set it gap'),
                  Pair('Envious', 'Envious - Lorem ipsum dolor set it gap'),
                  Pair('Vengeful', 'Vengeful - Lorem ipsum dolor set it gap'),
                  Pair('Enraged', 'Enraged - Lorem ipsum dolor set it gap'),
                ]),
                Mood('Disgust', '🤮', [
                  Pair('Bored', 'Bored - Lorem ipsum dolor set it gap'),
                  Pair('Dissatisfied', 'Dissatisfied - Lorem ipsum dolor set it gap'),
                  Pair('Distrustful', 'Distrustful - Lorem ipsum dolor set it gap'),
                  Pair('Embarrassed', 'Embarrassed - Lorem ipsum dolor set it gap'),
                  Pair('Regretful', 'Regretful - Lorem ipsum dolor set it gap'),
                  Pair('Ashamed', 'Ashamed - Lorem ipsum dolor set it gap'),
                  Pair('Contemptuous', 'Contemptuous - Lorem ipsum dolor set it gap'),
                ]),
                Mood('Sadness', '😞', [
                  Pair('Pensive', 'Pensive - Lorem ipsum dolor set it gap'),
                  Pair('Disappointed', 'Disappointed - Lorem ipsum dolor set it gap'),
                  Pair('Helpless', 'Helpless - Lorem ipsum dolor set it gap'),
                  Pair('Rejected', 'Rejected - Lorem ipsum dolor set it gap'),
                  Pair('Lonely', 'Lonely - Lorem ipsum dolor set it gap'),
                  Pair('Depressed', 'Depressed - Lorem ipsum dolor set it gap'),
                  Pair('In Grief', 'In Grief - Lorem ipsum dolor set it gap'),
                ]),
                Mood('Surprise', '😮', [
                  Pair('Distracted', 'Distracted - Lorem ipsum dolor set it gap'),
                  Pair('Surprised', 'Surprised - Lorem ipsum dolor set it gap'),
                  Pair('Touched', 'Touched - Lorem ipsum dolor set it gap'),
                  Pair('Amazed', 'Amazed - Lorem ipsum dolor set it gap'),
                ]),
                Mood('Fear', '😧', [
                  Pair('Anxious', 'Anxious - Lorem ipsum dolor set it gap'),
                  Pair('Unclear', 'Unclear - Lorem ipsum dolor set it gap'),
                  Pair('Insecure', 'Insecure - Lorem ipsum dolor set it gap'),
                  Pair('Indecisive', 'Indecisive - Lorem ipsum dolor set it gap'),
                  Pair('Jealous', 'Jealous - Lorem ipsum dolor set it gap'),
                  Pair('Overwhelmed', 'Overwhelmed - Lorem ipsum dolor set it gap'),
                  Pair('Panicked', 'Panicked - Lorem ipsum dolor set it gap'),
                ]),
                Mood('Trust', '🙂', [
                  Pair('Accepting', 'Accepting - Lorem ipsum dolor set it gap'),
                  Pair('Secure', 'Secure - Lorem ipsum dolor set it gap'),
                  Pair('Confident', 'Confident - Lorem ipsum dolor set it gap'),
                  Pair('Forgiving', 'Forgiving - Lorem ipsum dolor set it gap'),
                  Pair('Supported', 'Supported - Lorem ipsum dolor set it gap'),
                  Pair('Admiring', 'Admiring - Lorem ipsum dolor set it gap'),
                ]),
                Mood('Joy', '😃', [
                  Pair('Serene', 'Serene - Lorem ipsum dolor set it gap'),
                  Pair('Grateful', 'Grateful - Lorem ipsum dolor set it gap'),
                  Pair('Relieved', 'Relieved - Lorem ipsum dolor set it gap'),
                  Pair('Content', 'Content - Lorem ipsum dolor set it gap'),
                  Pair('Fulfilled', 'Fulfilled - Lorem ipsum dolor set it gap'),
                  Pair('In Love', 'In Love - Lorem ipsum dolor set it gap'),
                ]),
                Mood('Interest', '😕', [
                  Pair('Interested', 'Interested - Lorem ipsum dolor set it gap'),
                  Pair('Hopeful', 'Hopeful - Lorem ipsum dolor set it gap'),
                  Pair('Anticipating', 'Anticipating - Lorem ipsum dolor set it gap'),
                  Pair('Compassionate', 'Compassionate - Lorem ipsum dolor set it gap'),
                  Pair('Excited', 'Excited - Lorem ipsum dolor set it gap'),
                  Pair('Vigilant', 'Vigilant - Lorem ipsum dolor set it gap'),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MoodSpinner extends LeafRenderObjectWidget {
  const MoodSpinner({Key? key, required this.moods, required this.vsync}) : super(key: key);

  final List<Mood> moods;
  final TickerProvider vsync;

  @override
  RenderObject createRenderObject(BuildContext context) => RenderMoodSpinner(moods, vsync: vsync);

  @override
  void updateRenderObject(BuildContext context, covariant RenderMoodSpinner renderObject) => renderObject
    ..moods = moods
    ..vsync = vsync;
}

class RenderMoodSpinner extends RenderBox with RenderBoxDebugBounds {
  RenderMoodSpinner(List<Mood> moods, {required TickerProvider vsync})
      : _moods = moods,
        _vsync = vsync,
        colorsSpectrum = [for (var i = 0; i < 360; i++) _resolveColorFromHue(fullAngle - i.toDouble())],
        colorsByMood =
            moods.fold<Triple<int, int, Map<int, List<Color>>>>(const Triple(0, 0, {}), (previousValue, Mood element) {
          final index = previousValue.a;
          final total = previousValue.b;
          return Triple(index + 1, total + element.items.length, {
            ...previousValue.c,
            index: [
              for (int i = 0; i < element.items.length; i++)
                _resolveColorFromHue(fullAngle - (((total + i + 1) / moods.totalSubs) * fullAngle))
            ]
          });
        }).c {
    drag = PanGestureRecognizer()
      ..onStart = _onDragStart
      ..onUpdate = _onDragUpdate
      ..onCancel = _onDragCancel
      ..onEnd = _onDragEnd;
  }

  static const contentBackgroundColor = primaryColor;
  static const activeTextColor = Colors.white;
  static final labelTextStyle = TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.normal);
  static const minFlingVelocity = 10;

  late final DragGestureRecognizer drag;
  late final List<Color> colorsSpectrum;
  late final Map<int, List<Color>> colorsByMood;

  late final AnimationController controller;
  late Animation<Offset> animation;

  late Rect trackBounds;

  List<Mood> get moods => _moods;
  List<Mood> _moods;

  set moods(List<Mood> moods) {
    if (_moods == moods) {
      return;
    }
    _moods = moods;
    markNeedsPaint();
  }

  double get selectedAngle => _selectedAngle;
  double _selectedAngle = 0;

  set selectedAngle(double angle) {
    if (_selectedAngle == angle) {
      return;
    }
    _selectedAngle = angle;
    markNeedsPaint();
  }

  TickerProvider get vsync => _vsync;
  TickerProvider _vsync;

  set vsync(TickerProvider vsync) {
    if (vsync == _vsync) {
      return;
    }
    _vsync = vsync;
    controller.resync(_vsync);
  }

  double get trackDivisions => fullAngle / moods.totalSubs;

  int get selectedTrackItem => (fullAngle - selectedAngle.degrees) ~/ trackDivisions;

  int get selectedMoodIndex {
    int sum = 0;
    for (int i = 0; i < moods.length; i++) {
      sum += moods[i].items.length;
      if (sum > selectedTrackItem) {
        return i;
      }
    }
    return moods.length - 1;
  }

  int get totalItemsUntilSelectedMoodIndex =>
      moods.sublist(0, selectedMoodIndex).fold<int>(0, (total, element) => total + element.items.length);

  List<Pair<String, String>> get selectedMoodItems => moods[selectedMoodIndex].items;

  int get selectedMoodItemIndex =>
      math.min(selectedMoodItems.length - 1, selectedTrackItem - totalItemsUntilSelectedMoodIndex);

  Offset _dragOffset = Offset.zero;

  void _onUpdateSelectedAngle(Offset to) {
    final previousSelectedTrackItem = selectedTrackItem;
    final diffInAngle = toAngle(to, trackBounds.center) - toAngle(_dragOffset, trackBounds.center);
    selectedAngle = (selectedAngle + diffInAngle).normalizeAngle;

    if (previousSelectedTrackItem != selectedTrackItem) {
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        HapticFeedback.selectionClick();
      });
    }
  }

  void _onDragStart(DragStartDetails details) => _dragOffset = details.localPosition;

  void _onDragUpdate(DragUpdateDetails details) {
    _onUpdateSelectedAngle(details.localPosition);
    _dragOffset = details.localPosition;
  }

  void _onDragCancel() => _dragOffset = Offset.zero;

  void _onDragEnd(DragEndDetails details) => _onFling(details.velocity.pixelsPerSecond);

  void _onFling(Offset pixelsPerSecond) {
    animation = controller.drive(Tween(begin: Offset.zero, end: _dragOffset));

    final unitsPerSecond = Offset(pixelsPerSecond.dx / trackBounds.width, pixelsPerSecond.dy / trackBounds.height);
    final primaryVelocity = unitsPerSecond.distance;
    if (primaryVelocity > minFlingVelocity) {
      controller
          .animateWith(SpringSimulation(
              SpringDescription(mass: trackBounds.radius * .1, stiffness: .5, damping: 1.0), 0, 1, -primaryVelocity))
          .whenCompleteOrCancel(() => _onDragCancel());
    }
  }

  @override
  void attach(covariant PipelineOwner owner) {
    super.attach(owner);
    controller = AnimationController.unbounded(vsync: vsync, duration: const Duration(milliseconds: 250))
      ..addListener(() => _onUpdateSelectedAngle(animation.value));
  }

  @override
  void detach() {
    controller.dispose();
    super.detach();
  }

  @override
  bool get sizedByParent => true;

  @override
  bool get isRepaintBoundary => true;

  @override
  bool hitTestSelf(Offset position) => trackBounds.contains(position);

  @override
  void handleEvent(PointerEvent event, covariant BoxHitTestEntry entry) {
    if (event is PointerDownEvent) {
      drag.addPointer(event);
    }
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final bounds = offset & size;
    debugBounds.add(bounds);
    canvas.clipRect(bounds);

    final trackRadius = size.height * .5;
    final trackThickness = size.width * .04;
    const trackTranslateFactor = .3;
    final trackXTranslate = trackRadius * trackTranslateFactor;
    final trackCenter = size.centerLeft(offset).translate(trackXTranslate, 0);
    const trackArcRadius = Radius.circular(1);
    trackBounds = Rect.fromCircle(center: trackCenter, radius: trackRadius);
    final trackPath = Path()
      ..moveTo(trackBounds.topCenter.dx, trackBounds.topCenter.dy + trackThickness)
      ..arcToPoint(trackBounds.bottomCenter.translate(0, -trackThickness), radius: trackArcRadius)
      ..arcToPoint(trackBounds.topCenter.translate(0, trackThickness), radius: trackArcRadius)
      ..moveTo(trackBounds.topCenter.dx, trackBounds.topCenter.dy)
      ..arcToPoint(trackBounds.bottomCenter, radius: trackArcRadius, clockwise: false)
      ..arcToPoint(trackBounds.topCenter, radius: trackArcRadius, clockwise: false);
    canvas.drawPath(
      trackPath,
      Paint()
        ..shader = SweepGradient(
          endAngle: fullAngleInRadians,
          transform: GradientRotation(selectedAngle),
          colors: colorsSpectrum,
        ).createShader(trackBounds),
    );
    for (int i = 0; i < (fullAngle / moods.length); i++) {
      final angle = (i * moods.length).radians + selectedAngle;
      final p2 = trackCenter.translateAlong(angle, trackRadius);
      canvas.drawLine(
        p2.translateAlong(angle, -trackThickness),
        p2,
        Paint()
          ..color = Colors.black87
          ..blendMode = BlendMode.overlay,
      );
    }
    final trackVisibleBounds = Rect.fromLTWH(offset.dx, offset.dy, trackRadius + trackXTranslate, trackRadius * 2);
    debugBounds.add(trackVisibleBounds);

    final moodTrackRadius = trackRadius - trackThickness;
    final moodTrackWidth = moodTrackRadius * .5;
    final moodTrackBounds = Rect.fromCircle(center: trackCenter, radius: moodTrackRadius);
    canvas.drawCircle(
      trackCenter,
      moodTrackRadius,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x10FFFFFF), Color(0x2F000000)],
          stops: [.5, 1],
        ).createShader(moodTrackBounds),
    );
    double moodItemPrevAngle = 0;
    for (int i = 0; i < moods.length; i++) {
      final item = moods[i];
      final angle = (item.items.length * trackDivisions).radians;
      final effectivePrevAngle = moodItemPrevAngle + selectedAngle;
      canvas.drawLine(
        trackCenter,
        trackCenter.translateAlong(effectivePrevAngle + angle, trackRadius - trackThickness),
        Paint()
          ..color = contentBackgroundColor
          ..strokeWidth = trackThickness * .1,
      );

      final isSelected = selectedMoodIndex == i;
      final titleCenter =
          trackCenter.translateAlong(effectivePrevAngle + angle / 2, moodTrackRadius - moodTrackWidth / 2);
      final titleBounds = canvas.drawText(
        item.title,
        center: titleCenter,
        style: labelTextStyle.copyWith(
          fontSize: labelTextStyle.fontSize! * 1.05,
          color: isSelected ? activeTextColor : Colors.grey.shade600,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      );
      final iconTextLayoutResult =
          canvas.layoutText(item.icon, style: TextStyle(fontSize: labelTextStyle.fontSize! * 1.65, height: .75));
      final iconBounds = iconTextLayoutResult
          .paint(titleCenter.translate(0, -(titleBounds.radius + iconTextLayoutResult.size.radius)));
      debugBounds.addAll({titleBounds, iconBounds});

      moodItemPrevAngle += angle;
    }
    debugBounds.add(moodTrackBounds);

    final knobRadius = moodTrackRadius - moodTrackWidth;
    final knobPadding = knobRadius * .5;
    const knobTranslateFactor = .25;
    final knobBounds = Rect.fromCircle(center: trackCenter, radius: knobRadius);
    final knobArrowWidth = trackThickness * 1.275;
    canvas
      ..drawCircle(trackCenter, knobRadius, Paint()..color = contentBackgroundColor)
      ..drawCircle(
          trackCenter,
          knobRadius * 1.0275,
          Paint()
            ..color = contentBackgroundColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = knobRadius * .015)
      ..drawPath(
        Path()
          ..moveTo(knobBounds.centerRight.dx, knobBounds.centerRight.dy - knobArrowWidth / 2)
          ..lineTo(knobBounds.centerRight.dx + knobArrowWidth / 2, knobBounds.centerRight.dy)
          ..lineTo(knobBounds.centerRight.dx, knobBounds.centerRight.dy + knobArrowWidth / 2),
        Paint()..color = contentBackgroundColor,
      );
    final descriptionTextBounds = canvas.drawText(
      moods[selectedMoodIndex].items[selectedMoodItemIndex].b,
      center: trackCenter.translate(knobPadding * knobTranslateFactor, 0),
      maxWidth: (knobRadius * 2) - (knobPadding * (1 + knobTranslateFactor)),
      style: labelTextStyle.copyWith(fontSize: labelTextStyle.fontSize! * 1.015),
    );
    debugBounds.addAll({descriptionTextBounds, knobBounds});

    final itemsTextLayoutResults = <TextLayoutResult>[];
    for (int i = 0; i < selectedMoodItems.length; i++) {
      final isSelected = selectedMoodItemIndex == i;
      itemsTextLayoutResults.add(canvas.layoutText(
        selectedMoodItems[i].a,
        style: labelTextStyle.copyWith(
          fontSize: labelTextStyle.fontSize! * 1.25,
          color: isSelected ? activeTextColor : null,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ));
    }

    final remainingBounds = trackBounds.topRight & Size(size.width - trackVisibleBounds.width, size.height);
    final remainingBoundsLeftMargin = remainingBounds.width * .125;
    final textIndicatorRadius = remainingBoundsLeftMargin * .125;
    final textIndicatorPadding = textIndicatorRadius * 2;
    final selectedColorsForMood = colorsByMood[selectedMoodIndex]!;
    final itemsSeparatorHeight = remainingBoundsLeftMargin * .35;
    final totalIndicatorHeight =
        itemsTextLayoutResults.fold<double>(0.0, (acc, element) => acc + element.size.height + itemsSeparatorHeight) -
            itemsSeparatorHeight;
    Offset itemsStartOffset = remainingBounds.centerLeft.translate(
        remainingBoundsLeftMargin + ((textIndicatorPadding + textIndicatorRadius) * 2), -totalIndicatorHeight / 2);
    final itemsBounds = itemsStartOffset &
        Size(itemsTextLayoutResults.fold(0.0, (maxWidth, element) => math.max(maxWidth, element.size.width)),
            totalIndicatorHeight);
    for (int i = 0; i < itemsTextLayoutResults.length; i++) {
      final result = itemsTextLayoutResults[i];
      final textBounds = result.paint(result.size.center(itemsStartOffset));

      canvas.drawCircle(
        textBounds.centerLeft.translate(-(textIndicatorRadius + textIndicatorPadding), 0),
        textIndicatorRadius,
        Paint()..color = selectedColorsForMood[i],
      );

      itemsStartOffset += Offset(0, result.size.height + itemsSeparatorHeight);
      debugBounds.add(textBounds);
    }
    debugBounds.addAll({remainingBounds, itemsBounds});
  }
}

Color _resolveColorFromHue(double value) => HSLColor.fromAHSL(1, value, .9, .6).toColor();

extension on List<Mood> {
  int get totalSubs => fold(0, (count, element) => count + element.items.length);
}

class Mood {
  const Mood(this.title, this.icon, this.items);

  final String title;
  final String icon;
  final List<Pair<String, String>> items;
}
