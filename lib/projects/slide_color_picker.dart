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
      backgroundColor: Colors.white,
      body: Container(
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
  const ColorPicker({Key key, @required this.vsync, this.onChanged}) : super(key: key);

  final TickerProvider vsync;
  final ValueChanged<Color> onChanged;

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
    @required TickerProvider vsync,
    ValueChanged<Color> onChanged,
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

  HorizontalDragGestureRecognizer drag;
  TapGestureRecognizer tap;
  List<Color> colorsSpectrum;
  RRect trackHandleBounds;
  RRect controlHandleBounds;
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

  ValueChanged<Color> _onChanged;

  set onChanged(ValueChanged<Color> onChanged) {
    if (_onChanged == onChanged) {
      return;
    }
    _onChanged = onChanged;
  }

  static const maxColorHue = 360;
  static const controlHandleColor = Color(0xFFFFFFFF);
  static const iconColor = Color(0xFF444444);
  static const shadowColor = Color(0x38000000);

  void _onStartDrag(DragStartDetails details) {
    slideController.value = _resolveHorizontalOffsetFromLocalPosition(details.localPosition);
    markNeedsPaint();
  }

  void _onUpdateDrag(DragUpdateDetails details) {
    slideController.value += details.primaryDelta;
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
    return slideController.value.clamp(0.0, trackHandleBounds.width) / trackHandleBounds.width;
  }

  Color get selectedColor {
    return _resolveColorFromHue(selectedPercent * maxColorHue);
  }

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
  BoxConstraints get constraints => super.constraints.loosen();

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
    final trackHeight = _resolveTrackHeight(constraints);
    final controlHandleHeight = _resolveControlHandleHeight(trackHeight);
    final trackBounds = Rect.fromCenter(
      center: size.bottomCenter(offset).translate(0, -controlHandleHeight / 2),
      width: size.width - controlHandleHeight,
      height: trackHeight,
    );
    trackHandleBounds = RRect.fromRectAndRadius(trackBounds, Radius.circular(trackHeight / 2));

    // Draw color spectrum
    canvas.drawRRect(
      trackHandleBounds,
      Paint()..shader = LinearGradient(colors: colorsSpectrum).createShader(trackBounds),
    );

    // Draw control handle & preview
    final handleBounds = Rect.fromCircle(
      center: Offset((selectedPercent * trackBounds.width) + trackBounds.left, trackBounds.center.dy),
      radius: controlHandleHeight / 2,
    );
    controlHandleBounds = RRect.fromRectAndRadius(handleBounds, Radius.circular(controlHandleHeight / 4));

    final triangleLength = _resolveIconSize(trackHeight);
    final previewOffset = handleBounds.center - Offset(0, _resolvePreviewSpacing(trackHeight));
    final previewRadius = _resolvePreviewHeight(trackHeight) / 2;
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
      ..addRRect(controlHandleBounds)
      ..close();
    canvas.drawPath(
      previewPath,
      Paint()
        ..color = shadowColor
        ..maskFilter = ui.MaskFilter.blur(BlurStyle.normal, previewRadius / 1.5),
    );
    canvas.drawPath(previewPath, Paint()..color = controlHandleColor);

    // Draw preview color
    final delta = previewRadius / 6.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCircle(center: previewCenter, radius: previewRadius - delta),
        Radius.circular((previewRadius - delta) / previewRadiusRatio),
      ),
      Paint()..color = selectedColor,
    );

    // Draw handle arrow icons
    final iconSize = _resolveIconSize(trackHeight);
    final iconSpacing = iconSize / 2.5;
    const iconWidthFactor = 1.75;
    final cursorPath = Path()
      ..moveTo(handleBounds.center.dx - iconSpacing, handleBounds.center.dy - iconSize)
      ..relativeLineTo(-iconSize * iconWidthFactor, iconSize)
      ..relativeLineTo(iconSize * iconWidthFactor, iconSize)
      ..relativeMoveTo(iconSpacing * 2.0, 0)
      ..relativeLineTo(iconSize * iconWidthFactor, -iconSize)
      ..relativeLineTo(-iconSize * iconWidthFactor, -iconSize)
      ..close();
    canvas.drawPath(cursorPath, Paint()..color = iconColor);
  }

  static Color _resolveColorFromHue(double value) {
    return HSLColor.fromAHSL(1, value, 1.0, .5).toColor();
  }

  static Size _computeSize(BoxConstraints constraints) {
    final trackHeight = _resolveTrackHeight(constraints);
    final previewHeight = _resolvePreviewHeight(trackHeight) + _resolveIconSize(trackHeight);
    final previewSpacing = _resolvePreviewSpacing(trackHeight);
    final controlHandleHeight = _resolveControlHandleHeight(trackHeight);
    return constraints.constrain(Size(constraints.maxWidth, previewHeight + previewSpacing + controlHandleHeight));
  }

  static double _resolveTrackHeight(BoxConstraints constraints) {
    return constraints.maxHeight * .125;
  }

  static double _resolveControlHandleHeight(double trackHeight) {
    return trackHeight * 3.5;
  }

  static double _resolvePreviewHeight(double trackHeight) {
    return trackHeight * 3.25;
  }

  static double _resolvePreviewSpacing(double trackHeight) {
    return trackHeight * 2.25;
  }

  static double _resolveIconSize(double trackHeight) {
    return trackHeight * .5;
  }

  double _resolveHorizontalOffsetFromLocalPosition(Offset position) {
    return position.dx - trackHandleBounds.left;
  }
}
