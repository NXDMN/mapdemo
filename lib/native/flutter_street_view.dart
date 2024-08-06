import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapdemo/native/street_view_events.dart';
import 'package:mapdemo/native/street_view_types.dart';

class FlutterStreetView extends StatefulWidget {
  const FlutterStreetView(
    this.initPosition, {
    super.key,
    this.onCameraChange,
    this.onPanoramaChange,
    this.onPanoramaClick,
    this.onPanoramaLongClick,
  });

  final LatLng initPosition;
  final void Function(StreetViewPanoramaCamera)? onCameraChange;
  final void Function(StreetViewPanoramaLocation?, Exception?)?
      onPanoramaChange;
  final void Function(StreetViewPanoramaOrientation, Point)? onPanoramaClick;
  final void Function(StreetViewPanoramaOrientation, Point)?
      onPanoramaLongClick;

  @override
  State<FlutterStreetView> createState() => _FlutterStreetViewState();
}

class _FlutterStreetViewState extends State<FlutterStreetView> {
  @override
  Widget build(BuildContext context) {
    // This is used in the platform side to register the view.
    const String viewType = 'flutter-street-view';
    // Pass parameters to the platform side.
    Map<String, dynamic> creationParams = <String, dynamic>{
      'initPosition': <double>[
        widget.initPosition.latitude,
        widget.initPosition.longitude
      ],
    };

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return PlatformViewLink(
          surfaceFactory: (context, controller) => AndroidViewSurface(
            controller: controller as AndroidViewController,
            gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
            hitTestBehavior: PlatformViewHitTestBehavior.opaque,
          ),
          onCreatePlatformView: (params) =>
              PlatformViewsService.initSurfaceAndroidView(
            id: params.id,
            viewType: viewType,
            layoutDirection: TextDirection.ltr,
            creationParams: creationParams,
            creationParamsCodec: const StandardMessageCodec(),
            onFocus: () {
              params.onFocusChanged(true);
            },
          )
                ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
                ..addOnPlatformViewCreatedListener(onPlatformViewCreated)
                ..create(),
          viewType: viewType,
        );
      case TargetPlatform.iOS:
        return UiKitView(
          viewType: viewType,
          onPlatformViewCreated: onPlatformViewCreated,
          creationParams: creationParams,
          creationParamsCodec: const StandardMessageCodec(),
        );
      default:
        return Text('$defaultTargetPlatform is not yet supported.');
    }
  }

  @override
  void dispose() {
    _disconnectStreams();
    _streetViewEventStreamController.close();
    super.dispose();
  }

  MethodChannel? channel;

  final StreamController<StreetViewEvent> _streetViewEventStreamController =
      StreamController<StreetViewEvent>.broadcast();

  StreamSubscription? _onCameraChange;
  StreamSubscription? _onPanoramaChange;
  StreamSubscription? _onPanoramaClick;
  StreamSubscription? _onPanoramaLongClick;

  void onPlatformViewCreated(int viewId) {
    channel = MethodChannel('flutter_street_view_$viewId');
    channel?.setMethodCallHandler(
        (MethodCall call) => _handleMethodCall(call, viewId));
    _connectStreams(viewId);
  }

  Future<dynamic> _handleMethodCall(MethodCall call, int viewId) async {
    switch (call.method) {
      case "camera#onChange":
        final args = StreetViewPanoramaCamera.fromMap(call.arguments);
        _streetViewEventStreamController.add(CameraChangeEvent(viewId, args));
        break;
      case "panorama#onChange":
        String? errorMsg =
            call.arguments['error'] is String ? call.arguments['error'] : null;
        Exception? e = errorMsg != null ? Exception(errorMsg) : null;
        final data = PanoramaChangeData(
            e == null
                ? StreetViewPanoramaLocation.fromMap(call.arguments)
                : null,
            e);
        _streetViewEventStreamController.add(PanoramaChangeEvent(viewId, data));
        break;
      case "panorama#onClick":
        final map = call.arguments;
        final orientation = StreetViewPanoramaOrientation.fromMap(map);
        final point = Point(map['x'] as int, map['y'] as int);
        final data = PanoramaClickData(orientation, point);
        _streetViewEventStreamController.add(PanoramaClickEvent(viewId, data));
        break;
      case "panorama#onLongClick":
        final map = call.arguments;
        final orientation =
            StreetViewPanoramaOrientation.fromMap(call.arguments);
        final point = Point(map['x'] as int, map['y'] as int);
        final data = PanoramaClickData(orientation, point);
        _streetViewEventStreamController
            .add(PanoramaLongClickEvent(viewId, data));
        break;
      default:
        throw UnimplementedError(
            "The method '${call.method}' not implemented.");
    }
  }

  /// The Camera was changed.
  Stream<CameraChangeEvent> onCameraChangeStream(int viewId) {
    return _streetViewEventStreamController.stream
        .where((event) => event.viewId == viewId)
        .where((data) => data is CameraChangeEvent)
        .cast<CameraChangeEvent>();
  }

  /// The Panorama was changed.
  Stream<PanoramaChangeEvent> onPanoramaChangeStream(int viewId) {
    return _streetViewEventStreamController.stream
        .where((event) => event.viewId == viewId)
        .where((data) => data is PanoramaChangeEvent)
        .cast<PanoramaChangeEvent>();
  }

  /// The Panorama was clicked.
  Stream<PanoramaClickEvent> onPanoramaClickStream(int viewId) {
    return _streetViewEventStreamController.stream
        .where((event) => event.viewId == viewId)
        .where((data) => data is PanoramaClickEvent)
        .cast<PanoramaClickEvent>();
  }

  /// The Panorama was long clicked.
  Stream<PanoramaLongClickEvent> onPanoramaLongClickStream(int viewId) {
    return _streetViewEventStreamController.stream
        .where((event) => event.viewId == viewId)
        .where((data) => data is PanoramaLongClickEvent)
        .cast<PanoramaLongClickEvent>();
  }

  void _connectStreams(int viewId) {
    if (widget.onCameraChange != null) {
      _onCameraChange = onCameraChangeStream(viewId)
          .listen((e) => widget.onCameraChange!(e.value));
    }

    if (widget.onPanoramaChange != null) {
      _onPanoramaChange = onPanoramaChangeStream(viewId).listen(
          (e) => widget.onPanoramaChange!(e.value.location, e.value.exception));
    }

    if (widget.onPanoramaClick != null) {
      _onPanoramaClick = onPanoramaClickStream(viewId).listen(
          (e) => widget.onPanoramaClick!(e.value.orientation, e.value.point));
    }

    if (widget.onPanoramaLongClick != null) {
      _onPanoramaLongClick = onPanoramaLongClickStream(viewId).listen((e) =>
          widget.onPanoramaLongClick!(e.value.orientation, e.value.point));
    }
  }

  void _disconnectStreams() {
    _onCameraChange?.cancel();
    _onPanoramaChange?.cancel();
    _onPanoramaClick?.cancel();
    _onPanoramaLongClick?.cancel();
  }
}
