import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:mapdemo/one_map_nearby_place.dart';

class NearbyPlacesLayer extends StatefulWidget {
  const NearbyPlacesLayer({
    super.key,
    required this.places,
    required this.markerIcon,
  });

  final List<OneMapNearbyPlace> places;
  final Widget markerIcon;

  @override
  State<NearbyPlacesLayer> createState() => _NearbyPlacesLayerState();
}

class _NearbyPlacesLayerState extends State<NearbyPlacesLayer> {
  Map<String, Marker> markers = <String, Marker>{};
  Map<String, bool> showInfoWindows = <String, bool>{};

  @override
  void didUpdateWidget(covariant NearbyPlacesLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.places != oldWidget.places) {
      showInfoWindows.clear();
      for (var place in widget.places) {
        showInfoWindows["${place.name}_${place.latlng}"] = false;
      }
    }
  }

  void _onMarkerTapped(String id, {bool infoWindow = false}) {
    final Marker? tappedMarker = markers[id];
    if (tappedMarker != null) {
      if (infoWindow) {
        setState(() {
          showInfoWindows[id] = !showInfoWindows[id]!;
        });
      } else {
        showModalBottomSheet(
          context: context,
          isDismissible: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          builder: (_) => DraggableScrollableSheet(
            expand: false,
            builder: (BuildContext context, scrollController) =>
                SingleChildScrollView(
              controller: scrollController,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Column(
                  children: [
                    Text(id),
                    Text("Latitue:${tappedMarker.point.latitude}"),
                    Text("Longitude:${tappedMarker.point.longitude}"),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.places.isEmpty) return const SizedBox.shrink();

    return MarkerLayer(
      rotate: true,
      markers: widget.places.map<Marker>((place) {
        final String markerId = "${place.name}_${place.latlng}";
        Marker marker = Marker(
          point: place.latlng!,
          width: 300,
          height: 100,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              if (showInfoWindows[markerId]!)
                Transform.translate(
                  offset: const Offset(0, -60),
                  child: InfoWindow(
                    title: place.name,
                    text:
                        "${place.addressBlockHouseNumber}, ${place.addressStreetName}, ${(place.addressFloorNumber != null && place.addressUnitNumber != null) ? "#${place.addressFloorNumber}-${place.addressUnitNumber}, " : ""}Singapore ${place.addressPostalCode}",
                  ),
                ),
              InkWell(
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: widget.markerIcon,
                ),
                onTap: () {
                  _onMarkerTapped(markerId, infoWindow: true);
                },
              ),
            ],
          ),
        );
        markers[markerId] = marker;

        return marker;
      }).toList(),
    );
  }
}

class InfoWindow extends StatelessWidget {
  final String? title;
  final String? text;

  const InfoWindow({
    super.key,
    this.title,
    this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: ShapeDecoration(
        shape: InfoWindowBorder(),
        color: Colors.white,
        shadows: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 3.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title ?? '', softWrap: true),
          Text(text ?? '', softWrap: true),
        ],
      ),
    );
  }
}

class InfoWindowBorder extends ShapeBorder {
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  ui.Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return ui.Path()
      ..addRect(rect)
      ..moveTo(rect.bottomCenter.dx - 10, rect.bottomCenter.dy)
      ..relativeLineTo(10, 10)
      ..relativeLineTo(10, -10)
      ..close();
  }

  @override
  ui.Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return getInnerPath(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}
