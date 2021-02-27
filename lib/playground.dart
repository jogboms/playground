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
      body: Center(
        child: GraphView(),
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
    );
  }
}

class RenderGraphViewWidget extends RenderSliver {
  RenderGraphViewWidget({
    @required this.controller,
  });

  final ScrollController controller;

  void _animateTo(double horizontalOffset) {
    controller.animateTo(horizontalOffset, duration: Duration(milliseconds: 500), curve: Curves.linearToEaseOut);
  }

  static const itemCount = 50;
  static const itemExtent = 100;
  static const itemMinHeight = 50.0;
  static const itemMaxHeight = 300.0;
  static const tickDivisions = 5;
  static const labelColor = Color(0xFFFFFFFF);
  static const shadowColor = Color(0xFF303030);

  List<Rect> debugBounds = [];

  @override
  SliverConstraints get constraints => super.constraints.copyWith(
        crossAxisExtent: super.constraints.crossAxisExtent.clamp(itemMinHeight, itemMaxHeight).toDouble(),
      );

  @override
  bool hitTestSelf({double mainAxisPosition, double crossAxisPosition}) {
    return true;
  }

  @override
  void handleEvent(PointerEvent event, covariant SliverHitTestEntry entry) {
    if (event is PointerDownEvent) {}
  }

  @override
  void performLayout() {
    final maxExtent = (itemCount * itemExtent) + padding;
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

  double get padding => viewport.width;

  @override
  void paint(PaintingContext context, Offset offset) {
    debugBounds = [];
    final canvas = context.canvas;
    final viewportRect = offset & viewport;

    final standardFontSize = viewport.height / 12;
    final fontEnlargement = standardFontSize * 2.5;
    final enlargedFontSize = standardFontSize + fontEnlargement;

    final scrolledOffset = offset.translate(-constraints.scrollOffset, 0);
    final resolvedOffset = scrolledOffset.translate(padding / 2, 0);
    final normalizedHorizontalOffset = math.min(0, scrolledOffset.dx).abs();
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
