import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../extensions.dart';
import '../interpolate.dart';

class ActivityRings extends StatefulWidget {
  @override
  _ActivityRingsState createState() => _ActivityRingsState();
}

class _ActivityRingsState extends State<ActivityRings> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final items = [
      Data(
        title: 'Activity',
        progress: 56,
        icon: Icons.nightlight_round,
        color: Color(0xFFFF7C31),
        iconColor: Color(0xFFFFFFFF),
      ),
      Data(
        title: 'Habits',
        progress: 69,
        icon: Icons.opacity,
        color: Color(0xFF6706FF),
        iconColor: Color(0xFFFFFFFF),
      ),
      Data(
        title: 'Rest',
        progress: 30,
        icon: Icons.star,
        color: Color(0xFFFF2F78),
        iconColor: Color(0xFFFFFFFF),
      ),
    ];

    return Scaffold(
      backgroundColor: Color(0xFF161616),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox.fromSize(
            size: Size.square(540.0),
            child: ActivityRingsWidget(vsync: this, values: items),
          ),
          SizedBox(height: 64),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final item in items)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(color: item.color, shape: BoxShape.circle),
                      padding: EdgeInsets.all(12),
                      child: Icon(item.icon, size: 42, color: item.iconColor),
                    ),
                    SizedBox(height: 18),
                    Text(
                      item.title,
                      style: TextStyle(color: Colors.white60, fontWeight: FontWeight.w400, fontSize: 18),
                    ),
                  ],
                )
            ],
          )
        ],
      ),
    );
  }
}

class ActivityRingsWidget extends LeafRenderObjectWidget {
  const ActivityRingsWidget({Key key, @required this.vsync, @required this.values}) : super(key: key);

  final TickerProvider vsync;
  final List<Data> values;

  @override
  RenderActivityRings createRenderObject(BuildContext context) {
    return RenderActivityRings(vsync: vsync, values: values);
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderActivityRings renderObject) {
    renderObject
      ..vsync = vsync
      ..values = values;
  }
}

class RenderActivityRings extends RenderBox with RenderBoxDebugBounds {
  RenderActivityRings({@required TickerProvider vsync, @required List<Data> values})
      : _vsync = vsync,
        _values = values;

  AnimationController animation;
  AnimationController progressAnimation;

  static final startAngle = -90.radians;
  static final angleBuilder = interpolate(inputMax: 100.0, outputMax: 359.0);
  static const trackColor = Color(0xFF2D2D2D);

  List<Data> _values;

  set values(List<Data> values) {
    if (values == _values) {
      return;
    }
    _values = values;
    animation.forward(from: 0.0);
    markNeedsPaint();
  }

  TickerProvider _vsync;

  set vsync(TickerProvider vsync) {
    assert(vsync != null);
    if (vsync == _vsync) {
      return;
    }
    _vsync = vsync;
    animation.resync(_vsync);
    progressAnimation.resync(_vsync);
  }

  int _selectedHitTestIndex;
  int selectedIndex;

  void _onTapDown() {
    selectedIndex = _selectedHitTestIndex == selectedIndex ? null : _selectedHitTestIndex;
    progressAnimation.animateTo(selectedIndex != null ? _values[selectedIndex].progress : 0.0);
    HapticFeedback.selectionClick();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);

    animation = AnimationController(vsync: _vsync, duration: Duration(milliseconds: _values.length * 500))
      ..addListener(markNeedsPaint)
      ..forward();

    progressAnimation = AnimationController.unbounded(vsync: _vsync, duration: Duration(milliseconds: 350))
      ..addListener(markNeedsPaint);
  }

  @override
  void detach() {
    animation.removeListener(markNeedsPaint);
    progressAnimation.removeListener(markNeedsPaint);

    super.detach();
  }

  @override
  bool get sizedByParent => true;

  @override
  ui.Size computeDryLayout(BoxConstraints constraints) {
    return constraints.biggest;
  }

  @override
  bool hitTestSelf(ui.Offset position) {
    for (final entry in ringPaths.entries) {
      if (entry.value.contains(localToGlobal(position))) {
        _selectedHitTestIndex = entry.key;
        return true;
      }
    }
    return false;
  }

  @override
  void handleEvent(PointerEvent event, covariant BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is PointerDownEvent) {
      _onTapDown();
    }
  }

  final Map<int, Path> ringPaths = {};

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final bounds = offset & size;
    debugBounds.add(bounds);

    final baseRadius = size.radius * .4;
    final ringSpacing = baseRadius * .05;
    final ringWidth = (size.radius - baseRadius - (ringSpacing * (_values.length - 1))) / _values.length;
    for (var i = 0; i < _values.length; i++) {
      final item = _values[i];
      final animatedValue = Interval(i / _values.length, (i + 1) / _values.length).transform(animation.value);
      final paths = _computeRingPaths(
        sweepAngle: angleBuilder(item.progress * animatedValue).radians,
        strokeWidth: ringWidth,
        center: bounds.center,
        radius: baseRadius + (ringWidth * (i + 1)) + (ringSpacing * i),
      );
      _drawRing(
        canvas,
        trackPath: paths.a,
        progressPath: paths.b,
        strokeWidth: ringWidth,
        color: item.color,
        icon: item.icon,
        iconColor: item.iconColor,
      );

      ringPaths[i] = paths.b;
    }

    if (selectedIndex != null) {
      final selectedValue = _values[selectedIndex];
      canvas.drawPath(
        ringPaths[selectedIndex],
        Paint()
          ..color = Color.lerp(selectedValue.color, trackColor, .15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = ringSpacing / 2,
      );

      const textColor = Color(0xFFFFFFFF);
      final titleTextBounds = canvas.drawText(
        '${progressAnimation.value.toInt()}%',
        center: bounds.center,
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: baseRadius * .45),
      );
      debugBounds.add(titleTextBounds);

      final captionFontSize = baseRadius * .175;
      final captionTextBounds = canvas.drawText(
        'Done',
        center: titleTextBounds.bottomCenter.translate(0, captionFontSize * .75),
        style: TextStyle(color: textColor, fontWeight: FontWeight.w300, fontSize: captionFontSize),
      );
      debugBounds.add(captionTextBounds);

      final iconFontSize = baseRadius * .275;
      final iconTextBounds = canvas.drawText(
        String.fromCharCode(selectedValue.icon.codePoint),
        center: titleTextBounds.topCenter.translate(0, -iconFontSize * .75),
        style: TextStyle(color: trackColor, fontFamily: selectedValue.icon.fontFamily, fontSize: iconFontSize),
      );
      debugBounds.add(iconTextBounds);
    }

    if (selectedIndex == null) {
      final iconData = Icons.track_changes;
      final titleTextBounds = canvas.drawText(
        String.fromCharCode(iconData.codePoint),
        center: bounds.center,
        style: TextStyle(
          color: trackColor,
          fontFamily: iconData.fontFamily,
          fontWeight: FontWeight.bold,
          fontSize: baseRadius * .75,
        ),
      );
      debugBounds.add(titleTextBounds);
    }
  }

  void _drawRing(
    Canvas canvas, {
    @required Path trackPath,
    @required Path progressPath,
    @required double strokeWidth,
    @required Color color,
    @required IconData icon,
    @required Color iconColor,
  }) {
    canvas.drawPath(trackPath, Paint()..color = trackColor);
    debugPaths.add(trackPath);

    canvas.drawPath(progressPath, Paint()..color = color);
    debugPaths.add(progressPath);

    final bounds = trackPath.getBounds();
    final iconOffset = toPolar(bounds.center, startAngle, bounds.radius - strokeWidth / 2);
    final iconBounds = canvas.drawText(
      String.fromCharCode(icon.codePoint),
      center: iconOffset,
      style: TextStyle(
        fontFamily: icon.fontFamily,
        fontSize: strokeWidth * .5,
        color: Color.lerp(iconColor, color, .2),
      ),
    );
    debugBounds.add(iconBounds);
  }

  Pair<Path, Path> _computeRingPaths({
    @required double sweepAngle,
    @required double strokeWidth,
    @required Offset center,
    @required double radius,
  }) {
    final innerRadius = radius - strokeWidth;
    final trackPath = Path()
      ..moveTo(center.dx + radius, center.dy)
      ..relativeArcToPoint(Offset(-radius * 2, 0), radius: Radius.circular(radius))
      ..relativeArcToPoint(Offset(radius * 2, 0), radius: Radius.circular(radius))
      ..relativeMoveTo(-strokeWidth, 0)
      ..relativeArcToPoint(Offset(-innerRadius * 2, 0), radius: Radius.circular(innerRadius), clockwise: false)
      ..relativeArcToPoint(Offset(innerRadius * 2, 0), radius: Radius.circular(innerRadius), clockwise: false);

    final endAngle = sweepAngle + startAngle;
    final isLargeArc = endAngle >= 90.radians;
    final startOuterOffset = toPolar(center, startAngle, radius);
    final startInnerOffset = toPolar(center, startAngle, innerRadius);
    final endOuterOffset = toPolar(center, endAngle, radius);
    final endInnerOffset = toPolar(center, endAngle, innerRadius);
    final progressPath = Path()
      ..moveTo(startOuterOffset.dx, startOuterOffset.dy)
      ..arcToPoint(
        endOuterOffset,
        radius: Radius.circular(radius),
        largeArc: isLargeArc,
      )
      ..arcToPoint(endInnerOffset, radius: Radius.circular(strokeWidth / 2))
      ..arcToPoint(
        startInnerOffset,
        radius: Radius.circular(innerRadius),
        largeArc: isLargeArc,
        clockwise: false,
      )
      ..arcToPoint(startOuterOffset, radius: Radius.circular(strokeWidth / 2));

    return Pair(trackPath, progressPath);
  }
}

class Data {
  const Data({
    @required this.title,
    @required this.progress,
    @required this.color,
    @required this.icon,
    @required this.iconColor,
  });

  final String title;
  final double progress;
  final Color color;
  final IconData icon;
  final Color iconColor;
}
