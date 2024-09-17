import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapdemo/nearby_places_layer.dart';
import 'package:mapdemo/one_map_nearby_place.dart';

final testNearbyPlaces = <OneMapNearbyPlace>[
  OneMapNearbyPlace(
    name: "Place A",
    description: "This is Place A",
    addressBlockHouseNumber: "277",
    addressStreetName: "Street A",
    addressPostalCode: "123456",
    latlng: const LatLng(1.30040819039694, 103.839669047112),
    iconName: "A",
  ),
  OneMapNearbyPlace(
    name: "Place B",
    description: "This is Place B",
    addressBlockHouseNumber: "166",
    addressStreetName: "Street B",
    addressPostalCode: "234567",
    latlng: const LatLng(1.29742018061931, 103.854234798536),
    iconName: "B",
  ),
  OneMapNearbyPlace(
    name: "Place C",
    description: "This is Place C",
    addressBlockHouseNumber: "635",
    addressStreetName: "Street C",
    addressPostalCode: "987654",
    latlng: const LatLng(1.29871263170447, 103.805520397172),
    iconName: "C",
  )
];

final mapOptions = MapOptions(
  minZoom: 11,
  maxZoom: 19,
  initialZoom: 11,
  initialCenter: const LatLng(1.354378, 103.833669),
  cameraConstraint: CameraConstraint.contain(
    bounds: LatLngBounds(
        const LatLng(1.144, 103.585), const LatLng(1.494, 104.122)),
  ),
  keepAlive: true,
);

/*
places:
  if not empty, markers render the places
  else, nothing render
markerIcon:
  cannot be null, this widget is the marker rendered
onMarkerTapped:
  should toggle InfoWindow/ModalBottomSheet to display info
*/
void main() {
  group('NearbyPlacesLayer', () {
    testWidgets('places not empty and markerIcon rendered', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterMap(
              options: mapOptions,
              children: [
                NearbyPlacesLayer(
                  places: testNearbyPlaces,
                  markerIcon: const Text("Marker"),
                ),
              ],
            ),
          ),
        ),
      );

      var marker = find.text("Marker");

      expect(marker, findsExactly(3));
    });

    testWidgets('places empty nothing rendered', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterMap(
              options: mapOptions,
              children: const [
                NearbyPlacesLayer(
                  places: [],
                  markerIcon: Text("Marker"),
                ),
              ],
            ),
          ),
        ),
      );

      var marker = find.text("Marker");

      expect(marker, findsNothing);
    });

    testWidgets('onMarkerTapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterMap(
              options: mapOptions,
              children: [
                NearbyPlacesLayer(
                  places: testNearbyPlaces,
                  markerIcon: const Text("Marker"),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text("Marker").first);

      await tester.pump();

      expect(find.byType(InfoWindow), findsOne);
    });
  });
}
