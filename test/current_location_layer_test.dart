import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapdemo/current_location_layer.dart';

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
final testPosition = Position(
  longitude: 103.800,
  latitude: 1.222,
  timestamp: DateTime.now(),
  accuracy: 50.6,
  altitude: 20.0,
  altitudeAccuracy: 1.0,
  heading: 120,
  headingAccuracy: 1.0,
  speed: 150.9,
  speedAccuracy: 10.0,
);
/*
Location permission:
  if granted, start subscribe to position stream and heading stream
  else, nothing render
Position stream:
  if emit value, marker will render at the position
  else, nothing render,
Heading stream:
  if emit value, heading arrow will render around the current location marker
  else, no heading arrow render (current location marker not affected)
focusCurrentLocation:
  if true, MapController camera will focus on current location,
  else, MapController camera not focus
Animation?
  MapController camera move smoothly when current location changes
  heading arrow rotate smoothly when heading changes
*/
void main() {
  group("CurrentLocationLayer normal", () {
    TestWidgetsFlutterBinding.ensureInitialized();

    const MethodChannel geolocatorChannel =
        MethodChannel('flutter.baseflow.com/geolocator');
    const EventChannel geolocatorUpdatesChannel =
        EventChannel('flutter.baseflow.com/geolocator_updates');
    const EventChannel compassChannel =
        EventChannel('hemanthraj/flutter_compass');

    Future locationHandler(MethodCall methodCall) async {
      if (methodCall.method == 'getCurrentPosition') {
        return testPosition.toJson();
      }

      if (methodCall.method == 'isLocationServiceEnabled') {
        return true;
      }

      if (methodCall.method == 'checkPermission') {
        return 3;
      }
    }

    //https://github.com/flutter/flutter/issues/113506
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        ..setMockMethodCallHandler(geolocatorChannel, locationHandler)
        ..setMockStreamHandler(geolocatorUpdatesChannel,
            MockStreamHandler.inline(onListen: (args, events) {
          events.success(testPosition.toJson());
          events.endOfStream();
        }))
        ..setMockStreamHandler(compassChannel,
            MockStreamHandler.inline(onListen: (args, events) {
          events.success([180.0, 1.0, 1.0]);
          events.endOfStream();
        }));
    });

    testWidgets('focusCurrentLocation true', (tester) async {
      await tester.runAsync(() async {
        final MapController mapController = MapController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FlutterMap(
                mapController: mapController,
                options: mapOptions,
                children: const [
                  CurrentLocationLayer(focusCurrentLocation: true),
                ],
              ),
            ),
          ),
        );
        // For stream subscribe
        await Future.delayed(const Duration(seconds: 5));

        await tester.pumpAndSettle();

        expect(mapController.camera.center,
            LatLng(testPosition.latitude, testPosition.longitude));
      });
    });

    testWidgets('focusCurrentLocation false', (tester) async {
      await tester.runAsync(() async {
        final MapController mapController = MapController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FlutterMap(
                mapController: mapController,
                options: mapOptions,
                children: const [
                  CurrentLocationLayer(focusCurrentLocation: false),
                ],
              ),
            ),
          ),
        );
        // For stream subscribe
        await Future.delayed(const Duration(seconds: 5));

        await tester.pumpAndSettle();

        expect(mapController.camera.center, const LatLng(1.354378, 103.833669));
      });
    });
  });

  group("CurrentLocationLayer without location and heading", () {
    TestWidgetsFlutterBinding.ensureInitialized();

    const MethodChannel geolocatorChannel =
        MethodChannel('flutter.baseflow.com/geolocator');
    const EventChannel geolocatorUpdatesChannel =
        EventChannel('flutter.baseflow.com/geolocator_updates');
    const EventChannel compassChannel =
        EventChannel('hemanthraj/flutter_compass');

    Future locationHandler(MethodCall methodCall) async {
      if (methodCall.method == 'getCurrentPosition') {
        return testPosition.toJson();
      }

      if (methodCall.method == 'isLocationServiceEnabled') {
        return true;
      }

      if (methodCall.method == 'checkPermission') {
        return 1;
      }
    }

    //https://github.com/flutter/flutter/issues/113506
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        ..setMockMethodCallHandler(geolocatorChannel, locationHandler)
        ..setMockStreamHandler(geolocatorUpdatesChannel,
            MockStreamHandler.inline(onListen: (args, events) {
          events.success(testPosition.toJson());
          events.endOfStream();
        }))
        ..setMockStreamHandler(compassChannel,
            MockStreamHandler.inline(onListen: (args, events) {
          events.endOfStream();
        }));
    });

    testWidgets('no current location', (tester) async {
      await tester.runAsync(() async {
        final MapController mapController = MapController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FlutterMap(
                mapController: mapController,
                options: mapOptions,
                children: const [
                  CurrentLocationLayer(focusCurrentLocation: true),
                ],
              ),
            ),
          ),
        );
        // For stream subscribe
        await Future.delayed(const Duration(seconds: 5));

        await tester.pumpAndSettle();

        expect(find.byKey(const Key("CurrentLocationMarker")), findsNothing);
      });
    });

    testWidgets('no heading', (tester) async {
      await tester.runAsync(() async {
        final MapController mapController = MapController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FlutterMap(
                mapController: mapController,
                options: mapOptions,
                children: const [
                  CurrentLocationLayer(focusCurrentLocation: false),
                ],
              ),
            ),
          ),
        );
        // For stream subscribe
        await Future.delayed(const Duration(seconds: 5));

        await tester.pumpAndSettle();

        expect(find.byKey(const Key("HeadingMarker")), findsNothing);
      });
    });
  });
}
