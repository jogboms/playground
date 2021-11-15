import 'package:flutter/material.dart';

import 'projects/activity_rings.dart';
import 'projects/balls_generator.dart';
import 'projects/bed_time.dart';
import 'projects/circular_color_picker.dart';
import 'projects/edge_detection.dart';
import 'projects/gauge_meter.dart';
import 'projects/gradient_range_selector.dart';
import 'projects/graph_with_selector.dart';
import 'projects/graph_with_selector_2.dart';
import 'projects/hour_minute_dial.dart';
import 'projects/measure_slider.dart';
import 'projects/more_balls_generator.dart';
import 'projects/progress_dial.dart';
import 'projects/slide_color_picker.dart';
import 'projects/slide_to_action.dart';
import 'projects/studio_pro.dart';

class Projects extends StatelessWidget {
  static MaterialPageRoute<void> get route => MaterialPageRoute(builder: (_) => Projects());

  final items = [
    MapEntry<String, WidgetBuilder>('Hour/Minute Dial', (_) => HourMinuteDial()),
    MapEntry<String, WidgetBuilder>('Bed Time', (_) => BedTime()),
    MapEntry<String, WidgetBuilder>('Measure Slider', (_) => MeasureSlider()),
    MapEntry<String, WidgetBuilder>('Progress Dial', (_) => ProgressDial()),
    MapEntry<String, WidgetBuilder>('Gauge Meter', (_) => GaugeMeter()),
    MapEntry<String, WidgetBuilder>('Circular Color Picker', (_) => const CircularColorPicker()),
    MapEntry<String, WidgetBuilder>('Studio Pro', (_) => StudioPro()),
    MapEntry<String, WidgetBuilder>('Activity Rings', (_) => ActivityRings()),
    MapEntry<String, WidgetBuilder>('Slide To Action', (_) => SlideToAction()),
    MapEntry<String, WidgetBuilder>('Slide Color Picker', (_) => SlideColorPicker()),
    MapEntry<String, WidgetBuilder>('Gradient Range Selector', (_) => GradientRangeSelector()),
    MapEntry<String, WidgetBuilder>('Graph With Selector', (_) => GraphWithSelector()),
    MapEntry<String, WidgetBuilder>('Graph With Selector II', (_) => GraphWithSelectorII()),
    MapEntry<String, WidgetBuilder>('Heart Of Maths', (_) => HeartOfMaths()),
    MapEntry<String, WidgetBuilder>('Edge Detection', (_) => EdgeDetection()),
    MapEntry<String, WidgetBuilder>('Balls Generator', (_) => BallsGenerator()),
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
            leading: Icon(Icons.widgets_outlined, color: Colors.white),
            minLeadingWidth: 0,
            dense: true,
            title: Text(item.key, style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: item.value));
            },
          );
        },
      ),
    );
  }
}
