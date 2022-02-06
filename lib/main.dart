import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shake/shake.dart';

import 'playground.dart';
import 'projects.dart';

void main() => runApp(
      MaterialApp(
        theme: ThemeData.dark(),
        debugShowCheckedModeBanner: false,
        home: const App(),
      ),
    );

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  bool isViewingProject = false;

  @override
  void initState() {
    if (Platform.isAndroid || Platform.isIOS) {
      ShakeDetector.autoStart(
        onPhoneShake: () {
          if (!isViewingProject) {
            isViewingProject = true;
            Navigator.of(context).push(Projects.route).whenComplete(() => isViewingProject = false);
          }
        },
      );
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const Playground();
  }
}
