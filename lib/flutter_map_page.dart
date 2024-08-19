import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapdemo/extensions.dart';
import 'package:mapdemo/location_helper.dart';
import 'package:mapdemo/nearby_places_enum.dart';
import 'package:mapdemo/one_map_community_club.dart';
import 'package:mapdemo/one_map_hdb_branch.dart';
import 'package:mapdemo/one_map_library.dart';
import 'package:mapdemo/one_map_nearby_place.dart';
import 'package:mapdemo/one_map_search_results.dart';
import 'package:mapdemo/street_view_page.dart';
import 'package:mapdemo/ui_map.dart';

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
  final dio = Dio();

  final sgBounds = LatLngBounds(
    const LatLng(1.144, 103.585), //southwest
    const LatLng(1.494, 104.122), //northeast
  );

  final FocusNode _searchFocusNode = FocusNode();
  final SearchController _searchController = SearchController();

  final MapController _mapController = MapController();

  bool focusCurrentLocation = true;

  LatLng? _currentLatLng;

  NearbyPlaces? _selectedNearbyPlaces;
  List<OneMapNearbyPlace> _nearbyPlaces = [];

  bool isbusy = false;

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Flutter Map'),
        actions: [
          MenuAnchor(
            builder: (context, controller, child) {
              return IconButton(
                onPressed: () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
                icon: const Icon(Icons.layers_outlined),
              );
            },
            menuChildren: List<MenuItemButton>.generate(
              NearbyPlaces.values.length,
              (int index) {
                final place = NearbyPlaces.values[index];
                return MenuItemButton(
                  onPressed: () => _searchNearbyPlaces(place),
                  leadingIcon: Image.network(place.icon, width: 30, height: 30),
                  child: Text(place.name),
                );
              },
            ),
          ),
        ],
      ),
      body: isbusy
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                UIMap(
                  mapController: _mapController,
                  focusCurrentLocation: focusCurrentLocation,
                  tappedLatLng: _currentLatLng,
                  onTap: (_, latlng) => _addMarkerAndMoveCamera(latlng),
                  nearbyPlaces: _nearbyPlaces,
                  nearbyMarkerIcon: _selectedNearbyPlaces != null
                      ? Image.network(_selectedNearbyPlaces!.icon)
                      : const SizedBox.shrink(),
                ),

                // Page control
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    children: [
                      SearchAnchor(
                        searchController: _searchController,
                        isFullScreen: false,
                        viewLeading: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () {
                            _searchController.closeView(null);
                            _searchController.text = "";
                            _searchFocusNode.unfocus();
                          },
                        ),
                        viewOnSubmitted: _goToLatLng,
                        builder: (context, controller) => SearchBar(
                          controller: controller,
                          focusNode: _searchFocusNode,
                          onTap: () => controller.openView(),
                        ),
                        suggestionsBuilder: _generateSuggestion,
                      ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "streetview",
            onPressed: _onStreetViewPressed,
            shape: const CircleBorder(),
            child: const Icon(Icons.streetview),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "currentlocation",
            onPressed: () => setState(() => focusCurrentLocation = true),
            shape: const CircleBorder(),
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  void _addMarkerAndMoveCamera(LatLng latLng) {
    setState(() {
      _currentLatLng = latLng;
      focusCurrentLocation = false;
    });

    //_mapController.move(latLng, 19);
    _mapController.animatedMove(this, latLng, 19);
  }

  final latlngRegex = RegExp(
      r'^[-+]?([1-8]?\d(\.\d+)?|90(\.0+)?),\s*[-+]?(180(\.0+)?|((1[0-7]\d)|([1-9]?\d))(\.\d+)?)$');

  void _goToLatLng(String s) async {
    _searchController.closeView(s);
    _searchFocusNode.unfocus();

    s = s.trim();

    if (s.isEmpty) return;

    if (latlngRegex.hasMatch(s)) {
      // is latlng
      LatLng? latLng = s.toLatLng();
      if (latLng != null) {
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
        'https://www.onemap.gov.sg/api/common/elastic/search',
        queryParameters: {
          'searchVal': s,
          'returnGeom': 'Y',
          'getAddrDetails': 'Y',
          'pageNum': 1,
        },
      );
      if (response.statusCode == 200) {
        var json = response.data as Map<String, dynamic>;
        OneMapSearchResults searchResults = OneMapSearchResults.fromJson(json);
        if (searchResults.found > 0) {
          AddressResult location = searchResults.results[0];
          if (location.lat != null && location.lng != null) {
            _addMarkerAndMoveCamera(LatLng(location.lat!, location.lng!));
          }
        } else {
          if (!mounted) return;
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

    if (s.isEmpty) {
      s = "a";
    }

    var response = await dio.get(
      'https://www.onemap.gov.sg/api/common/elastic/search',
      queryParameters: {
        'searchVal': s,
        'returnGeom': 'Y',
        'getAddrDetails': 'Y',
        'pageNum': 1,
      },
    );
    if (response.statusCode == 200) {
      var json = response.data as Map<String, dynamic>;
      OneMapSearchResults searchResults = OneMapSearchResults.fromJson(json);
      if (searchResults.found > 0) {
        return List<ListTile>.generate(searchResults.results.length,
            (int index) {
          final AddressResult location = searchResults.results[index];
          return ListTile(
            title: Text(location.searchVal),
            subtitle: Text(location.address),
            onTap: () {
              controller.closeView(null);
              controller.text = "";
              _searchFocusNode.unfocus();
              _addMarkerAndMoveCamera(LatLng(location.lat!, location.lng!));
            },
          );
        });
      }
    }
    return [
      const ListTile(
        title: Text("No results found"),
      )
    ];
  }

  void _onStreetViewPressed() async {
    setState(() {
      isbusy = true;
    });
    LatLng latLng;
    if (_currentLatLng != null) {
      latLng = _currentLatLng!;
    } else {
      Position? position = await LocationHelper.getCurrentPosition();
      if (position != null) {
        latLng = LatLng(position.latitude, position.longitude);
      } else {
        // No selected location and no current location
        latLng = const LatLng(1.354378, 103.833669);
      }
    }

    // Check if panorama exists at the location, this require to enable Street View Static API,
    // this requests are available at no charge because it is metadata requests.
    var response = await dio.get(
      'https://maps.googleapis.com/maps/api/streetview/metadata',
      queryParameters: {
        'location': "${latLng.latitude},${latLng.longitude}",
        'key': const String.fromEnvironment('MAPS_API_KEY'),
      },
    );
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

  void _searchNearbyPlaces(NearbyPlaces place) async {
    final queryName = switch (place) {
      NearbyPlaces.hdbBranches => 'hdb_branches',
      NearbyPlaces.communityClubs => 'communityclubs',
      NearbyPlaces.libraries => 'libraries',
    };

    LatLngBounds visibleBounds = _mapController.camera.visibleBounds;

    var response = await dio.get(
      'https://www.onemap.gov.sg/api/public/themesvc/retrieveTheme',
      queryParameters: {
        'queryName': queryName,
        'extents':
            '${visibleBounds.south},${visibleBounds.west},${visibleBounds.north},${visibleBounds.east}'
      },
      options: Options(
        headers: {
          'Authorization': const String.fromEnvironment('ONE_MAP_TOKEN'),
        },
      ),
    );

    if (response.statusCode == 200) {
      var json = response.data as Map<String, dynamic>;
      var results = json['SrchResults'] as List;

      if (!mounted) return;

      if (((results[0]["FeatCount"] as int?) ?? 0) > 0) {
        List<OneMapNearbyPlace> nearbyPlaces = results
            .sublist(1)
            .map<OneMapNearbyPlace>((r) => switch (place) {
                  NearbyPlaces.hdbBranches => OneMapHdbBranch.fromJson(r),
                  NearbyPlaces.communityClubs =>
                    OneMapCommunityClub.fromJson(r),
                  NearbyPlaces.libraries => OneMapLibrary.fromJson(r),
                })
            .toList();

        setState(() {
          focusCurrentLocation = false;
          _nearbyPlaces = nearbyPlaces;
          _selectedNearbyPlaces = place;
        });
      } else {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Not found"),
            content: Text("No nearby ${place.name} around."),
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
