import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapdemo/current_location_layer.dart';
import 'package:mapdemo/extensions.dart';
import 'package:mapdemo/location_helper.dart';
import 'package:mapdemo/one_map_search_results.dart';
import 'package:mapdemo/street_view_page.dart';

/*
1. able to plot marker on the map
2. click on marker
3. show Singapore map
4. hide show layers on the map
5. pan to location using lat lng
*/
class FlutterMapPage extends StatefulWidget {
  const FlutterMapPage({super.key});

  @override
  State<FlutterMapPage> createState() => _FlutterMapPageState();
}

class _FlutterMapPageState extends State<FlutterMapPage>
    with TickerProviderStateMixin {
  bool showControls = false;
  final dio = Dio();

  final sgBounds = LatLngBounds(
    const LatLng(1.144, 103.585), //southwest
    const LatLng(1.494, 104.122), //northeast
  );

  final MapController _mapController = MapController();
  bool showPolygons = false;
  bool showPolylines = false;
  bool showCircles = false;

  Position? _currentLocation;
  bool focusCurrentLocation = false;

  // Markers START
  Map<String, Marker> markers = <String, Marker>{};
  int _markerIdCounter = 0;
  final List<LatLng> latLngList = [
    const LatLng(1.300535688799964, 103.85526531815529),
    const LatLng(1.340535688799964, 103.81526531815529),
    const LatLng(1.3414141175644319, 103.70247144252062),
    const LatLng(1.342965014570922, 103.70189175009727),
    const LatLng(1.439634488961546, 103.82100060582161),
    const LatLng(1.376783841865973, 103.76657422631979),
    const LatLng(1.3705803346710366, 103.85150905698538),
    const LatLng(1.3482605813428485, 103.9541494846344),
    const LatLng(1.3249689179499191, 103.9135492220521),
    const LatLng(1.3568198071147146, 103.88276115059853),
    const LatLng(1.3438505706221706, 103.75726092606783),
  ];

  static const current = "current";
  void _addMarker(LatLng l, {bool temp = false}) {
    final String markerId = temp ? current : "$_markerIdCounter";
    final Marker marker = Marker(
      point: l,
      width: 50,
      height: 50,
      child: IconButton(
        iconSize: 50,
        color: Colors.red,
        icon: const Icon(Icons.location_pin),
        onPressed: () {
          _onMarkerTapped(markerId);
        },
      ),
    );

    setState(() {
      markers[markerId] = marker;
    });

    _markerIdCounter++;
  }

  void _onMarkerTapped(String id) {
    final Marker? tappedMarker = markers[id];
    if (tappedMarker != null) {
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
  // Markers END

  bool isbusy = false;
  @override
  void initState() {
    super.initState();

    _getCurrentLocation();

    for (var l in latLngList) {
      _addMarker(l);
    }
  }

  void _getCurrentLocation() async {
    setState(() {
      isbusy = true;
    });
    try {
      _currentLocation = await LocationHelper.getCurrentPosition();
      if (_currentLocation != null) {
        focusCurrentLocation = true;
      }
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Location Error"),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              )
            ],
          ),
        );
      });
    }
    setState(() {
      isbusy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Flutter Map'),
        actions: [
          IconButton(
              onPressed: () => setState(() => showControls = !showControls),
              icon: Icon(showControls ? Icons.expand_less : Icons.expand_more))
        ],
      ),
      body: isbusy
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    minZoom: 11,
                    maxZoom: 19,
                    initialZoom: _currentLocation != null ? 19 : 12,
                    initialCenter: _currentLocation != null
                        ? LatLng(_currentLocation!.latitude,
                            _currentLocation!.longitude)
                        : const LatLng(1.354378, 103.833669),
                    onTap: (_, latlng) => _addMarkerAndMoveCamera(latlng),
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
                      tileUpdateTransformer: MapControllerExtension
                          .animatedMoveTileUpdateTransformer,
                      urlTemplate:
                          "https://www.onemap.gov.sg/maps/tiles/Default_HD/{z}/{x}/{y}.png",
                      userAgentPackageName: "com.example.mapdemo",
                    ),

                    if (_currentLocation != null)
                      CurrentLocationLayer(
                        _currentLocation!,
                        focusCurrentLocation: focusCurrentLocation,
                      ),

                    // Markers
                    MarkerLayer(
                      rotate: true,
                      markers: markers.values.toList(),
                    ),
                    // Polygons
                    if (showPolygons)
                      PolygonLayer(
                        polygons: [
                          Polygon(
                            points: [
                              LatLng(1.325, 103.905),
                              LatLng(1.345, 103.905),
                              LatLng(1.345, 103.855),
                              LatLng(1.325, 103.855),
                            ],
                            color: Colors.blue.withOpacity(0.5),
                            borderStrokeWidth: 2,
                            borderColor: Colors.blue,
                          ),
                        ],
                      ),

                    // Polygons
                    if (showPolylines)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [
                              LatLng(1.3005161, 103.7844032),
                              LatLng(1.3004098, 103.7844825),
                              LatLng(1.2998453, 103.7850075),
                              LatLng(1.2997711, 103.7851701),
                              LatLng(1.2997611, 103.7853548),
                              LatLng(1.2998092, 103.7855315),
                              LatLng(1.2999035, 103.78566),
                              LatLng(1.3005722, 103.7860762),
                              LatLng(1.301237, 103.7865871),
                              LatLng(1.3015098, 103.7867477),
                              LatLng(1.3017394, 103.7868561),
                              LatLng(1.3017624, 103.7868571),
                              LatLng(1.301868, 103.7868902),
                              LatLng(1.3026965, 103.7870746),
                              LatLng(1.3031376, 103.7872491),
                              LatLng(1.3034016, 103.7873882),
                              LatLng(1.3034778, 103.7874344),
                              LatLng(1.3039156, 103.7877986),
                              LatLng(1.3040901, 103.7880094),
                              LatLng(1.30449, 103.7886343),
                              LatLng(1.3051121, 103.7895788),
                              LatLng(1.305427, 103.7900045),
                              LatLng(1.3059201, 103.7903625),
                              LatLng(1.3061778, 103.7905221),
                              LatLng(1.3064435, 103.7906536),
                              LatLng(1.3069118, 103.7908976),
                              LatLng(1.307847, 103.7912194),
                              LatLng(1.30881, 103.7915379),
                              LatLng(1.3090273, 103.7915519),
                              LatLng(1.3092903, 103.7915162),
                              LatLng(1.3107071, 103.7910769),
                              LatLng(1.3108926, 103.7910706),
                              LatLng(1.3112273, 103.7911472),
                              LatLng(1.3113798, 103.7912337),
                              LatLng(1.3121803, 103.7919791),
                              LatLng(1.3134712, 103.7931795),
                              LatLng(1.3123137, 103.7947289),
                              LatLng(1.3121993, 103.7949502),
                              LatLng(1.3121091, 103.7952034),
                              LatLng(1.3120761, 103.7954578),
                              LatLng(1.3120913, 103.7956995),
                              LatLng(1.312151, 103.7959778),
                              LatLng(1.3128751, 103.7973623),
                              LatLng(1.3129828, 103.79821),
                              LatLng(1.3128863, 103.7985389),
                              LatLng(1.312743, 103.7988253),
                              LatLng(1.3119794, 103.8001084),
                              LatLng(1.3119005, 103.8004089),
                              LatLng(1.3110833, 103.8031665),
                            ],
                            strokeWidth: 5,
                            color: Colors.red.withOpacity(0.5),
                          ),
                        ],
                      ),
                    // Circles
                    if (showCircles)
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: LatLng(1.2868108, 103.8545349),
                            radius: 1000,
                            color: Colors.green.withOpacity(0.5),
                            borderColor: Colors.black.withOpacity(0.5),
                            useRadiusInMeter: true,
                          ),
                        ],
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
                            const Text(
                              'OneMap ©2023 contributors | Singapore Land Authority',
                              style: TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),

                // Page control
                if (showControls)
                  Column(
                    children: [
                      SearchAnchor(
                        isFullScreen: false,
                        viewOnSubmitted: (value) {
                          _goToLatLng(value);
                        },
                        builder: (context, controller) => SearchBar(
                          controller: controller,
                          onSubmitted: _goToLatLng,
                          // onTap: () {
                          //   controller.openView();
                          // },
                          onChanged: (_) {
                            controller.openView();
                          },
                        ),
                        suggestionsBuilder: _generateSuggestion,
                      ),
                      Row(
                        children: [
                          FilledButton(
                            onPressed: () =>
                                setState(() => showPolygons = !showPolygons),
                            child: const Text("Polygon"),
                          ),
                          FilledButton(
                            onPressed: () =>
                                setState(() => showPolylines = !showPolylines),
                            child: const Text("Polyline"),
                          ),
                          FilledButton(
                            onPressed: () =>
                                setState(() => showCircles = !showCircles),
                            child: const Text("Circle"),
                          ),
                          IconButton.filled(
                            onPressed: () =>
                                setState(() => focusCurrentLocation = true),
                            icon: const Icon(Icons.my_location),
                          ),
                          IconButton.filled(
                            onPressed: _onStreetViewPressed,
                            icon: const Icon(Icons.streetview),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
    );
  }

  void _addMarkerAndMoveCamera(LatLng latLng) {
    print(latLng);
    _addMarker(latLng, temp: true);

    //_mapController.move(latLng, 19);
    _mapController.animatedMove(this, latLng, 19);
  }

  final latlngRegex = RegExp(
      r'^[-+]?([1-8]?\d(\.\d+)?|90(\.0+)?),\s*[-+]?(180(\.0+)?|((1[0-7]\d)|([1-9]?\d))(\.\d+)?)$');
  void _goToLatLng(String s) async {
    s = s.trim();

    if (latlngRegex.hasMatch(s)) {
      // is latlng
      final l = s.split(',');
      if (l.length == 2) {
        final lat = double.tryParse(l[0]);
        final lng = double.tryParse(l[1]);

        if (lat != null && lng != null) {
          LatLng latLng = LatLng(lat, lng);
          if (latLng.checkWithinBounds(sgBounds)) {
            _addMarkerAndMoveCamera(latLng);
          } else {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text("Error"),
                content: const Text("Exceed bounds"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("OK"),
                  )
                ],
              ),
            );
          }
        }
      } else {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Error"),
            content: const Text("Invalid latlng"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              )
            ],
          ),
        );
      }
    } else {
      // not latlng
      var response = await dio.get(
          'https://www.onemap.gov.sg/api/common/elastic/search?searchVal=$s&returnGeom=Y&getAddrDetails=Y&pageNum=1');
      if (response.statusCode == 200) {
        var json = jsonDecode(response.data) as Map<String, dynamic>;
        OneMapSearchResults searchResults = OneMapSearchResults.fromJson(json);
        if (searchResults.found > 0) {
          AddressResult location = searchResults.results[0];
          if (location.lat != null && location.lng != null) {
            _addMarkerAndMoveCamera(LatLng(location.lat!, location.lng!));
          }
        } else {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Not found"),
              content: const Text("Try other values"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("OK"),
                )
              ],
            ),
          );
        }
      }
    }
  }

  Future<List<Widget>> _generateSuggestion(
      BuildContext context, SearchController controller) async {
    var s = controller.text.trim();
    var response = await dio.get(
        'https://www.onemap.gov.sg/api/common/elastic/search?searchVal=$s&returnGeom=Y&getAddrDetails=Y&pageNum=1');
    if (response.statusCode == 200) {
      var json = jsonDecode(response.data) as Map<String, dynamic>;
      OneMapSearchResults searchResults = OneMapSearchResults.fromJson(json);
      if (searchResults.found > 0) {
        return List<ListTile>.generate(searchResults.results.length,
            (int index) {
          final AddressResult location = searchResults.results[index];
          return ListTile(
            title: Text(location.searchVal),
            subtitle: Text(location.address),
            onTap: () {
              setState(() {
                controller.closeView(s);
              });
              _addMarkerAndMoveCamera(LatLng(location.lat!, location.lng!));
            },
          );
        });
      }
    }
    return [
      const ListTile(
        title: Text("Not results found"),
      )
    ];
  }

  void _onStreetViewPressed() async {
    setState(() {
      isbusy = true;
    });
    final marker = markers[current];
    LatLng latLng;
    if (marker != null) {
      latLng = marker.point;
    } else {
      Position? position = await LocationHelper.getCurrentPosition();
      if (position != null) {
        _currentLocation = position;
      }
      latLng = LatLng(_currentLocation!.latitude, _currentLocation!.longitude);
    }

    // Check if panorama exists at the location, this require to enable Street View Static API,
    // this requests are available at no charge because it is metadata requests.
    var response = await dio.get(
        'https://maps.googleapis.com/maps/api/streetview/metadata?location=${latLng.latitude},${latLng.longitude}&key=API_KEY');
    if (response.statusCode == 200) {
      if (!mounted) return;

      if (response.data['status'] as String == "OK") {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => StreetViewPage(latLng),
        ));
      } else {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Not found"),
            content: const Text("No street view at this location."),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              )
            ],
          ),
        );
      }
    }

    setState(() {
      isbusy = false;
    });
  }
}
//eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJiM2ViOTBhMzVhMTY2OWZiN2I1OTk4ZDM1Yzc4OGFjMiIsImlzcyI6Imh0dHA6Ly9pbnRlcm5hbC1hbGItb20tcHJkZXppdC1pdC0xMjIzNjk4OTkyLmFwLXNvdXRoZWFzdC0xLmVsYi5hbWF6b25hd3MuY29tL2FwaS92Mi91c2VyL3Bhc3N3b3JkIiwiaWF0IjoxNzIxMDIyMDc2LCJleHAiOjE3MjEyODEyNzYsIm5iZiI6MTcyMTAyMjA3NiwianRpIjoiZUFMSkZPU3JxMks0UG1PbyIsInVzZXJfaWQiOjQwNTYsImZvcmV2ZXIiOmZhbHNlfQ.MOLMUi9OwU-0iQTBryeURU83xpdm1Ckofx0nCeHC1dI

