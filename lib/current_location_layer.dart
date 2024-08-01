import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:mapdemo/extensions.dart';
import 'package:mapdemo/location_helper.dart';

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
  late AnimationController _headingAnimationcontroller;

  double? _currentHeading;
  late StreamSubscription<Position> _positionStreamSubscription;
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

    _headingAnimationcontroller = AnimationController(
        duration: const Duration(milliseconds: 100), vsync: this);

    _headingAnimationcontroller.forward();
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
        final controller = AnimationController(
            duration: const Duration(milliseconds: 500), vsync: this);
        final Animation<double> animation =
            CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

        controller.addListener(() {
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
          if (status == AnimationStatus.completed) {
            print("marker move end");
            controller.dispose();
          } else if (status == AnimationStatus.dismissed) {
            controller.dispose();
          } else if (status == AnimationStatus.forward) {
            print("marker move start");
          }
        });

        controller.forward();

        // print(_currentLatLng);
      },
      onError: (error) {
        setState(() {
          _currentLatLng = null;
        });
      },
    );
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
    _headingAnimationcontroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentLatLng == null) return const SizedBox.shrink();

    print("build");
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
        Marker(
          width: 10,
          height: 10,
          point: _currentLatLng!,
          child: StreamBuilder<CompassEvent>(
            stream: LocationHelper.getHeadingStream(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final tweenTurns = Tween<double>(
                  begin: (_currentHeading ?? 0) / 360,
                  end: (snapshot.data!.heading!) / 360,
                );

                _currentHeading = snapshot.data!.heading;
                //print(_currentHeading);

                // Note: For location marker of size 20x20 and heading marker of size 10x10,
                // the ratio of rotation alignment to translate offset is approximately 1:5
                return Transform.translate(
                  offset: const Offset(0.0, -18.0),
                  child: RotationTransition(
                    alignment: const Alignment(0, 3.6),
                    turns: tweenTurns.animate(_headingAnimationcontroller),
                    child: CustomPaint(
                      painter: ArrowPainter(),
                    ),
                  ),
                );
              }

              return const SizedBox.shrink();
            },
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
