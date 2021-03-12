import 'package:flutter/material.dart';

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
      body: Container(
        child: Center(
          child: Text('Shake device to see projects'),
        ),
      ),
    );
  }
}
