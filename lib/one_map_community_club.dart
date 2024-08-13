import 'package:mapdemo/one_map_nearby_place.dart';

class OneMapCommunityClub extends OneMapNearbyPlace {
  final String? hyperLink;
  final String? addressType;

  OneMapCommunityClub({
    required super.name,
    required super.description,
    required super.addressBlockHouseNumber,
    required super.addressPostalCode,
    required super.addressStreetName,
    required super.type,
    required super.latlng,
    required super.iconName,
    this.hyperLink,
    this.addressType,
  });

  @override
  OneMapCommunityClub.fromJson(super.data)
      : hyperLink = data['HYPERLINK'],
        addressType = data['ADDRESSTYPE'],
        super.fromJson();

  @override
  Map<String, dynamic> toJson() => {
        if (hyperLink != null) "HYPERLINK": hyperLink,
        if (addressType != null) "ADDRESSTYPE": addressType,
        ...super.toJson(),
      };
}
