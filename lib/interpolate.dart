import 'dart:math' as math;

// https://stackoverflow.com/a/55088673/8236404
double Function(double input) interpolate({
  double? inputMin = 0,
  double? inputMax = 1,
  double? outputMin = 0,
  double? outputMax = 1,
}) {
  // null check
  if (inputMin == null || inputMax == null || outputMin == null || outputMax == null) {
    throw Exception("You can't have nulls as parameters");
  }

  //range check
  if (inputMin == inputMax) {
    print('Warning: Zero input range');
    return (x) => inputMax;
  }

  if (outputMin == outputMax) {
    print('Warning: Zero output range');
    return (x) => outputMax;
  }

  //check reversed input range
  var reverseInput = false;
  final oldMin = math.min(inputMin, inputMax);
  final oldMax = math.max(inputMin, inputMax);
  if (oldMin != inputMin) {
    reverseInput = true;
  }

  //check reversed output range
  var reverseOutput = false;
  final newMin = math.min(outputMin, outputMax);
  final newMax = math.max(outputMin, outputMax);
  if (newMin != outputMin) {
    reverseOutput = true;
  }

  // Hot-rod the most common case.
  if (!reverseInput && !reverseOutput) {
    final dNew = newMax - newMin;
    final dOld = oldMax - oldMin;
    return (x) {
      return ((x - oldMin) * dNew / dOld) + newMin;
    };
  }

  return (x) {
    double portion;
    if (reverseInput) {
      portion = (oldMax - x) * (newMax - newMin) / (oldMax - oldMin);
    } else {
      portion = (x - oldMin) * (newMax - newMin) / (oldMax - oldMin);
    }
    double result;
    if (reverseOutput) {
      result = newMax - portion;
    } else {
      result = portion + newMin;
    }

    return result;
  };
}
