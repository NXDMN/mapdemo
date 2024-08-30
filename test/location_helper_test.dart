import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapdemo/location_helper.dart';

final testPosition = Position(
  longitude: 100.0,
  latitude: 100.0,
  timestamp: DateTime.now(),
  accuracy: 50.6,
  altitude: 20.0,
  altitudeAccuracy: 1.0,
  heading: 120,
  headingAccuracy: 1.0,
  speed: 150.9,
  speedAccuracy: 10.0,
);

void main() {
  group('LocationHelper Test', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    const MethodChannel geolocatorChannel =
        MethodChannel('flutter.baseflow.com/geolocator');
    const EventChannel geolocatorUpdatesChannel =
        EventChannel('flutter.baseflow.com/geolocator_updates');
    const EventChannel compassChannel =
        EventChannel('hemanthraj/flutter_compass');

    Future locationHandler(MethodCall methodCall) async {
      // whenever `getCurrentPosition` method is called we want to return a testPosition
      if (methodCall.method == 'getCurrentPosition') {
        return testPosition.toJson();
      }
      // this is the check that's supposed to happend
      // on the Device before you try to get user's location
      if (methodCall.method == 'isLocationServiceEnabled') {
        return true;
      }
      // Here's another check that's happens on the user's device, we defaulted
      // it to authorized
      // case 0:
      //   return LocationPermission.denied;
      // case 1:
      //   return LocationPermission.deniedForever;
      // case 2:
      //   return LocationPermission.whileInUse;
      // case 3:
      //   return LocationPermission.always;
      // default:
      //   throw InvalidPermissionException(this);
      if (methodCall.method == 'checkPermission') {
        return 3;
      }
    }

    setUpAll(() {
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

    test('checkPermission', () async {
      final res = await LocationHelper.checkPermission();
      expect(res, true);
    });

    test('getCurrentPosition', () async {
      final res = await LocationHelper.getCurrentPosition();
      expect(res, isA<Position>());
    });

    test('getPositionStream', () {
      final res = LocationHelper.getPositionStream();
      expect(res, emitsInOrder([isA<Position>(), emitsDone]));
    });

    test('getHeadingStream', () {
      final res = LocationHelper.getHeadingStream();
      expect(res, emitsInOrder([isA<CompassEvent>(), emitsDone]));
    });
  });
}
