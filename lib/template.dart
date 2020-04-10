import 'dart:math' as math;

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

class Playground extends StatefulWidget {
  @override
  _PlaygroundState createState() => _PlaygroundState();
}

class _PlaygroundState extends State<Playground> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

extension on num {
  double get radians => (this * math.pi) / 180.0;
}

// https://math.stackexchange.com/questions/377169/going-from-a-value-inside-1-1-to-a-value-in-another-range/377174#377174
double interpolate({
  double input,
  double inputMin = 0,
  double inputMax = 1,
  double outputMin = 0,
  double outputMax = 1,
  Curve curve = Curves.decelerate,
}) {
  double result = input;

  if (outputMin == outputMax) {
    return outputMin;
  }

  if (inputMin == inputMax) {
    if (input <= inputMin) {
      return outputMin;
    }
    return outputMax;
  }

  // Input Range
  if (inputMin == -double.infinity) {
    result = -result;
  } else if (inputMax == double.infinity) {
    result = result - inputMin;
  } else {
    result = (result - inputMin) / (inputMax - inputMin);
  }

  // Easing
  result = curve.transform(result);

  // Output Range
  if (outputMin == -double.infinity) {
    result = -result;
  } else if (outputMax == double.infinity) {
    result = result + outputMin;
  } else {
    result = result * (outputMax - outputMin) + outputMin;
  }

  return result;
}
