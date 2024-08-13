import 'package:mapdemo/one_map_nearby_place.dart';

class OneMapLibrary extends OneMapNearbyPlace {
  final String? addressBuildingName;
  final String hyperLink;
  final String photoUrl;
  final String landXAddressPoint;
  final String landYAddressPoint;

  OneMapLibrary({
    required super.name,
    required super.description,
    required super.addressBlockHouseNumber,
    required super.addressFloorNumber,
    required super.addressPostalCode,
    required super.addressStreetName,
    required super.addressUnitNumber,
    required super.type,
    required super.latlng,
    required super.iconName,
    this.addressBuildingName,
    required this.hyperLink,
    required this.photoUrl,
    required this.landXAddressPoint,
    required this.landYAddressPoint,
  });

  @override
  OneMapLibrary.fromJson(super.data)
      : addressBuildingName = data['ADDRESSBUILDINGNAME'],
        hyperLink = data['HYPERLINK'],
        photoUrl = data['PHOTOURL'],
        landXAddressPoint = data['LANDXADDRESSPOINT'],
        landYAddressPoint = data['LANDYADDRESSPOINT'],
        super.fromJson();

  @override
  Map<String, dynamic> toJson() => {
        if (addressBuildingName != null)
          "ADDRESSBUILDINGNAME": addressBuildingName,
        "HYPERLINK": hyperLink,
        "PHOTOURL": photoUrl,
        "LANDXADDRESSPOINT": landXAddressPoint,
        "LANDYADDRESSPOINT": landYAddressPoint,
        ...super.toJson(),
      };
}
