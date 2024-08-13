import 'package:mapdemo/one_map_nearby_place.dart';

class OneMapHdbBranch extends OneMapNearbyPlace {
  final String branchServiceLine;
  final String email;

  OneMapHdbBranch({
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
    required this.branchServiceLine,
    required this.email,
  });

  @override
  OneMapHdbBranch.fromJson(super.data)
      : branchServiceLine = data['BRANCH_SERVICE_LINE'],
        email = data['EMAIL'],
        super.fromJson();

  @override
  Map<String, dynamic> toJson() => {
        "BRANCH_SERVICE_LINE": branchServiceLine,
        "EMAIL": email,
        ...super.toJson(),
      };
}
