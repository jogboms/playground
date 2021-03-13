import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'extensions.dart';

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
      backgroundColor: Color(0xFF161616),
      body: Center(
        child: SizedBox.fromSize(
          size: Size.square(640.0),
          child: A(),
        ),
      ),
    );
  }
}

class A extends LeafRenderObjectWidget {
  @override
  B createRenderObject(BuildContext context) {
    return B();
  }
}

class U {
  const U({
    @required this.progress,
    @required this.color,
    @required this.icon,
    @required this.iconColor,
  });

  final double progress;
  final Color color;
  final IconData icon;
  final Color iconColor;
}

class B extends RenderBox with RenderBoxDebugBounds {
  @override
  bool get sizedByParent => true;

  @override
  ui.Size computeDryLayout(BoxConstraints constraints) {
    return constraints.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final bounds = offset & size;
    debugBounds.add(bounds);

    final items = [
      U(
        progress: 0,
        icon: Icons.nightlight_round,
        color: Color(0xFFFF7C31),
        iconColor: Color(0xFFFFFFFF),
      ),
      U(
        progress: 0,
        icon: Icons.opacity,
        color: Color(0xFF951EFD),
        iconColor: Color(0xFFFFFFFF),
      ),
      U(
        progress: 0,
        icon: Icons.star,
        color: Color(0xFFFF2F78),
        iconColor: Color(0xFFFFFFFF),
      ),
    ];
    final baseRadius = size.radius * .4;
    final ringSpacing = baseRadius * .05;
    final ringWidth = (size.radius - baseRadius - (ringSpacing * (items.length - 1))) / items.length;
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      _drawRing(
        canvas,
        sweepAngle: (90 * (i + 1)).radians,
        strokeWidth: ringWidth,
        center: bounds.center,
        radius: baseRadius + (ringWidth * (i + 1)) + (ringSpacing * i),
        color: item.color,
        icon: item.icon,
        iconColor: item.iconColor,
      );
    }

    const textColor = Color(0xFFFFFFFF);
    final titleTextBounds = canvas.drawText(
      '57%',
      center: bounds.center,
      style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: baseRadius * .45),
    );
    debugBounds.add(titleTextBounds);

    final captionFontSize = baseRadius * .175;
    final captionTextBounds = canvas.drawText(
      'Done',
      center: titleTextBounds.bottomCenter.translate(0, captionFontSize * .75),
      style: TextStyle(color: textColor, fontWeight: FontWeight.w300, fontSize: captionFontSize),
    );
    debugBounds.add(captionTextBounds);
  }

  void _drawRing(
    Canvas canvas, {
    @required double sweepAngle,
    @required double strokeWidth,
    @required Offset center,
    @required double radius,
    @required Color color,
    @required IconData icon,
    @required Color iconColor,
  }) {
    final innerRadius = radius - strokeWidth;
    final trackPath = Path()
      ..moveTo(center.dx + radius, center.dy)
      ..relativeArcToPoint(Offset(-radius * 2, 0), radius: Radius.circular(radius))
      ..relativeArcToPoint(Offset(radius * 2, 0), radius: Radius.circular(radius))
      ..relativeMoveTo(-strokeWidth, 0)
      ..relativeArcToPoint(Offset(-innerRadius * 2, 0), radius: Radius.circular(innerRadius), clockwise: false)
      ..relativeArcToPoint(Offset(innerRadius * 2, 0), radius: Radius.circular(innerRadius), clockwise: false);
    canvas.drawPath(trackPath, Paint()..color = Color(0xFF2D2D2D));
    debugPaths.add(trackPath);

    final startAngle = -90.radians;
    final endAngle = sweepAngle + startAngle;
    final isLargeArc = endAngle >= 90.radians;
    final startOuterOffset = toPolar(center, startAngle, radius);
    final startInnerOffset = toPolar(center, startAngle, radius - strokeWidth);
    final endOuterOffset = toPolar(center, endAngle, radius);
    final endInnerOffset = toPolar(center, endAngle, radius - strokeWidth);
    final progressPath = Path()
      ..moveTo(startOuterOffset.dx, startOuterOffset.dy)
      ..arcToPoint(
        endOuterOffset,
        radius: Radius.circular(radius),
        largeArc: isLargeArc,
      )
      ..arcToPoint(endInnerOffset, radius: Radius.circular(strokeWidth / 2))
      ..arcToPoint(
        startInnerOffset,
        radius: Radius.circular(radius - strokeWidth),
        largeArc: isLargeArc,
        clockwise: false,
      )
      ..arcToPoint(startOuterOffset, radius: Radius.circular(strokeWidth / 2));
    canvas.drawPath(progressPath, Paint()..color = color);
    debugPaths.add(progressPath);

    final iconOffset = toPolar(center, startAngle, radius - strokeWidth / 2);
    final iconBounds = canvas.drawText(
      String.fromCharCode(icon.codePoint),
      center: iconOffset,
      style: TextStyle(fontFamily: Icons.star.fontFamily, fontSize: strokeWidth * .5, color: iconColor),
    );
    debugBounds.add(iconBounds);
  }
}
