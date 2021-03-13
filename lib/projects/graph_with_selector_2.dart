import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:playground/extensions.dart';
import 'package:playground/interpolate.dart';

class GraphWithSelectorII extends StatefulWidget {
  @override
  _GraphWithSelectorIIState createState() => _GraphWithSelectorIIState();
}

class _GraphWithSelectorIIState extends State<GraphWithSelectorII> with TickerProviderStateMixin {
  final List<double> values = List.generate(20, (_) => math.Random().nextDouble() * 150.0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121A2A),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF243455), Color(0xFF121A2A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SizedBox(
            height: 600,
            child: GraphView(values: values),
          ),
        ),
      ),
    );
  }
}

class GraphView extends ScrollView {
  GraphView({Key? key, required this.values})
      : super(key: key, scrollDirection: Axis.horizontal, physics: BouncingScrollPhysics());

  final List<double> values;

  @override
  List<Widget> buildSlivers(BuildContext context) {
    return [
      GraphViewWidget(values: values),
    ];
  }
}

class GraphViewWidget extends LeafRenderObjectWidget {
  const GraphViewWidget({Key? key, required this.values}) : super(key: key);

  final List<double> values;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderGraphViewWidget(values: values);
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderGraphViewWidget renderObject) {
    renderObject.values = values;
  }
}

class RenderGraphViewWidget extends RenderSliver {
  RenderGraphViewWidget({required List<double> values})
      : _values = values,
        _maxValue = values.reduce(math.max) {
    tap = TapGestureRecognizer()..onTapDown = _onTapDown;
  }

  late TapGestureRecognizer tap;

  double _maxValue;

  List<double> _values;

  set values(List<double> values) {
    if (_values == values) {
      return;
    }
    _values = values;
    _maxValue = values.reduce(math.max);
    markNeedsPaint();
    markNeedsLayout();
  }

  static const itemExtent = 75.0;
  static const strokeGradient = [Color(0xFFE6B92C), Color(0xFFF73369)];
  static const selectorGradient = [Color(0x26000000), Color(0x42000000)];
  static const backgroundColor = Color(0xFF1E2C46);
  static const labelColor = Color(0xFFFFFFFF);
  static const mutedLabelColor = Color(0x66CCCCCC);

  Set<Rect> debugBounds = {};

  late Rect fillPathBounds;

  int? _selectedIndex;

  void _onTapDown(TapDownDetails details) {
    final offset = details.localPosition.dx + constraints.scrollOffset - (padding / 2);
    _selectedIndex = interpolate(inputMax: geometry!.maxPaintExtent - padding, outputMax: _itemCount - 1.0)(offset)
        .discretize(1)
        .toInt();
    markNeedsPaint();
  }

  @override
  bool hitTestSelf({required double mainAxisPosition, required double crossAxisPosition}) {
    return fillPathBounds.contains(Offset(mainAxisPosition, crossAxisPosition));
  }

  @override
  void handleEvent(PointerEvent event, covariant SliverHitTestEntry entry) {
    if (event is PointerDownEvent) {
      tap.addPointer(event);
    }
  }

  int get _itemCount => _values.length;

  double get padding => itemExtent * 2;

  double get labelHeight => itemExtent * .5;

  double get graphToLabelPadding => labelHeight * .25;

  Size get viewport => Size(constraints.viewportMainAxisExtent, constraints.crossAxisExtent);

  @override
  void performLayout() {
    final maxExtent = ((_itemCount - 1) * itemExtent) + padding;
    final paintExtent = calculatePaintOffset(constraints, from: 0.0, to: maxExtent);
    final cacheExtent = calculateCacheOffset(constraints, from: 0.0, to: maxExtent);

    geometry = SliverGeometry(
      scrollExtent: maxExtent,
      paintExtent: paintExtent,
      cacheExtent: cacheExtent,
      maxPaintExtent: maxExtent,
      hitTestExtent: paintExtent,
      hasVisualOverflow: maxExtent > constraints.remainingPaintExtent || constraints.scrollOffset > 0.0,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    debugBounds.clear();
    final canvas = context.canvas;
    final viewportRect = Rect.fromCenter(
      center: viewport.center(offset),
      width: viewport.width,
      height: viewport.height - padding,
    );
    debugBounds.add(viewportRect);

    // Generate points offset
    final scrolledOffset = offset.translate(-constraints.scrollOffset + (padding / 2), viewportRect.top);
    final graphHeight = viewportRect.height - labelHeight - graphToLabelPadding;
    final offsets = <Offset>[];
    for (var i = 0; i < _itemCount; i++) {
      offsets.add(
        scrolledOffset +
            Offset(
              i * itemExtent,
              graphHeight * (1 - (_values[i] / _maxValue)),
            ),
      );
    }

    // Draw dashed lines
    for (var i = 0; i < _itemCount; i++) {
      canvas.drawPath(
        _createDashedLinePath(Offset(offsets[i].dx, viewportRect.top), graphHeight, 6.0),
        Paint()
          ..color = mutedLabelColor.withOpacity(.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round,
      );
    }

    // Draw selector background
    final selectedOffset = _selectedIndex != null ? offsets[_selectedIndex!] : null;
    if (selectedOffset != null) {
      final selectorBounds = Rect.fromCenter(
        center: Offset(selectedOffset.dx, viewportRect.center.dy),
        width: itemExtent,
        height: viewportRect.height + (itemExtent / 1.25),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(selectorBounds, Radius.circular(itemExtent / 8)),
        Paint()
          ..shader = LinearGradient(
            colors: selectorGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(fillPathBounds),
      );
      debugBounds.add(selectorBounds);
    }

    // Generate curved path from spline
    final spline = CatmullRomSpline(offsets).generateSamples();
    final curvedPath = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (final sample in spline) {
      curvedPath.lineTo(sample.value.dx, sample.value.dy);
    }

    // Draw curved path
    const strokeWidth = 6.0;
    fillPathBounds = curvedPath.getBounds();
    final curveGradientShader = LinearGradient(colors: strokeGradient).createShader(fillPathBounds);
    canvas.drawPath(
      curvedPath,
      Paint()
        ..shader = curveGradientShader
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth,
    );

    // Draw selector circles
    if (selectedOffset != null) {
      canvas.drawCircle(selectedOffset, strokeWidth * 4.0, Paint()..color = backgroundColor);
      canvas.drawCircle(
        selectedOffset,
        strokeWidth * 1.5,
        Paint()
          ..shader = curveGradientShader
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
    }

    // Draw labels
    for (var i = 0; i < _itemCount; i++) {
      final textBounds = canvas.drawText(
        '${(i + 1).toString().padLeft(2, "0")}',
        center: Offset(offsets[i].dx, viewportRect.bottom - (labelHeight / 2)),
        style: TextStyle(
          fontSize: labelHeight / (_selectedIndex == i ? 1.5 : 2.125),
          fontWeight: _selectedIndex == i ? FontWeight.w600 : FontWeight.w500,
          letterSpacing: 1.05,
          color: _selectedIndex == i ? labelColor : mutedLabelColor,
        ),
      );
      debugBounds.add(textBounds);
    }
  }

  @override
  void debugPaint(PaintingContext context, ui.Offset offset) {
    assert(() {
      super.debugPaint(context, offset);

      if (debugPaintSizeEnabled) {
        debugBounds.forEach((bounds) {
          context.canvas.drawRect(
              bounds,
              Paint()
                ..style = PaintingStyle.stroke
                ..color = const Color(0xFF00FFFF));
        });
      }

      return true;
    }());
  }

  Path _createDashedLinePath(Offset offset, double length, double dashLength) {
    final path = Path()..moveTo(offset.dx, offset.dy);
    for (var j = 0; j < (((length / (dashLength * 2)) * 2) - 1); j++) {
      j % 2 == 0 ? (path..relativeLineTo(0, dashLength)) : (path..relativeMoveTo(0, dashLength));
    }
    return path;
  }
}
