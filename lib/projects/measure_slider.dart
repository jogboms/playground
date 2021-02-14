import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:playground/extensions.dart';

class MeasureSlider extends StatefulWidget {
  @override
  _MeasureSliderState createState() => _MeasureSliderState();
}

class _MeasureSliderState extends State<MeasureSlider> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          height: 200,
          child: MeasureView(
            value: 50.0,
            unit: 'cm',
            labelBuilder: (value) => '${value.toInt()}',
            onChanged: (value) {
              print(value);
            },
          ),
        ),
      ),
    );
  }
}

typedef LabelBuilder = String Function(double value);

class MeasureView extends ScrollView {
  MeasureView({
    Key key,
    this.unit = '',
    this.value,
    this.itemCount,
    this.itemExtent,
    this.itemTickStep,
    this.onChanged,
    this.labelBuilder,
  }) : super(key: key, scrollDirection: Axis.horizontal, physics: BouncingScrollPhysics());

  final double value;
  final String unit;
  final int itemCount;
  final double itemExtent;
  final int itemTickStep;
  final ValueChanged<double> onChanged;
  final LabelBuilder labelBuilder;

  @override
  List<Widget> buildSlivers(BuildContext context) {
    return [
      MeasureViewWidget(
        value: value,
        unit: unit,
        itemCount: itemCount,
        itemExtent: itemExtent,
        itemTickStep: itemTickStep,
        onChanged: onChanged,
        labelBuilder: labelBuilder,
      ),
    ];
  }
}

class MeasureViewWidget extends LeafRenderObjectWidget {
  const MeasureViewWidget({
    Key key,
    this.value,
    this.unit,
    this.itemCount,
    this.itemExtent,
    this.itemTickStep,
    this.onChanged,
    this.labelBuilder,
  }) : super(key: key);

  final double value;
  final String unit;
  final int itemCount;
  final double itemExtent;
  final int itemTickStep;
  final ValueChanged<double> onChanged;
  final LabelBuilder labelBuilder;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderMeasureViewWidget(
      value: value,
      controller: ScrollController()..attach(Scrollable.of(context).position),
      unit: unit,
      itemCount: itemCount,
      itemExtent: itemExtent,
      itemTickStep: itemTickStep,
      onChanged: onChanged,
      labelBuilder: labelBuilder,
    );
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderMeasureViewWidget renderObject) {
    renderObject
      ..value = value
      ..unit = unit
      ..itemCount = itemCount
      ..itemExtent = itemExtent
      ..itemTickStep = itemTickStep
      ..onChanged = onChanged
      ..labelBuilder = labelBuilder;
  }
}

class RenderMeasureViewWidget extends RenderSliver {
  RenderMeasureViewWidget({
    @required this.controller,
    double value,
    String unit,
    int itemCount,
    double itemExtent,
    int itemTickStep,
    ValueChanged<double> onChanged,
    LabelBuilder labelBuilder,
  })  : _unit = unit,
        _itemCount = itemCount ?? 20,
        _itemExtent = itemExtent ?? 80.0,
        _itemTickStep = itemTickStep ?? 5,
        _onChanged = onChanged,
        _labelBuilder = labelBuilder ?? ((value) => '$value') {
    tap = TapGestureRecognizer()..onTapUp = _onTap;
  }

  final ScrollController controller;

  TapGestureRecognizer tap;

  void _onTap(TapUpDetails details) {
    value = ((constraints.scrollOffset + details.globalPosition.dx - (padding / 2)) / _itemExtent) * _itemTickStep;
  }

  String _unit;

  set unit(String unit) {
    if (_unit == unit) {
      return;
    }
    _unit = unit;
    markNeedsPaint();
  }

  int _itemCount;

  set itemCount(int itemCount) {
    if (_itemCount == itemCount || itemCount == null) {
      return;
    }
    _itemCount = itemCount;
    markNeedsLayout();
    markNeedsPaint();
  }

  double _itemExtent;

  set itemExtent(double itemExtent) {
    if (_itemExtent == itemExtent || itemExtent == null) {
      return;
    }
    _itemExtent = itemExtent;
    markNeedsLayout();
    markNeedsPaint();
  }

  int _itemTickStep;

  set itemTickStep(int itemTickStep) {
    if (_itemExtent == itemTickStep || itemTickStep == null) {
      return;
    }
    _itemTickStep = itemTickStep;
    markNeedsLayout();
    markNeedsPaint();
  }

  ValueChanged<double> _onChanged;

  set onChanged(ValueChanged<double> onChanged) {
    if (onChanged != null) {
      _onChanged = onChanged;
    }
  }

  LabelBuilder _labelBuilder;

  set labelBuilder(LabelBuilder labelBuilder) {
    if (labelBuilder != null) {
      _labelBuilder = labelBuilder;
    }
  }

  double _selectedValue;

  set value(double value) {
    if (_selectedValue == value || value == null) {
      return;
    }
    final _value = (value / _itemTickStep).discretize(tickDivisions);
    _onSelectValue(_value);
    markNeedsPaint();
    WidgetsBinding.instance.addPostFrameCallback((_) => _animateTo(_value * _itemExtent));
  }

  void _onSelectValue(double value) {
    if (_selectedValue == value) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HapticFeedback.selectionClick();
      _onChanged?.call(value);
      _selectedValue = value;
    });
  }

  void _animateTo(double horizontalOffset) {
    controller.animateTo(horizontalOffset, duration: Duration(milliseconds: 500), curve: Curves.linearToEaseOut);
  }

  static const itemMinHeight = 50.0;
  static const itemMaxHeight = 300.0;
  static const tickDivisions = 5;
  static const labelColor = Color(0xFFFFFFFF);
  static const shadowColor = Color(0xFF303030);

  List<Rect> debugLabelBounds = [];

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
    if (event is PointerDownEvent) {
      tap.addPointer(event);
    }
  }

  @override
  void performLayout() {
    final maxExtent = (_itemCount * _itemExtent) + padding;
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
    debugLabelBounds = [];
    final canvas = context.canvas;
    final viewportRect = offset & viewport;

    final standardFontSize = viewport.height / 12;
    final fontEnlargement = standardFontSize * 2.5;
    final enlargedFontSize = standardFontSize + fontEnlargement;

    final scrolledOffset = offset.translate(-constraints.scrollOffset, 0);
    final resolvedOffset = scrolledOffset.translate(padding / 2, 0);
    final normalizedHorizontalOffset = math.min(0, scrolledOffset.dx).abs();

    // Draw track
    final trackHeight = viewport.height * 4 / 5;
    final tickHeight = trackHeight / 10;
    final tickWidth = trackHeight / 60.0;
    final tickSpacing = _itemExtent / tickDivisions;
    final largeTickHeight = tickHeight * 2.25;
    final cursorTickHeight = largeTickHeight * 2;

    for (var i = 0; i < (_itemCount * tickDivisions) + 1; i++) {
      final dx = i * tickSpacing;
      final tickEndOffset = resolvedOffset.translate(dx, viewport.height - tickHeight / 2);

      final isVisibleInViewport = viewportRect.contains(tickEndOffset);
      if (!isVisibleInViewport) {
        continue;
      }

      final index = i ~/ tickDivisions;
      final isLargeTick = i % tickDivisions == 0;
      final resolvedTickHeight = isLargeTick ? largeTickHeight : tickHeight;
      final tickStartOffset = tickEndOffset.translate(0, -resolvedTickHeight);

      canvas.drawLine(
        tickStartOffset,
        tickEndOffset,
        Paint()
          ..color = labelColor.withOpacity(.2)
          ..strokeWidth = tickWidth
          ..strokeCap = StrokeCap.round,
      );

      // Draw labels
      if (isLargeTick) {
        final t = ((normalizedHorizontalOffset - dx).abs() / _itemExtent).clamp(0.0, 1.0);
        final fontSize = standardFontSize + (fontEnlargement * (1 - t));
        _drawLabel(
          canvas,
          _labelBuilder(index.toDouble() * _itemTickStep),
          fontSize,
          resolvedOffset.translate(dx, enlargedFontSize - fontSize),
          Color.lerp(labelColor.withOpacity(.3), labelColor, 1.0 - t),
          fontSize == enlargedFontSize,
        );
      }
    }
    _drawGradients(canvas, viewportRect);

    // Draw cursor
    final cursorBottomOffset = viewportRect.bottomCenter.translate(0, -tickHeight / 4);
    final cursorTopOffset = cursorBottomOffset.translate(0, -cursorTickHeight);
    canvas.drawLine(
      cursorTopOffset,
      cursorBottomOffset,
      Paint()
        ..color = Color(0xFF9465E4)
        ..strokeWidth = tickWidth * 1.5
        ..strokeCap = StrokeCap.round,
    );
    _drawLabel(
      canvas,
      _unit,
      standardFontSize,
      cursorTopOffset.translate(0, -standardFontSize * 2.5),
      Color(0xFFC366D5),
    );

    _onSelectValue((normalizedHorizontalOffset / _itemExtent).clamp(0.0, _itemCount.toDouble()).toDouble());
  }

  void _drawGradients(Canvas canvas, Rect viewport) {
    final dimOffset = viewport.width / 5;
    final leftRect = Rect.fromLTWH(viewport.left, 0.0, dimOffset, viewport.height);
    final colors = [shadowColor, shadowColor.withOpacity(0)];
    canvas.drawRect(
      leftRect,
      Paint()..shader = ui.Gradient.linear(leftRect.centerLeft, leftRect.centerRight, colors),
    );
    final rightRect = Rect.fromLTWH(viewport.right - dimOffset, 0.0, dimOffset, viewport.height);
    canvas.drawRect(
      rightRect,
      Paint()..shader = ui.Gradient.linear(rightRect.centerRight, rightRect.centerLeft, colors),
    );
  }

  void _drawLabel(Canvas canvas, String text, double fontSize, Offset offset, Color color, [bool shadow = false]) {
    final textPainter = TextPainter(textAlign: TextAlign.center, textDirection: TextDirection.rtl)
      ..text = TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: fontSize,
          shadows: [
            if (shadow) ui.Shadow(color: Colors.white38, offset: Offset(0, 1), blurRadius: 4),
          ],
        ),
      )
      ..layout();
    final bounds = (offset & textPainter.size).translate(-textPainter.width / 2, 0);
    textPainter.paint(canvas, bounds.topLeft);
    debugLabelBounds.add(bounds);
  }

  @override
  void debugPaint(PaintingContext context, ui.Offset offset) {
    assert(() {
      super.debugPaint(context, offset);

      if (debugPaintSizeEnabled) {
        debugLabelBounds.forEach((bounds) {
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
