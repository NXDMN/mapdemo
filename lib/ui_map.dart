import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapdemo/current_location_layer.dart';
import 'package:mapdemo/extensions.dart';
import 'package:mapdemo/nearby_places_enum.dart';
import 'package:mapdemo/nearby_places_layer.dart';
import 'package:mapdemo/one_map_nearby_place.dart';
import 'package:url_launcher/url_launcher.dart';

class UIMap extends StatefulWidget {
  const UIMap({
    super.key,
    this.mapController,
    this.focusCurrentLocation = true,
    this.tappedLatLng,
    this.onTap,
    this.selectedNearbyPlaces,
    this.nearbyPlaces = const [],
  });

  final MapController? mapController;
  final bool focusCurrentLocation;
  final LatLng? tappedLatLng;
  final void Function(TapPosition, LatLng)? onTap;
  final NearbyPlaces? selectedNearbyPlaces;
  final List<OneMapNearbyPlace> nearbyPlaces;

  @override
  State<UIMap> createState() => _UIMapState();
}

class _UIMapState extends State<UIMap> {
  MapController? get mapController => widget.mapController;
  LatLng? get tappedLatLng => widget.tappedLatLng;
  void Function(TapPosition, LatLng)? get onTap => widget.onTap;
  NearbyPlaces? get selectedNearbyPlaces => widget.selectedNearbyPlaces;
  List<OneMapNearbyPlace> get nearbyPlaces => widget.nearbyPlaces;

  final sgBounds = LatLngBounds(
    const LatLng(1.144, 103.585), //southwest
    const LatLng(1.494, 104.122), //northeast
  );

  late bool focusCurrentLocation;

  @override
  void initState() {
    super.initState();
    focusCurrentLocation = widget.focusCurrentLocation;
  }

  @override
  void didUpdateWidget(covariant UIMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    focusCurrentLocation = widget.focusCurrentLocation;
  }

  @override
  Widget build(BuildContext context) {
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
          bounds: sgBounds,
        ),
        keepAlive: true,
      ),
      children: [
        // Base map
        TileLayer(
          tileUpdateTransformer:
              MapControllerExtension.animatedMoveTileUpdateTransformer,
          urlTemplate:
              "https://www.onemap.gov.sg/maps/tiles/Default_HD/{z}/{x}/{y}.png",
          userAgentPackageName: "com.example.mapdemo",
        ),

        // Attribute (https://www.onemap.gov.sg/docs/maps/)
        Align(
          alignment: Alignment.bottomRight,
          child: ColoredBox(
            color: Colors.white70,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.network(
                  'https://www.onemap.gov.sg/web-assets/images/logo/om_logo.png',
                  width: 18,
                  height: 18,
                ),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 10),
                    children: [
                      TextSpan(
                        text: " OneMap",
                        style: const TextStyle(
                          color: Colors.blue,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            final url = Uri.parse('https://www.onemap.gov.sg/');
                            if (!await launchUrl(url)) {
                              throw Exception('Could not launch $url');
                            }
                          },
                      ),
                      const TextSpan(
                        text: ' © contributors | ',
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(
                        text: "Singapore Land Authority ",
                        style: const TextStyle(
                          color: Colors.blue,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            final url = Uri.parse('https://www.sla.gov.sg/');
                            if (!await launchUrl(url)) {
                              throw Exception('Could not launch $url');
                            }
                          },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

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
        CurrentLocationLayer(focusCurrentLocation: focusCurrentLocation),

        // NearbyPlaces Marker
        NearbyPlacesLayer(
          places: nearbyPlaces,
          markerIcon: selectedNearbyPlaces != null
              ? Image.network(selectedNearbyPlaces!.icon)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
