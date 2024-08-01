import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapdemo/native/flutter_street_view.dart';

class StreetViewPage extends StatefulWidget {
  const StreetViewPage(this.initPosition, {super.key});

  final LatLng initPosition;

  @override
  State<StreetViewPage> createState() => _StreetViewPageState();
}

class _StreetViewPageState extends State<StreetViewPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Flutter Street View'),
      ),
      body: FlutterStreetView(
        widget.initPosition,
        onCameraChange: (camera) {
          print('CameraChange:$camera');
        },
        onPanoramaChange: (location, exception) {
          print('PanoramaChange:$location');
        },
        onPanoramaClick: (orientation, point) {
          print('PanoramaClick:$orientation');
        },
        onPanoramaLongClick: (orientation, point) {
          print('PanoramaLongClick:$orientation');
        },
      ),
    );
  }
}
