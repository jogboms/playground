import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../interpolate.dart';

class SlideToAction extends StatefulWidget {
  @override
  _SlideToActionState createState() => _SlideToActionState();
}

class _SlideToActionState extends State<SlideToAction> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF070813),
      body: Center(
        child: SlideButton(
          vsync: this,
          title: "SLIDE TO SEND",
          onTap: () {
            print("onTap");
          },
          onSlide: () {
            print("onSlide");
          },
        ),
      ),
    );
  }
}

class SlideButton extends LeafRenderObjectWidget {
  const SlideButton({Key key, this.title, this.onTap, this.onSlide, @required this.vsync}) : super(key: key);

  final String title;
  final VoidCallback onTap;
  final VoidCallback onSlide;
  final TickerProvider vsync;

  @override
  RenderSlideButton createRenderObject(BuildContext context) {
    return RenderSlideButton(title: title, onTap: onTap, onSlide: onSlide, vsync: vsync);
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderSlideButton renderObject) {
    renderObject
      ..title = title
      ..onTap = onTap
      ..onSlide = onSlide
      ..vsync = vsync;
  }
}

class RenderSlideButton extends RenderBox {
  RenderSlideButton({
    String title,
    VoidCallback onTap,
    VoidCallback onSlide,
    TickerProvider vsync,
  })  : _title = title,
        _onTap = onTap,
        _onSlide = onSlide,
        _vsync = vsync {
    final physics = BouncingScrollPhysics();
    drag = HorizontalDragGestureRecognizer()
      ..minFlingVelocity = physics.minFlingVelocity
      ..maxFlingVelocity = physics.maxFlingVelocity
      ..minFlingDistance = physics.dragStartDistanceMotionThreshold
      ..onStart = _onDragStart
      ..onUpdate = _onDragUpdate
      ..onCancel = _onDragCancel
      ..onEnd = _onDragEnd;
  }

  DragGestureRecognizer drag;
  AnimationController slideController;
  AnimationController heartBeatController;

  TickerProvider _vsync;

  set vsync(TickerProvider vsync) {
    assert(vsync != null);
    if (vsync == _vsync) {
      return;
    }
    _vsync = vsync;
    slideController.resync(_vsync);
    heartBeatController.resync(_vsync);
  }

  String _title;

  set title(String title) {
    assert(title != null);
    if (_title == title) {
      return;
    }
    _title = title;
  }

  VoidCallback _onTap;

  set onTap(VoidCallback onTap) {
    if (_onTap == onTap) {
      return;
    }
    _onTap = onTap;
  }

  VoidCallback _onSlide;

  set onSlide(VoidCallback onSlide) {
    if (_onSlide == onSlide) {
      return;
    }
    _onSlide = onSlide;
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);

    slideController = AnimationController.unbounded(
      value: 0.0,
      vsync: _vsync,
      duration: Duration(milliseconds: 350),
    )..addListener(markNeedsPaint);

    heartBeatController = AnimationController(
      vsync: _vsync,
      duration: Duration(milliseconds: 1000),
    )
      ..addListener(markNeedsPaint)
      ..repeat(reverse: true);
  }

  @override
  void detach() {
    slideController.removeListener(markNeedsPaint);
    heartBeatController.removeListener(markNeedsPaint);

    super.detach();
  }

  void _onDragStart(DragStartDetails details) {
    slideController.animateTo(size.width * .05).whenCompleteOrCancel(() {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        _onTap?.call();
      });
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    slideController.value += details.primaryDelta;
  }

  void _onDragCancel() {
    slideController.value = 0.0;
  }

  void _onDragEnd(DragEndDetails details) {
    final threshold = size.width / 4;
    if (slideController.value > threshold) {
      slideController.animateTo(size.width).whenCompleteOrCancel(() {
        _onDragCancel();
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          _onSlide?.call();
        });
      });
      return;
    }
    slideController.animateBack(0.0).whenCompleteOrCancel(_onDragCancel);
  }

  @override
  bool hitTestSelf(ui.Offset position) => true;

  @override
  bool get isRepaintBoundary => true;

  @override
  void handleEvent(PointerEvent event, covariant BoxHitTestEntry entry) {
    if (event is PointerDownEvent) {
      drag.addPointer(event);
    }
  }

  @override
  void performLayout() {
    final effectiveConstraints = constraints.enforce(BoxConstraints(
      minHeight: 40,
      maxHeight: 80,
      maxWidth: 400,
    ));
    size = effectiveConstraints.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final value = math.max(0.0, slideController.value);
    final t = interpolate(inputMax: size.width)(value);
    final bounds = RRect.fromRectAndRadius(offset & size, Radius.circular(18));

    canvas.clipRRect(bounds);

    canvas.drawRRect(
      bounds,
      Paint()..color = Color.lerp(Color(0xFF141224), Color(0xFF5A01CB), Curves.decelerate.transform(t)),
    );

    final textColor = Colors.white.withOpacity(1 - Curves.decelerate.transform(t));
    final textRect = _drawParagraph(
      canvas,
      _title,
      offset: size.center(offset).translate(value, 0),
      color: textColor,
      fontSize: size.height / 5,
      fontWeight: FontWeight.w700,
    );

    final arrowOffset = textRect.centerLeft.translate(Curves.decelerate.transform(t) * value, 0);
    final iconData = Icons.chevron_right_rounded;
    final arrowCount = 3;
    for (int i = 0; i < arrowCount; i++) {
      _drawParagraph(
        canvas,
        String.fromCharCode(iconData.codePoint),
        offset: arrowOffset - Offset(i * 8.0, 0) + Offset(4 * heartBeatController.value, 0),
        color: Color.lerp(Colors.transparent, textColor.withOpacity(1.0 - (i * 1 / arrowCount)), 1 - t),
        fontSize: size.height / 3.5,
        fontFamily: iconData.fontFamily,
        fontWeight: FontWeight.w300,
      );
    }
  }

  Rect _drawParagraph(
    Canvas canvas,
    String text, {
    @required Offset offset,
    @required Color color,
    @required double fontSize,
    String fontFamily,
    FontWeight fontWeight,
  }) {
    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.center))
      ..pushStyle(ui.TextStyle(
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
        letterSpacing: 1.2,
        fontFamily: fontFamily,
      ))
      ..addText(text);
    final paragraph = builder.build();
    final constraints = ui.ParagraphConstraints(width: (fontSize / 1.25) * text.length);
    final finalOffset = offset - Offset(constraints.width / 2, fontSize / 2);
    canvas.drawParagraph(paragraph..layout(constraints), finalOffset);
    return Rect.fromLTWH(finalOffset.dx, finalOffset.dy, paragraph.longestLine, paragraph.height);
  }
}
