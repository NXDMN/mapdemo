import 'package:latlong2/latlong.dart';

class StreetViewPanoramaOrientation {
  StreetViewPanoramaOrientation({this.bearing, this.tilt});

  /// Direction of the orientation, in degrees clockwise from north.
  final double? bearing;

  /// The angle, in degrees, of the orientation.
  final double? tilt;

  /// Create [StreetViewPanoramaOrientation] and put data by [map].
  factory StreetViewPanoramaOrientation.fromMap(dynamic map) {
    return StreetViewPanoramaOrientation(
      bearing: map['bearing'] as double?,
      tilt: map['tilt'] as double?,
    );
  }

  /// Put all param to a map
  Map<String, dynamic> toMap() => {'bearing': bearing, 'tilt': tilt};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreetViewPanoramaOrientation &&
          runtimeType == other.runtimeType &&
          bearing == other.bearing &&
          tilt == other.tilt;

  @override
  int get hashCode => bearing.hashCode ^ tilt.hashCode;

  @override
  String toString() {
    return 'StreetViewPanoramaOrientation{bearing: $bearing, tilt: $tilt}';
  }
}

class StreetViewPanoramaCamera {
  StreetViewPanoramaCamera({this.bearing, this.tilt, this.zoom, this.fov});

  ///Direction of the orientation, in degrees clockwise from north.
  final double? bearing;

  /// The angle in degrees from horizon of the panorama, range -90 to 90
  final double? tilt;

  /// The zoom level of current panorama.
  /// more info see,
  /// for [android] https://developers.google.com/android/reference/com/google/android/gms/maps/model/StreetViewPanoramaCamera.Builder#zoom
  /// for [iOS] https://developers.google.com/maps/documentation/ios-sdk/reference/interface_g_m_s_panorama_camera#adb2250d57b30987cd2d13e52fa03833d
  final double? zoom;

  /// The field of view (FOV) encompassed by the larger dimension (width or height) of the view in degrees at zoom 1. `iOS only`
  /// This is clamped to the range [1, 160] degrees, and has a default value of 90.
  /// more info see, [iOS] https://developers.google.com/maps/documentation/ios-sdk/reference/interface_g_m_s_panorama_camera#a64dcd1302c83a54f2d068cbb19ea5cef
  final double? fov;

  factory StreetViewPanoramaCamera.fromMap(dynamic map) {
    return StreetViewPanoramaCamera(
      bearing: map['bearing'] as double?,
      tilt: map['tilt'] as double?,
      zoom: map['zoom'] as double?,
      fov: map['fov'] as double?,
    );
  }

  Map<String, dynamic> toMap() =>
      {'bearing': bearing, 'tilt': tilt, 'zoom': zoom, 'fov': fov};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreetViewPanoramaCamera &&
          runtimeType == other.runtimeType &&
          bearing == other.bearing &&
          tilt == other.tilt &&
          zoom == other.zoom &&
          fov == other.fov;

  @override
  int get hashCode =>
      bearing.hashCode ^ tilt.hashCode ^ zoom.hashCode ^ fov.hashCode;

  @override
  String toString() {
    return 'StreetViewPanoramaCamera{bearing: $bearing, tilt: $tilt, zoom: $zoom, fov: $fov}';
  }
}

class StreetViewPanoramaLocation {
  /// Array [StreetViewPanoramaLink] includes information about near panoramas of current panorama.
  final List<StreetViewPanoramaLink>? links;

  /// The location of current panorama.
  final LatLng? position;

  /// The panorama Id of current panorama.
  final String? panoId;

  StreetViewPanoramaLocation({this.links, this.position, this.panoId});

  factory StreetViewPanoramaLocation.fromMap(dynamic map) {
    List<StreetViewPanoramaLink>? linksTmp;
    LatLng? position;
    String? panoId;
    if (map != null) {
      if (map['links'] != null) {
        linksTmp = [];
        (map['links'] as List?)?.forEach((e) {
          linksTmp!.add(StreetViewPanoramaLink(panoId: e[0], bearing: e[1]));
        });
      }
      position = map['position'][0] != null && map['position'][1] != null
          ? LatLng(map['position'][0] as double, map['position'][1] as double)
          : null;
      panoId = map['panoId'] as String?;
    }
    return StreetViewPanoramaLocation(
        links: linksTmp, position: position, panoId: panoId);
  }

  Map<String, dynamic> toMap() {
    // ignore: unnecessary_cast
    return {
      'links': links,
      'position': position,
      'panoId': panoId,
    } as Map<String, dynamic>;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreetViewPanoramaLocation &&
          runtimeType == other.runtimeType &&
          links == other.links &&
          position == other.position &&
          panoId == other.panoId;

  bool isNull() => links == null && position == null && panoId == null;

  @override
  int get hashCode => links.hashCode ^ position.hashCode ^ panoId.hashCode;

  @override
  String toString() {
    return 'StreetViewPanoramaLocation{links: $links, position: $position, panoId: $panoId}';
  }
}

class StreetViewPanoramaLink {
  StreetViewPanoramaLink({this.bearing, this.panoId});

  /// The direction of the linked panorama, in degrees clockwise from north.
  final double? bearing;

  /// The panorama ID of the linked panorama.
  final String? panoId;

  /// Create a [StreetViewPanoramaLink] and init data by a map.
  factory StreetViewPanoramaLink.fromMap(Map<String, dynamic> map) {
    return StreetViewPanoramaLink(
      bearing: map['bearing'] as double?,
      panoId: map['panoId'] as String?,
    );
  }

  /// Put all param to a map
  Map<String, dynamic> toMap() => {
        'bearing': bearing,
        'panoId': panoId,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreetViewPanoramaLink &&
          runtimeType == other.runtimeType &&
          bearing == other.bearing &&
          panoId == other.panoId;

  @override
  int get hashCode => bearing.hashCode ^ panoId.hashCode;

  @override
  String toString() {
    return 'StreetViewPanoramaLink{bearing: $bearing, panoId: $panoId}';
  }
}
