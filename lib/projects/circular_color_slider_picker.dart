import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:playground/extensions.dart';

class CircularColorSliderPicker extends StatefulWidget {
  const CircularColorSliderPicker({Key? key}) : super(key: key);

  @override
  _CircularColorSliderPickerState createState() => _CircularColorSliderPickerState();
}

class _CircularColorSliderPickerState extends State<CircularColorSliderPicker> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox.fromSize(
          size: const Size(400, 500),
          child: DecoratedBox(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Stack(
              children: [
                CircularColorSliderPickerWidget(
                  onChanged: (Color color) {
                    // print(color);
                  },
                ),
                Positioned.fill(
                  top: null,
                  bottom: 48,
                  child: Center(
                    child: Column(
                      children: const [
                        Icon(Icons.swipe, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'DRAG FROM LEFT TO RIGHT',
                          style: TextStyle(color: Colors.grey, fontSize: 14, letterSpacing: 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CircularColorSliderPickerWidget extends LeafRenderObjectWidget {
  const CircularColorSliderPickerWidget({Key? key, this.onChanged}) : super(key: key);

  final ValueChanged<Color>? onChanged;

  @override
  RenderCircularColorSliderPicker createRenderObject(BuildContext context) =>
      RenderCircularColorSliderPicker().._onChanged = onChanged;

  @override
  void updateRenderObject(BuildContext context, covariant RenderCircularColorSliderPicker renderObject) =>
      renderObject.._onChanged = onChanged;
}

class RenderCircularColorSliderPicker extends RenderBox {
  RenderCircularColorSliderPicker()
      : colorsSpectrum = [for (var i = 0; i < fullAngle; i++) _resolveColorFromHue(fullAngle - i.toDouble())] {
    drag = HorizontalDragGestureRecognizer()..onUpdate = _onDragUpdate;
  }

  static const colorShiftMagnitude = 4;

  late final HorizontalDragGestureRecognizer drag;
  late final List<Color> colorsSpectrum;

  double get selectedAngle => _selectedAngle;
  double _selectedAngle = 0;

  set selectedAngle(double angle) {
    if (_selectedAngle == angle) {
      return;
    }
    _selectedAngle = angle;
    markNeedsPaint();
  }

  ValueChanged<Color>? _onChanged;

  Color get selectedColor =>
      _resolveColorFromHue(fullAngle - (-selectedAngle * colorShiftMagnitude).normalize(fullAngle));

  void _onDragUpdate(DragUpdateDetails details) {
    selectedAngle += details.primaryDelta ?? 0.0;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      HapticFeedback.selectionClick();
      _onChanged?.call(selectedColor);
    });
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is PointerDownEvent) {
      drag.addPointer(event);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    canvas.clipRect(Offset.zero & size);

    final trackCenter = Offset(size.width * .5, size.height * 1.125);
    final trackRadius = size.width * .75;
    final trackThickness = size.width * .0375;
    const trackArcRadius = Radius.circular(1);
    final trackBounds = Rect.fromCircle(center: trackCenter, radius: trackRadius);
    final trackPath = Path()
      ..moveTo(trackBounds.topCenter.dx, trackBounds.topCenter.dy + trackThickness)
      ..arcToPoint(trackBounds.bottomCenter.translate(0, -trackThickness), radius: trackArcRadius)
      ..arcToPoint(trackBounds.topCenter.translate(0, trackThickness), radius: trackArcRadius)
      ..moveTo(trackBounds.topCenter.dx, trackBounds.topCenter.dy)
      ..arcToPoint(trackBounds.bottomCenter, radius: trackArcRadius, clockwise: false)
      ..arcToPoint(trackBounds.topCenter, radius: trackArcRadius, clockwise: false);
    canvas
      ..drawShadow(trackPath, Colors.black54, trackBounds.radius * .05, false)
      ..drawPath(trackPath.shift(Offset(0, trackBounds.radius * .015)), Paint()..color = Colors.white)
      ..drawPath(
        trackPath,
        Paint()
          ..shader = SweepGradient(
            endAngle: (fullAngle / colorShiftMagnitude).radians,
            tileMode: TileMode.repeated,
            transform: GradientRotation(selectedAngle.radians),
            colors: colorsSpectrum,
          ).createShader(trackBounds),
      );

    const indicatorColorsCount = 24;
    final indicatorTrackRadius = trackRadius + (size.width * .15);
    for (int i = 0; i < indicatorColorsCount; i += 1) {
      final angle = i * fullAngle / indicatorColorsCount;
      canvas.drawCircle(
        trackCenter +
            Offset.fromDirection(
              (selectedAngle + angle).normalize(fullAngle).radians,
              indicatorTrackRadius * 0.95,
            ),
        size.width * .015,
        Paint()..color = _resolveColorFromHue(fullAngle - (angle * colorShiftMagnitude).normalize(fullAngle)),
      );
    }

    final indicatorCenter = trackCenter + Offset.fromDirection(-90.radians, indicatorTrackRadius);
    final indicatorRadius = size.width * .075;
    canvas
      ..drawShadow(
        Path()..addOval(Rect.fromCircle(center: indicatorCenter, radius: indicatorRadius)),
        Colors.black87,
        indicatorRadius * .5,
        true,
      )
      ..drawCircle(indicatorCenter, indicatorRadius, Paint()..color = Colors.white)
      ..drawCircle(indicatorCenter, indicatorRadius * .75, Paint()..color = selectedColor);

    final indicatorArrowWidth = trackThickness * .75;
    canvas.drawPath(
      Path()
        ..moveTo(trackBounds.topCenter.dx - indicatorArrowWidth / 2, trackBounds.topCenter.dy)
        ..relativeLineTo(indicatorArrowWidth / 2, -indicatorArrowWidth / 1.5)
        ..relativeLineTo(indicatorArrowWidth / 2, indicatorArrowWidth / 1.5),
      Paint()..color = selectedColor,
    );
  }
}

Color _resolveColorFromHue(double value) => HSLColor.fromAHSL(1, value, 1, .6).toColor();
