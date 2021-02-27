import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
      backgroundColor: Colors.black,
      body: Center(
        child: SizedBox(
          height: 600,
          child: GraphView(),
        ),
      ),
    );
  }
}

class GraphView extends ScrollView {
  GraphView({Key key}) : super(key: key, scrollDirection: Axis.horizontal, physics: BouncingScrollPhysics());

  @override
  List<Widget> buildSlivers(BuildContext context) {
    return [
      GraphViewWidget(),
    ];
  }
}

class GraphViewWidget extends LeafRenderObjectWidget {
  const GraphViewWidget({Key key}) : super(key: key);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderGraphViewWidget(
      controller: ScrollController()..attach(Scrollable.of(context).position),
      values: List.generate(50, (_) => math.Random().nextDouble() * kMaxValue),
    );
  }
}

const kMaxValue = 500.0;

class RenderGraphViewWidget extends RenderSliver {
  RenderGraphViewWidget({
    @required this.controller,
    @required List<double> values,
  })  : _values = values,
        _maxValue = values.reduce(math.max);

  final ScrollController controller;

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

  void _animateTo(double horizontalOffset) {
    controller.animateTo(horizontalOffset, duration: Duration(milliseconds: 500), curve: Curves.linearToEaseOut);
  }

  static const itemExtent = 50.0;
  static const strokeColor = Color(0xFF6E50A3);
  static const shadowColor = Color(0xFF1B0F41);

  Set<Rect> debugBounds = {};

  @override
  bool hitTestSelf({double mainAxisPosition, double crossAxisPosition}) {
    return true;
  }

  @override
  void handleEvent(PointerEvent event, covariant SliverHitTestEntry entry) {
    if (event is PointerDownEvent) {}
  }

  int get _itemCount => _values.length;

  @override
  void performLayout() {
    final maxExtent = (_itemCount - 1) * itemExtent;
    final extent = math.max(constraints.viewportMainAxisExtent, maxExtent);
    final paintExtent = calculatePaintOffset(constraints, from: 0.0, to: extent);
    final cacheExtent = calculateCacheOffset(constraints, from: 0.0, to: extent);

    geometry = SliverGeometry(
      scrollExtent: extent,
      paintExtent: paintExtent,
      cacheExtent: cacheExtent,
      maxPaintExtent: extent,
      hitTestExtent: paintExtent,
      hasVisualOverflow: maxExtent > constraints.remainingPaintExtent || constraints.scrollOffset > 0.0,
    );
  }

  Size get viewport => Size(constraints.viewportMainAxisExtent, constraints.crossAxisExtent);

  @override
  void paint(PaintingContext context, Offset offset) {
    debugBounds.clear();
    final canvas = context.canvas;
    final viewportRect = offset & viewport;
    debugBounds.add(viewportRect);

    // Generate points offset
    final scrolledOffset = offset.translate(-constraints.scrollOffset, 0);
    final viewportHeight = viewportRect.height;
    final offsets = <Offset>[];
    for (var i = 0; i < _itemCount; i++) {
      offsets.add(scrolledOffset + Offset(i * itemExtent, viewportHeight * (1 - (_values[i] / _maxValue))));
    }

    // Generate curved path from spline
    final spline = CatmullRomSpline(offsets).generateSamples();
    final curvedPath = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (final sample in spline) {
      curvedPath..lineTo(sample.value.dx, sample.value.dy);
    }

    // Draw filled curved path
    final fillPath = Path.from(curvedPath)
      ..lineTo(offsets.last.dx, viewportHeight)
      ..lineTo(offsets.first.dx, viewportHeight);
    final fillPathBounds = fillPath.getBounds();
    debugBounds.add(fillPathBounds);
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          colors: [shadowColor, Color(0x00000000)],
          stops: [0.6, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(fillPathBounds),
    );

    // Draw curved path
    canvas.drawPath(
      curvedPath,
      Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0,
    );
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
}
