import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapdemo/current_location_layer.dart';
import 'package:mapdemo/nearby_places_layer.dart';

/*
Map:
  Make sure map within Singapore bounds
  Gesture: Pinch to zoom, double tap to zoom in, onTap works
  MapController move map smoothly (with animation)
Attribute:
  Must show OneMap logo and attribution
focusCurrentLocation:
  if true, MapController camera will focus on current location,
  else, MapController camera not focus
  When map is moved, focusCurrentLocation is false
tappedLatLng:
  if not null, Marker render at tappedLatLng,
  else, nothing render
*/
// Since test not allow for HttpClient, here we create a map without tiles
void main() {
  group('UIMap', () {
    testWidgets('map bounds', (tester) async {
      final MapController mapController = MapController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    minZoom: 11,
                    maxZoom: 19,
                    initialZoom: 12,
                    initialCenter: const LatLng(1.354378, 103.833669),
                    onTap: onTap,
                    onMapEvent: (event) {
                      if (event is MapEventMoveStart) {
                        setState(() {
                          focusCurrentLocation = false;
                        });
                      }
                    },
                    cameraConstraint: CameraConstraint.contain(
                      bounds: LatLngBounds(
                        const LatLng(1.144, 103.585), //southwest
                        const LatLng(1.494, 104.122), //northeast
                      ),
                    ),
                    keepAlive: true,
                  ),
                  children: [
                    // Marker plot on LatLng tapped
                    if (tappedLatLng != null)
                      MarkerLayer(
                        rotate: true,
                        markers: [
                          Marker(
                            point: tappedLatLng!,
                            width: 50,
                            height: 50,
                            child: const Icon(
                              Icons.location_pin,
                              size: 50,
                              color: Colors.red,
                            ),
                          )
                        ],
                      ),

                    // Current position marker
                    CurrentLocationLayer(
                        focusCurrentLocation: focusCurrentLocation),

                    // NearbyPlaces Marker
                    NearbyPlacesLayer(
                      places: nearbyPlaces,
                      markerIcon: nearbyMarkerIcon ?? const SizedBox.shrink(),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
    });
  });
}
