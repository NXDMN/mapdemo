import 'package:latlong2/latlong.dart';
import 'package:mapdemo/extensions.dart';

class OneMapNearbyPlace {
  final String name;
  final String description;
  final String addressBlockHouseNumber;
  final String? addressFloorNumber;
  final String addressPostalCode;
  final String addressStreetName;
  final String? addressUnitNumber;
  final String type;
  final LatLng? latlng;
  final String iconName;

  OneMapNearbyPlace({
    required this.name,
    required this.description,
    required this.addressBlockHouseNumber,
    this.addressFloorNumber,
    required this.addressPostalCode,
    required this.addressStreetName,
    this.addressUnitNumber,
    required this.type,
    required this.latlng,
    required this.iconName,
  });

  OneMapNearbyPlace.fromJson(Map<String, dynamic> data)
      : name = data['NAME'],
        description = data['DESCRIPTION'],
        addressBlockHouseNumber = data['ADDRESSBLOCKHOUSENUMBER'],
        addressFloorNumber = data['ADDRESSFLOORNUMBER'],
        addressPostalCode = data['ADDRESSPOSTALCODE'],
        addressStreetName = data['ADDRESSSTREETNAME'],
        addressUnitNumber = data['ADDRESSUNITNUMBER'],
        type = data['Type'],
        latlng = (data['LatLng'] as String?).toLatLng(),
        iconName = data['ICON_NAME'];

  Map<String, dynamic> toJson() => {
        "NAME": name,
        "DESCRIPTION": description,
        "ADDRESSBLOCKHOUSENUMBER": addressBlockHouseNumber,
        if (addressFloorNumber != null)
          "ADDRESSFLOORNUMBER": addressFloorNumber,
        "ADDRESSPOSTALCODE": addressPostalCode,
        "ADDRESSSTREETNAME": addressStreetName,
        if (addressUnitNumber != null) "ADDRESSUNITNUMBER": addressUnitNumber,
        "Type": type,
        "LatLng": latlng,
        "ICON_NAME": iconName,
      };
}
