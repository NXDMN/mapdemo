import 'dart:typed_data';

import 'package:flutter/material.dart';

class StreetViewPanoramaInitDemo extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _StreetViewPanoramaInitDemoState();
}

class _StreetViewPanoramaInitDemoState
    extends State<StreetViewPanoramaInitDemo> {
  Uint8List? _bluePoint;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Street View Init Demo'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [],
        ),
      ),
    );
  }
}
