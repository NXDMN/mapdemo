import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

extension LatLngExtension on LatLng {
  // check if user-typed latlng is within Singapore bounds
  bool checkWithinBounds(LatLngBounds bounds) {
    return (latitude <= bounds.north &&
        latitude >= bounds.south &&
        longitude <= bounds.east &&
        longitude >= bounds.west);
  }
}

extension StringExtension on String? {
  LatLng? toLatLng() {
    if (this != null && this!.isNotEmpty) {
      final l = this!.split(',');
      if (l.length == 2) {
        final lat = double.tryParse(l[0]);
        final lng = double.tryParse(l[1]);

        if (lat != null && lng != null) return LatLng(lat, lng);
      }
    }

    return null;
  }
}

// https://github.com/fleaflet/flutter_map/blob/master/example/lib/pages/animated_map_controller.dart
extension MapControllerExtension on MapController {
  static const _startedId = 'AnimatedMapController#MoveStarted';
  static const _inProgressId = 'AnimatedMapController#MoveInProgress';
  static const _finishedId = 'AnimatedMapController#MoveFinished';

  void animatedMove(
      TickerProvider vsync, LatLng destLocation, double destZoom) {
    // Create some tweens. These serve to split up the transition from one location to another.
    // In our case, we want to split the transition be<tween> our current map center and the destination.
    final camera = this.camera;
    final latTween = Tween<double>(
        begin: camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(
        begin: camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: camera.zoom, end: destZoom);

    // Create a animation controller that has a duration and a TickerProvider.
    final controller = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: vsync);
    // The animation determines what path the animation will take. You can try different Curves values, although I found
    // fastOutSlowIn to be my favorite.
    final Animation<double> animation =
        CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    // Note this method of encoding the target destination is a workaround.
    // When proper animated movement is supported (see #1263) we should be able
    // to detect an appropriate animated movement event which contains the
    // target zoom/center.
    final startIdWithTarget =
        '$_startedId#${destLocation.latitude},${destLocation.longitude},$destZoom';
    bool hasTriggeredMove = false;

    controller.addListener(() {
      final String id;
      if (animation.value == 1.0) {
        id = _finishedId;
      } else if (!hasTriggeredMove) {
        id = startIdWithTarget;
      } else {
        id = _inProgressId;
      }

      hasTriggeredMove |= move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
        id: id,
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      } else if (status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  /// Causes tiles to be prefetched at the target location and disables pruning
  /// whilst animating movement. When proper animated movement is added (see
  /// #1263) we should just detect the appropriate AnimatedMove events and
  /// use their target zoom/center.
  static final animatedMoveTileUpdateTransformer =
      TileUpdateTransformer.fromHandlers(handleData: (updateEvent, sink) {
    final mapEvent = updateEvent.mapEvent;

    final id = mapEvent is MapEventMove ? mapEvent.id : null;
    if (id?.startsWith(_startedId) ?? false) {
      final parts = id!.split('#')[2].split(',');
      final lat = double.parse(parts[0]);
      final lon = double.parse(parts[1]);
      final zoom = double.parse(parts[2]);

      // When animated movement starts load tiles at the target location and do
      // not prune. Disabling pruning means existing tiles will remain visible
      // whilst animating.
      sink.add(
        updateEvent.loadOnly(
          loadCenterOverride: LatLng(lat, lon),
          loadZoomOverride: zoom,
        ),
      );
    } else if (id == _inProgressId) {
      // Do not prune or load whilst animating so that any existing tiles remain
      // visible. A smarter implementation may start pruning once we are close to
      // the target zoom/location.
    } else if (id == _finishedId) {
      // We already prefetched the tiles when animation started so just prune.
      sink.add(updateEvent.pruneOnly());
    } else {
      sink.add(updateEvent);
    }
  });
}
