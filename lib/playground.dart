import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import './extensions.dart';

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
      body: Center(
        child: SizedBox(
          height: 600,
          child: GraphViewWidget(vsync: this),
        ),
      ),
    );
  }
}

class GraphViewWidget extends LeafRenderObjectWidget {
  const GraphViewWidget({Key key, @required this.vsync}) : super(key: key);

  final TickerProvider vsync;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderGraphViewWidget(vsync: vsync);
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderGraphViewWidget renderObject) {
    renderObject..vsync = vsync;
  }
}

class RenderGraphViewWidget extends RenderBox {
  RenderGraphViewWidget({
    @required TickerProvider vsync,
  }) : _vsync = vsync;

  AnimationController slideController;

  TickerProvider _vsync;

  set vsync(TickerProvider vsync) {
    assert(vsync != null);
    if (vsync == _vsync) {
      return;
    }
    _vsync = vsync;
    slideController.resync(_vsync);
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);

    slideController = AnimationController(
      value: 0.0,
      vsync: _vsync,
      duration: Duration(seconds: 1),
    )..addListener(markNeedsPaint);

    slideController.repeat(reverse: true);
  }

  @override
  void detach() {
    slideController.removeListener(markNeedsPaint);

    super.detach();
  }

  @override
  bool get isRepaintBoundary => true;

  Set<Rect> debugBounds = {};

  @override
  void performLayout() {
    size = constraints.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    debugBounds.clear();
    final canvas = context.canvas;
    final bounds = offset & size;
    debugBounds.add(bounds);

    // Generate points offset
    final offsets = <Offset>[];
    const totalCount = 150;
    final radius = size.radius;
    for (var i = 0; i < totalCount; i++) {
      offsets.add(
        toPolar(
          bounds.center,
          360.0.radians * (i + 1) / totalCount,
          slideController.value * radius,
          // slideController.value * radius * math.Random().nextDouble().between(radius - 10, radius),
        ),
      );
    }

    offsets.add(offsets.first);

    // Generate curved path from spline
    final spline = CatmullRomSpline(offsets).generateSamples(end: slideController.value);
    final curvedPath = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (final sample in spline) {
      curvedPath..lineTo(sample.value.dx, sample.value.dy);
    }

    // Draw curved path
    const strokeWidth = 6.0;
    canvas.drawPath(
      curvedPath,
      Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth,
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
