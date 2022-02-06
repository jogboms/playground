import 'package:flutter/material.dart';

import 'projects/activity_rings.dart';
import 'projects/balls_generator.dart';
import 'projects/bed_time.dart';
import 'projects/circular_color_picker.dart';
import 'projects/circular_color_slider_picker.dart';
import 'projects/edge_detection.dart';
import 'projects/gauge_meter.dart';
import 'projects/gradient_range_selector.dart';
import 'projects/graph_with_selector.dart';
import 'projects/graph_with_selector_2.dart';
import 'projects/hour_minute_dial.dart';
import 'projects/light_gradient_selector.dart';
import 'projects/measure_slider.dart';
import 'projects/more_balls_generator.dart';
import 'projects/progress_dial.dart';
import 'projects/slide_color_picker.dart';
import 'projects/slide_to_action.dart';
import 'projects/studio_pro.dart';

class Projects extends StatelessWidget {
  Projects({Key? key}) : super(key: key);

  static MaterialPageRoute<void> get route => MaterialPageRoute(builder: (_) => Projects());

  final items = [
    MapEntry<String, WidgetBuilder>('Hour/Minute Dial', (_) => const HourMinuteDial()),
    MapEntry<String, WidgetBuilder>('Bed Time', (_) => const BedTime()),
    MapEntry<String, WidgetBuilder>('Measure Slider', (_) => const MeasureSlider()),
    MapEntry<String, WidgetBuilder>('Progress Dial', (_) => const ProgressDial()),
    MapEntry<String, WidgetBuilder>('Gauge Meter', (_) => const GaugeMeter()),
    MapEntry<String, WidgetBuilder>('Circular Color Picker', (_) => const CircularColorPicker()),
    MapEntry<String, WidgetBuilder>('Circular Color Slider Picker', (_) => const CircularColorSliderPicker()),
    MapEntry<String, WidgetBuilder>('Studio Pro', (_) => const StudioPro()),
    MapEntry<String, WidgetBuilder>('Activity Rings', (_) => const ActivityRings()),
    MapEntry<String, WidgetBuilder>('Slide To Action', (_) => const SlideToAction()),
    MapEntry<String, WidgetBuilder>('Slide Color Picker', (_) => const SlideColorPicker()),
    MapEntry<String, WidgetBuilder>('Light Gradient Selector', (_) => const LightGradientSelector()),
    MapEntry<String, WidgetBuilder>('Gradient Range Selector', (_) => const GradientRangeSelector()),
    MapEntry<String, WidgetBuilder>('Graph With Selector', (_) => const GraphWithSelector()),
    MapEntry<String, WidgetBuilder>('Graph With Selector II', (_) => const GraphWithSelectorII()),
    MapEntry<String, WidgetBuilder>('Heart Of Maths', (_) => const HeartOfMaths()),
    MapEntry<String, WidgetBuilder>('Edge Detection', (_) => const EdgeDetection()),
    MapEntry<String, WidgetBuilder>('Balls Generator', (_) => const BallsGenerator()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (_, index) {
          final item = items[index];
          return ListTile(
            leading: const Icon(Icons.widgets_outlined, color: Colors.white),
            minLeadingWidth: 0,
            dense: true,
            title: Text(item.key, style: const TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: item.value));
            },
          );
        },
      ),
    );
  }
}
