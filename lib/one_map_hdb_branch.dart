import 'package:latlong2/latlong.dart';
import 'package:mapdemo/extensions.dart';

class OneMapHdbBranch {
  final String name;
  final String description;
  final String addressBlockHouseNumber;
  final String addressFloorNumber;
  final String addressPostalCode;
  final String addressStreetName;
  final String addressUnitNumber;
  final String branchServiceLine;
  final String email;
  final String type;
  final LatLng? latlng;
  final String iconName;

  OneMapHdbBranch({
    required this.name,
    required this.description,
    required this.addressBlockHouseNumber,
    required this.addressFloorNumber,
    required this.addressPostalCode,
    required this.addressStreetName,
    required this.addressUnitNumber,
    required this.branchServiceLine,
    required this.email,
    required this.type,
    required this.latlng,
    required this.iconName,
  });

  OneMapHdbBranch.fromJson(Map<String, dynamic> data)
      : name = data['NAME'],
        description = data['DESCRIPTION'],
        addressBlockHouseNumber = data['ADDRESSBLOCKHOUSENUMBER'],
        addressFloorNumber = data['ADDRESSFLOORNUMBER'],
        addressPostalCode = data['ADDRESSPOSTALCODE'],
        addressStreetName = data['ADDRESSSTREETNAME'],
        addressUnitNumber = data['ADDRESSUNITNUMBER'],
        branchServiceLine = data['BRANCH_SERVICE_LINE'],
        email = data['EMAIL'],
        type = data['Type'],
        latlng = (data['LatLng'] as String?).toLatLng(),
        iconName = data['ICON_NAME'];

  Map<String, dynamic> toJson() => {
        "NAME": name,
        "DESCRIPTION": description,
        "ADDRESSBLOCKHOUSENUMBER": addressBlockHouseNumber,
        "ADDRESSFLOORNUMBER": addressFloorNumber,
        "ADDRESSPOSTALCODE": addressPostalCode,
        "ADDRESSSTREETNAME": addressStreetName,
        "ADDRESSUNITNUMBER": addressUnitNumber,
        "BRANCH_SERVICE_LINE": branchServiceLine,
        "EMAIL": email,
        "Type": type,
        "LatLng": latlng,
        "ICON_NAME": iconName,
      };
}
