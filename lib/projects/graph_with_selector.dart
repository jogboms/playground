import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:playground/extensions.dart';
import 'package:playground/interpolate.dart';

class GraphWithSelector extends StatefulWidget {
  @override
  _GraphWithSelectorState createState() => _GraphWithSelectorState();
}

class _GraphWithSelectorState extends State<GraphWithSelector> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    const kMaxValue = 150.0;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SizedBox(
          height: 400,
          child: GraphView(
            vsync: this,
            values: List.generate(50, (_) => math.Random().nextDouble() * kMaxValue),
          ),
        ),
      ),
    );
  }
}

class GraphView extends ScrollView {
  GraphView({Key? key, required this.vsync, required this.values})
      : super(key: key, scrollDirection: Axis.horizontal, physics: BouncingScrollPhysics());

  final TickerProvider vsync;
  final List<double> values;

  @override
  List<Widget> buildSlivers(BuildContext context) {
    return [
      GraphViewWidget(vsync: vsync, values: values),
    ];
  }
}

class GraphViewWidget extends LeafRenderObjectWidget {
  const GraphViewWidget({Key? key, required this.vsync, required this.values}) : super(key: key);

  final TickerProvider vsync;
  final List<double> values;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderGraphViewWidget(
      vsync: vsync,
      controller: ScrollController()..attach(Scrollable.of(context)!.position),
      values: values,
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderGraphViewWidget renderObject) {
    renderObject
      ..vsync = vsync
      ..values = values;
  }
}

class RenderGraphViewWidget extends RenderSliver {
  RenderGraphViewWidget({
    required TickerProvider vsync,
    required List<double> values,
    required this.controller,
  })   : _vsync = vsync,
        _values = values,
        _maxValue = values.reduce(math.max) {
    tap = TapGestureRecognizer()..onTapDown = _onTapDown;
  }

  final ScrollController controller;

  late TapGestureRecognizer tap;

  double _maxValue;
  late AnimationController animation;

  TickerProvider _vsync;

  set vsync(TickerProvider vsync) {
    if (vsync == _vsync) {
      return;
    }
    _vsync = vsync;
    animation.resync(_vsync);
  }

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

  static const itemExtent = 48.0;
  static const strokeColor = Color(0xFF6E50A3);
  static const shadowColor = Color(0xFF1B0F41);
  static const selectorColor = Color(0xFFFFFFFF);
  static const backgroundColor = Color(0xFF000000);

  Set<Rect?> debugBounds = {};

  Rect? fillPathBounds;

  int? _selectedIndex;

  void _onTapDown(TapDownDetails details) {
    final offset = details.localPosition.dx + constraints.scrollOffset - (padding / 2);
    _selectedIndex = interpolate(inputMax: geometry!.maxPaintExtent - padding, outputMax: _itemCount - 1.0)(offset)
        .discretize(1)
        .toInt();
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);

    animation = AnimationController(
      value: 0.0,
      vsync: _vsync,
      duration: Duration(milliseconds: 10000),
    )
      ..addListener(markNeedsPaint)
      ..forward();

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      controller.animateTo(
        500, // You can do some calculations here using the geometry
        duration: Duration(milliseconds: 10000),
        curve: Curves.linearToEaseOut,
      );
    });
  }

  @override
  void detach() {
    animation
      ..removeListener(markNeedsPaint)
      ..dispose();

    super.detach();
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  bool hitTestSelf({required double mainAxisPosition, required double crossAxisPosition}) {
    return fillPathBounds!.contains(Offset(mainAxisPosition, crossAxisPosition));
  }

  @override
  void handleEvent(PointerEvent event, covariant SliverHitTestEntry entry) {
    if (event is PointerDownEvent) {
      tap.addPointer(event);
    }
  }

  int get _itemCount => _values.length;

  double get padding => itemExtent * 2;

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

  Size get viewport => Size(constraints.viewportMainAxisExtent, constraints.crossAxisExtent);

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
    final viewportHeight = viewportRect.height;
    final offsets = <Offset>[];
    for (var i = 0; i < _itemCount; i++) {
      offsets.add(
        scrolledOffset +
            Offset(
              i * itemExtent,
              viewportHeight * (1 - (_values[i] / _maxValue)),
            ),
      );
    }

    // Generate curved path from spline
    final spline = CatmullRomSpline(offsets).generateSamples(end: math.max(1e-10, animation.value));
    final curvedPath = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (final sample in spline) {
      curvedPath.lineTo(sample.value.dx, sample.value.dy);
    }

    // Draw filled curved path
    final fillPath = Path.from(curvedPath)
      ..lineTo(offsets.last.dx, viewportHeight)
      ..lineTo(offsets.first.dx, viewportHeight);
    fillPathBounds = fillPath.getBounds();
    debugBounds.add(fillPathBounds);
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          colors: [shadowColor, Color(0x00000000)],
          stops: [0.6, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(fillPathBounds!),
    );

    // Draw curved path
    const strokeWidth = 4.0;
    canvas.drawPath(
      curvedPath,
      Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth,
    );

    // Draw selector
    if (_selectedIndex != null) {
      const verticalOffset = 4.0;
      const circleRation = 2.5;
      final selectedOffset = offsets[_selectedIndex!];
      canvas.drawLine(
        Offset(selectedOffset.dx, viewportRect.top + verticalOffset),
        Offset(selectedOffset.dx, viewportRect.bottom - verticalOffset),
        Paint()
          ..color = selectorColor.withOpacity(.6)
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
      canvas.drawCircle(selectedOffset, (strokeWidth + 1) * circleRation, Paint()..color = backgroundColor);
      canvas.drawCircle(selectedOffset, strokeWidth * circleRation, Paint()..color = selectorColor);
    }
  }

  @override
  void debugPaint(PaintingContext context, ui.Offset offset) {
    assert(() {
      super.debugPaint(context, offset);

      if (debugPaintSizeEnabled) {
        debugBounds.forEach((bounds) {
          context.canvas.drawRect(
              bounds!,
              Paint()
                ..style = PaintingStyle.stroke
                ..color = const Color(0xFF00FFFF));
        });
      }

      return true;
    }());
  }
}
