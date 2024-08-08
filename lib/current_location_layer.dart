import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:mapdemo/extensions.dart';
import 'package:mapdemo/location_helper.dart';

// Reference: https://github.com/tlserver/flutter_map_location_marker/tree/main

class CurrentLocationLayer extends StatefulWidget {
  const CurrentLocationLayer(
    this.initialCurrentPosition, {
    super.key,
    this.focusCurrentLocation = false,
  });

  final Position initialCurrentPosition;
  final bool focusCurrentLocation;

  @override
  State<CurrentLocationLayer> createState() => _CurrentLocationLayerState();
}

class _CurrentLocationLayerState extends State<CurrentLocationLayer>
    with TickerProviderStateMixin {
  StreamSubscription<CompassEvent>? _headingStreamSubscription;
  AnimationController? _headingAnimationController;
  double? _currentHeading;

  late StreamSubscription<Position> _positionStreamSubscription;
  AnimationController? _positionAnimationController;
  LatLng? _currentLatLng;

  @override
  void initState() {
    super.initState();

    // Get initial value in case of the position is focused (by FlutterMap initialCenter) but no marker render yet
    // because the stream have not emit
    _currentLatLng = LatLng(
      widget.initialCurrentPosition.latitude,
      widget.initialCurrentPosition.longitude,
    );

    subscribePositionStream();
    subscribeHeadingStream();
  }

  void subscribePositionStream() {
    _positionStreamSubscription = LocationHelper.getPositionStream().listen(
      (position) {
        if (!mounted) {
          return;
        }

        final latTween = Tween<double>(
            begin: _currentLatLng!.latitude, end: position.latitude);
        final lngTween = Tween<double>(
            begin: _currentLatLng!.longitude, end: position.longitude);

        _positionAnimationController?.dispose();
        _positionAnimationController = AnimationController(
            duration: const Duration(milliseconds: 500), vsync: this);

        final Animation<double> animation = CurvedAnimation(
            parent: _positionAnimationController!, curve: Curves.fastOutSlowIn);

        _positionAnimationController!.addListener(() {
          setState(() {
            _currentLatLng = LatLng(
              latTween.evaluate(animation),
              lngTween.evaluate(animation),
            );
          });
          if (widget.focusCurrentLocation) {
            MapController.of(context).move(
              _currentLatLng!,
              19,
            );
          }
        });

        animation.addStatusListener((status) {
          if (status == AnimationStatus.completed ||
              status == AnimationStatus.dismissed) {
            _positionAnimationController!.dispose();
            _positionAnimationController = null;
          }
        });

        _positionAnimationController!.forward();
      },
      onError: (error) {
        setState(() {
          _currentLatLng = null;
        });
      },
    );
  }

  void subscribeHeadingStream() {
    _headingStreamSubscription =
        LocationHelper.getHeadingStream()?.listen((event) {
      // Convert to radian (Transform.rotate use radian)
      final heading = event.heading! * (pi / 180.0);

      final headingTween = HeadingRadianTween(
        begin: (_currentHeading ?? heading),
        end: (heading),
      );

      _headingAnimationController?.dispose();
      _headingAnimationController = AnimationController(
          duration: const Duration(milliseconds: 50), vsync: this);
      final Animation<double> animation = CurvedAnimation(
          parent: _headingAnimationController!, curve: Curves.easeInOut);

      _headingAnimationController!.addListener(() {
        setState(() {
          _currentHeading = headingTween.evaluate(animation);
          print("update:$_currentHeading");
        });
      });

      animation.addStatusListener((status) {
        if (status == AnimationStatus.completed ||
            status == AnimationStatus.dismissed) {
          _headingAnimationController!.dispose();
          _headingAnimationController = null;
        }
      });

      _headingAnimationController!.forward();
      //print(_currentHeading);
    }, onError: (error) {
      setState(() {
        _currentHeading = null;
      });
    });
  }

  @override
  void didUpdateWidget(covariant CurrentLocationLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusCurrentLocation != oldWidget.focusCurrentLocation &&
        widget.focusCurrentLocation) {
      print("manually animated move");
      MapController.of(context).animatedMove(
        this,
        _currentLatLng!,
        19,
      );
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription.cancel();
    _headingStreamSubscription?.cancel();
    _positionAnimationController?.dispose();
    _positionAnimationController = null;
    _headingAnimationController?.dispose();
    _headingAnimationController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentLatLng == null) return const SizedBox.shrink();

    //print("build");
    return MarkerLayer(
      rotate: false,
      markers: [
        Marker(
          width: 20,
          height: 20,
          point: _currentLatLng!,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  spreadRadius: 3,
                  blurRadius: 3,
                )
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(3.5),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFF2196F3),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
        if (_currentHeading != null)
          Marker(
            width: 10,
            height: 10,
            point: _currentLatLng!,
            child: Transform.translate(
              offset: const Offset(0.0, -18.0),
              child: Transform.rotate(
                alignment: const Alignment(0, 3.6),
                angle: _currentHeading!,
                child: CustomPaint(
                  painter: ArrowPainter(),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2
      ..color = const Color(0xFF2196F3);

    var path = ui.Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, size.height * 1 / 4)
      ..lineTo(size.width, size.height)
      ..arcToPoint(
        Offset(0, size.height),
        radius: const Radius.circular(20),
        clockwise: false,
      )
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

/// A linear interpolation between a beginning and ending value for radian
/// value. This value turn for both clockwise or anti-clockwise according to the
/// shorter direction.
class HeadingRadianTween extends Tween<double> {
  /// Creates a tween.
  HeadingRadianTween({
    required super.begin,
    required super.end,
  });

  @override
  double lerp(double t) {
    return _circularLerp(begin!, end!, t, 2 * pi);
  }

  double _circularLerp(double begin, double end, double t, double oneCircle) {
    final halfCircle = oneCircle / 2;
    // ignore: parameter_assignments
    begin = begin % oneCircle;
    // ignore: parameter_assignments
    end = end % oneCircle;

    final compareResult = (end - begin).abs().compareTo(halfCircle);
    final crossZero = compareResult == 1 ||
        (compareResult == 0 && begin != end && begin >= halfCircle);
    if (crossZero) {
      double opposite(double value) => (value + halfCircle) % oneCircle;

      return opposite(_doubleLerp(opposite(begin), opposite(end), t));
    } else {
      return _doubleLerp(begin, end, t);
    }
  }

  double _doubleLerp(double begin, double end, double t) =>
      begin + (end - begin) * t;
}
