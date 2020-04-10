import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

const MaterialColor primaryAccent = MaterialColor(
  0xFF121212,
  <int, Color>{
    50: Color(0xFFf7f7f7),
    100: Color(0xFFeeeeee),
    200: Color(0xFFe2e2e2),
    300: Color(0xFFd0d0d0),
    400: Color(0xFFababab),
    500: Color(0xFF8a8a8a),
    600: Color(0xFF636363),
    700: Color(0xFF505050),
    800: Color(0xFF323232),
    900: Color(0xFF121212),
  },
);

void main() => runApp(
      MaterialApp(
        theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: primaryAccent),
        debugShowCheckedModeBanner: false,
        home: Playground(),
      ),
    );

const double maxValue = 500;
final ValueNotifier<Pair<double, double>> valueNotifier = ValueNotifier(const Pair(0, maxValue));

class Playground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ValueListenableBuilder<Pair<double, double>>(
              valueListenable: valueNotifier,
              builder: (_, value, __) => Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      "${value.a.toStringAsFixed(1)}",
                      style: Theme.of(context).textTheme.display3.copyWith(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Text(
                    "-",
                    style: Theme.of(context).textTheme.body1.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  Expanded(
                    child: Text(
                      "${value.b.toStringAsFixed(1)}",
                      style: Theme.of(context).textTheme.display3.copyWith(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            RangeSlider(
              lowerValue: valueNotifier.value.a,
              upperValue: valueNotifier.value.b,
              max: maxValue,
              labelBuilder: (value) => value.toInt().toString(),
              onChanged: (l, u) => valueNotifier.value = Pair(l, u),
            ),
          ],
        ),
      ),
    );
  }
}

typedef void RangeSliderCallback(double lowerValue, double upperValue);
typedef String LabelBuilder(double value);

class RangeSlider extends LeafRenderObjectWidget {
  const RangeSlider({
    Key key,
    this.min = 0.0,
    @required this.max,
    @required this.lowerValue,
    @required this.upperValue,
    @required this.labelBuilder,
    this.divisions = 50,
    this.onChanged,
  })  : assert(min != null),
        assert(max != null),
        assert(min <= max),
        assert(divisions != null),
        assert(divisions > 0),
        assert(labelBuilder != null),
        assert(lowerValue != null),
        assert(upperValue != null),
        assert(lowerValue >= min && lowerValue <= max),
        assert(upperValue > lowerValue && upperValue <= max),
        super(key: key);

  final RangeSliderCallback onChanged;
  final double lowerValue;
  final double upperValue;
  final double min;
  final double max;
  final int divisions;
  final LabelBuilder labelBuilder;

  @override
  _RenderRangeSlider createRenderObject(BuildContext context) {
    return _RenderRangeSlider(
      lowerValue: lowerValue,
      upperValue: upperValue,
      min: min,
      max: max,
      divisions: divisions,
      labelBuilder: labelBuilder,
      onChanged: onChanged,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderRangeSlider renderObject) {
    renderObject
      ..lowerValue = lowerValue
      ..upperValue = upperValue
      ..min = min
      ..max = max
      ..labelBuilder = labelBuilder
      ..divisions = divisions
      ..onChanged = onChanged;
  }
}

class _RenderRangeSlider extends RenderBox {
  _RenderRangeSlider({
    double lowerValue,
    double upperValue,
    double min,
    double max,
    int divisions,
    LabelBuilder labelBuilder,
    RangeSliderCallback onChanged,
  })  : _divisions = divisions,
        _labelBuilder = labelBuilder,
        _lowerValue = lowerValue,
        _upperValue = upperValue,
        _min = min,
        _max = max,
        _onChanged = onChanged {
    _drag = HorizontalDragGestureRecognizer()
      ..onStart = _handleDragStart
      ..onEnd = ((_) => _handleDragCancel())
      ..onUpdate = _handleDragUpdate
      ..onCancel = _handleDragCancel;
  }

  static const double _overlayRadius = 16.0;
  static const double _overlayDiameter = _overlayRadius * 2.0;
  static const double _trackRadius = 8.0;
  static const double _preferredTrackWidth = 144.0;
  static const double _preferredTotalWidth = _preferredTrackWidth + 2 * _overlayDiameter;
  static const double _thumbRadius = _trackRadius + 6.0;
  static const double _innerThumbRadius = _trackRadius;
  static const double _maxTickLength = _trackRadius * 2;
  static const double _itemSpacing = 6.0;
  static const double _labelFontSize = 10.0;

  double _currentDragValue = 0.0;
  HorizontalDragGestureRecognizer _drag;

  double _minDragValue;
  double _maxDragValue;

  _ActiveThumb _activeThumb = _ActiveThumb.none;

  Rect _trackRect;
  Rect _thumbLowerRect;
  Rect _thumbUpperRect;

  RangeSliderCallback _onChanged;

  set onChanged(RangeSliderCallback value) {
    if (_onChanged == value) {
      return;
    }
    _onChanged = value;
    markNeedsPaint();
  }

  double _lowerValue;

  set lowerValue(double value) {
    assert(value != null);
    final _value = value.unlerp(_min, _max);
    assert(_value >= 0.0 && _value <= 1.0);
    final newValue = _value.discretize(_divisions);
    if (_lowerValue == newValue) {
      return;
    }
    _lowerValue = newValue;
  }

  double _upperValue;

  set upperValue(double value) {
    assert(value != null);
    final _value = value.unlerp(_min, _max);
    assert(_value >= 0.0 && _value <= 1.0);
    final newValue = _value.discretize(_divisions);
    if (_upperValue == newValue) {
      return;
    }
    _upperValue = newValue;
  }

  int _divisions;

  set divisions(int value) {
    if (_divisions == value) {
      return;
    }
    _divisions = value;
    markNeedsPaint();
  }

  LabelBuilder _labelBuilder;

  set labelBuilder(LabelBuilder value) {
    if (_labelBuilder == value) {
      return;
    }
    _labelBuilder = value;
    markNeedsPaint();
  }

  double _min;

  set min(double value) {
    if (_min == value) {
      return;
    }
    _min = value;
    markNeedsPaint();
  }

  double _max;

  set max(double value) {
    if (_max == value) {
      return;
    }
    _max = value;
    markNeedsPaint();
  }

  void _handleDragStart(DragStartDetails details) {
    _currentDragValue = _getValueFromGlobalPosition(details.globalPosition);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final double valueDelta = details.primaryDelta / _trackRect.width;
    _currentDragValue += valueDelta;
    _onRangeChanged(_currentDragValue.clamp(_minDragValue, _maxDragValue));
  }

  void _handleDragCancel() {
    _activeThumb = _ActiveThumb.none;
    _currentDragValue = 0.0;
  }

  void _onRangeChanged(double value) {
    value = value.discretize(_divisions);

    if (_activeThumb == _ActiveThumb.lowerThumb) {
      _lowerValue = value;
    } else {
      _upperValue = value;
    }

    _onChanged?.call(_lowerValue.lerp(_min, _max), _upperValue.lerp(_min, _max));

    markNeedsPaint();
  }

  double _getValueFromGlobalPosition(Offset globalPosition) {
    return (globalToLocal(globalPosition).dx - _overlayDiameter) / _trackRect.width;
  }

  void _validateActiveThumb(Offset position) {
    if (_thumbLowerRect.contains(position)) {
      _activeThumb = _ActiveThumb.lowerThumb;
      _minDragValue = 0.0;
      _maxDragValue = (_upperValue - _thumbRadius * 2.0 / _trackRect.width).discretize(_divisions);
    } else if (_thumbUpperRect.contains(position)) {
      _activeThumb = _ActiveThumb.upperThumb;
      _minDragValue = (_lowerValue + _thumbRadius * 2.0 / _trackRect.width).discretize(_divisions);
      _maxDragValue = 1.0;
    } else {
      _activeThumb = _ActiveThumb.none;
    }
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  bool get sizedByParent => true;

  @override
  void performResize() {
    size = Size(
      constraints.hasBoundedWidth ? constraints.maxWidth : _preferredTotalWidth,
      constraints.hasBoundedHeight ? constraints.maxHeight : _overlayDiameter,
    );
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return 2 * _overlayDiameter;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return _preferredTotalWidth;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _overlayDiameter;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _overlayDiameter;
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is PointerDownEvent) {
      _validateActiveThumb(event.position);

      if (_activeThumb != _ActiveThumb.none) {
        _drag.addPointer(event);
        _handleDragStart(DragStartDetails(globalPosition: event.position));
      }
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;

    final Size calculatedSize = size - Offset(_thumbRadius * 2, 0);
    _trackRect = offset.translate(_thumbRadius, _thumbRadius / 2) & calculatedSize.copyWith(height: _trackRadius * 2);
    final selectedRect = Rect.fromLTRB(
      _trackRect.left + _lowerValue * _trackRect.width,
      _trackRect.top,
      _trackRect.right - ((1 - _upperValue) * _trackRect.width),
      _trackRect.bottom,
    );
    _paintTrack(canvas, _trackRect, selectedRect);
    _paintThumbs(canvas, selectedRect);

    final tickRect = _trackRect.bottomLeft & _trackRect.size.copyWith(height: _maxTickLength + _itemSpacing);
    _paintTickMarks(canvas, tickRect);

    _paintLabels(
      canvas,
      tickRect.bottomLeft & tickRect.size.copyWith(height: _labelFontSize + _itemSpacing),
      _labelFontSize,
    );
  }

  void _paintTickMarks(Canvas canvas, Rect rect) {
    final double spacing = rect.width / _divisions;
    for (int i = 0; i <= _divisions; i++) {
      final _offset = rect.centerLeft + Offset(spacing * i, 0);
      final tick = Offset(0, ((i == 0 || i % 5 == 0 || i == _divisions) ? _maxTickLength : _maxTickLength * .65));
      canvas.drawLine(
        _offset,
        _offset + tick,
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2,
      );
    }
  }

  void _drawLabel(Canvas canvas, String text, double fontSize, Offset offset) {
    final textPainter = TextPainter(textAlign: TextAlign.center, textDirection: TextDirection.rtl);
    textPainter
      ..text = TextSpan(
        text: text,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: fontSize),
      )
      ..layout()
      ..paint(canvas, offset + Offset(-(textPainter.width / 2), 0));
  }

  void _paintLabels(Canvas canvas, Rect rect, double fontSize) {
    _drawLabel(canvas, _labelBuilder(_min), fontSize, rect.centerLeft);
    _drawLabel(canvas, _labelBuilder(_max), fontSize, rect.centerRight);
  }

  void _paintTrack(Canvas canvas, Rect rect, Rect selectedRect) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(16.0)),
      Paint()..color = Colors.grey.withOpacity(.35),
    );

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.greenAccent.shade100, Colors.greenAccent.shade700],
    );
    canvas.drawRect(selectedRect, Paint()..shader = gradient.createShader(selectedRect));
  }

  void _paintThumb(Canvas canvas, Rect rect) {
    canvas
      ..drawShadow(Path()..addOval(rect), Colors.black54, 4.0, true)
      ..drawCircle(rect.center, _thumbRadius, Paint()..color = Colors.white)
      ..drawCircle(rect.center, _innerThumbRadius, Paint()..color = Colors.orange.shade700);
  }

  void _paintThumbs(Canvas canvas, Rect selectedRect) {
    _thumbLowerRect = Rect.fromCircle(center: selectedRect.centerLeft, radius: _thumbRadius);
    _paintThumb(canvas, _thumbLowerRect);

    _thumbUpperRect = Rect.fromCircle(center: selectedRect.centerRight, radius: _thumbRadius);
    _paintThumb(canvas, _thumbUpperRect);
  }
}

extension on Size {
  Size copyWith({double width, double height}) {
    return Size(width ?? this.width, height ?? this.height);
  }
}

extension on double {
  double discretize(int divisions) {
    return (this * divisions).round() / divisions;
  }

  double lerp(double min, double max) {
    assert(this >= 0.0);
    assert(this <= 1.0);
    return this * (max - min) + min;
  }

  double unlerp(double min, double max) {
    assert(this <= max);
    assert(this >= min);
    return max > min ? (this - min) / (max - min) : 0.0;
  }
}

enum _ActiveThumb {
  none,
  lowerThumb,
  upperThumb,
}

class Pair<A, B> {
  const Pair(this.a, this.b);

  final A a;
  final B b;
}
