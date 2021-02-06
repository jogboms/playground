import 'package:flutter/material.dart';

import 'projects/balls_generator.dart';
import 'projects/bed_time.dart';
import 'projects/edge_detection.dart';
import 'projects/gradient_range_selector.dart';
import 'projects/hour_minute_dial.dart';
import 'projects/more_balls_generator.dart';
import 'projects/progress_dial.dart';
import 'projects/slide_to_action.dart';

class Projects extends StatelessWidget {
  static get route => MaterialPageRoute(builder: (_) => Projects());

  final items = [
    MapEntry("Hour/Minute Dial", (_) => HourMinuteDial()),
    MapEntry("Bed Time", (_) => BedTime()),
    MapEntry("Progress Dial", (_) => ProgressDial()),
    MapEntry("Slide To Action", (_) => SlideToAction()),
    MapEntry("Gradient Range Selector", (_) => GradientRangeSelector()),
    MapEntry("Heart Of Maths", (_) => HeartOfMaths()),
    MapEntry("Edge Detection", (_) => EdgeDetection()),
    MapEntry("Balls Generator", (_) => BallsGenerator()),
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
              Navigator.of(context).push(MaterialPageRoute(builder: item.value));
            },
          );
        },
      ),
    );
  }
}
