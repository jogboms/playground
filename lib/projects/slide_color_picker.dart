import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class SlideColorPicker extends StatefulWidget {
  @override
  _SlideColorPickerState createState() => _SlideColorPickerState();
}

class _SlideColorPickerState extends State<SlideColorPicker> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(
          child: SizedBox(
            height: 100,
            child: ColorPicker(
              vsync: this,
              onChanged: (color) {
                print(color);
              },
            ),
          ),
        ),
      ),
    );
  }
}

class ColorPicker extends LeafRenderObjectWidget {
  const ColorPicker({Key? key, required this.vsync, this.onChanged}) : super(key: key);

  final TickerProvider vsync;
  final ValueChanged<Color>? onChanged;

  @override
  RenderColorPicker createRenderObject(BuildContext context) {
    return RenderColorPicker(vsync: vsync, onChanged: onChanged);
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderColorPicker renderObject) {
    renderObject
      ..vsync = vsync
      ..onChanged = onChanged;
  }
}

class RenderColorPicker extends RenderBox {
  RenderColorPicker({
    required TickerProvider vsync,
    ValueChanged<Color>? onChanged,
  })  : _vsync = vsync,
        _onChanged = onChanged {
    colorsSpectrum = [
      for (var i = 0; i < maxColorHue; i++) _resolveColorFromHue(i.toDouble()),
    ];
    drag = HorizontalDragGestureRecognizer()
      ..onStart = _onStartDrag
      ..onUpdate = _onUpdateDrag
      ..onEnd = _onEndDrag
      ..onCancel = _onCancelDrag;
    tap = TapGestureRecognizer()..onTapDown = _onTapDown;
  }

  late HorizontalDragGestureRecognizer drag;
  late TapGestureRecognizer tap;
  late List<Color> colorsSpectrum;
  late RRect trackHandleBounds;
  late RRect controlHandleBounds;
  late AnimationController slideController;

  TickerProvider _vsync;

  set vsync(TickerProvider vsync) {
    if (vsync == _vsync) {
      return;
    }
    _vsync = vsync;
    slideController.resync(_vsync);
  }

  ValueChanged<Color>? _onChanged;

  set onChanged(ValueChanged<Color>? onChanged) {
    _onChanged = onChanged;
  }

  static const maxColorHue = 360;
  static const controlHandleColor = Color(0xFFFFFFFF);
  static const shadowColor = Color(0x43000000);

  void _onStartDrag(DragStartDetails details) {
    slideController.value = _resolveHorizontalOffsetFromLocalPosition(details.localPosition);
    markNeedsPaint();
  }

  void _onUpdateDrag(DragUpdateDetails details) {
    slideController.value += details.primaryDelta!;
    markNeedsPaint();
  }

  void _onEndDrag(DragEndDetails _) {
    _onCancelDrag();
  }

  void _onCancelDrag() {
    _onChanged?.call(selectedColor);
    HapticFeedback.selectionClick();
  }

  void _onTapDown(TapDownDetails details) {
    slideController
        .animateTo(_resolveHorizontalOffsetFromLocalPosition(details.localPosition))
        .whenCompleteOrCancel(_onCancelDrag);
  }

  double get selectedPercent {
    final resolvedWidth = math.max(1, trackHandleBounds.width);
    return slideController.value.clamp(0.0, resolvedWidth) / resolvedWidth;
  }

  Color get selectedColor => _resolveColorFromHue(selectedPercent * maxColorHue);

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);

    slideController = AnimationController.unbounded(
      value: 0.0,
      vsync: _vsync,
      duration: Duration(milliseconds: 350),
    )..addListener(markNeedsPaint);
  }

  @override
  void detach() {
    slideController.removeListener(markNeedsPaint);

    super.detach();
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  bool hitTestSelf(Offset position) => controlHandleBounds.contains(position) || trackHandleBounds.contains(position);

  @override
  void handleEvent(PointerEvent event, covariant BoxHitTestEntry entry) {
    if (event is PointerDownEvent) {
      final position = globalToLocal(event.position);
      if (controlHandleBounds.contains(position)) {
        drag.addPointer(event);
      } else if (trackHandleBounds.contains(position)) {
        tap.addPointer(event);
      }
    }
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return _computeSize(constraints);
  }

  @override
  void performLayout() {
    size = _computeSize(constraints);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final trackHeight = _controlHandleHeight / 3;
    final trackBounds = Rect.fromCenter(
      center: size.bottomCenter(offset).translate(0, -_controlHandleHeight / 2),
      width: size.width - _controlHandleHeight,
      height: trackHeight,
    );
    trackHandleBounds = RRect.fromRectAndRadius(trackBounds, Radius.circular(trackHeight / 2));

    // Draw color spectrum
    canvas.drawRRect(
      trackHandleBounds,
      Paint()..shader = LinearGradient(colors: colorsSpectrum).createShader(trackBounds),
    );

    // Compute control handle & preview
    final handleBounds = Rect.fromCircle(
      center: Offset((selectedPercent * trackBounds.width) + trackBounds.left, trackBounds.center.dy),
      radius: _controlHandleHeight / 2,
    );
    controlHandleBounds = RRect.fromRectAndRadius(handleBounds, Radius.circular(_controlHandleHeight / 4));

    final triangleLength = _previewHeight * .125;
    final previewSpace = triangleLength * .75;
    final previewOffset = handleBounds.topCenter - Offset(0, previewSpace);
    final previewRadius = (_previewHeight - triangleLength - previewSpace) / 2;
    const previewRadiusRatio = 2.5;
    final previewCenter = previewOffset.translate(0, -previewRadius - triangleLength);
    final previewPath = Path()
      ..moveTo(previewOffset.dx, previewOffset.dy)
      ..relativeLineTo(triangleLength, -triangleLength)
      ..relativeLineTo(-triangleLength * 2, 0)
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCircle(center: previewCenter, radius: previewRadius),
          Radius.circular(previewRadius / previewRadiusRatio),
        ),
      )
      ..addRRect(controlHandleBounds);

    // Compute handle arrow icons
    final iconSize = trackHeight / 2.25;
    final iconSpacing = iconSize / 2.5;
    const iconWidthFactor = 1.75;
    previewPath.addPath(
      Path()
        ..moveTo(handleBounds.center.dx - iconSpacing, handleBounds.center.dy - iconSize)
        ..relativeLineTo(-iconSize * iconWidthFactor, iconSize)
        ..relativeLineTo(iconSize * iconWidthFactor, iconSize)
        ..relativeMoveTo(iconSpacing * 2.0, 0)
        ..relativeLineTo(iconSize * iconWidthFactor, -iconSize)
        ..relativeLineTo(-iconSize * iconWidthFactor, -iconSize)
        ..close(),
      offset,
    );

    // Draw control handle shadow
    canvas.drawPath(
      previewPath,
      Paint()
        ..color = shadowColor
        ..maskFilter = ui.MaskFilter.blur(BlurStyle.normal, previewRadius / 1.5),
    );
    // Draw control handle
    canvas.drawPath(previewPath, Paint()..color = controlHandleColor);

    // Draw preview color
    final borderPadding = previewRadius / 6.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCircle(center: previewCenter, radius: previewRadius - borderPadding),
        Radius.circular((previewRadius - borderPadding) / previewRadiusRatio),
      ),
      Paint()..color = selectedColor,
    );
  }

  static Color _resolveColorFromHue(double value) {
    return HSLColor.fromAHSL(1, value, 1.0, .5).toColor();
  }

  Size _computeSize(BoxConstraints constraints) {
    return constraints.constrain(Size(_initialPreferredSize.width, _controlHandleHeight + _previewHeight));
  }

  Size get _initialPreferredSize {
    final maxSize = constraints.biggest;
    return Size(maxSize.width.clamp(100.0, 800.0).toDouble(), maxSize.height.clamp(0.0, 300.0).toDouble());
  }

  double get _controlHandleHeight => _initialPreferredSize.height * 0.45;

  double get _previewHeight => _initialPreferredSize.height * 0.55;

  double _resolveHorizontalOffsetFromLocalPosition(Offset position) {
    return position.dx - trackHandleBounds.left;
  }
}
