import 'package:mapdemo/one_map_nearby_place.dart';

class OneMapHawkerCentre extends OneMapNearbyPlace {
  final String? addressBuildingName;
  final String? photoUrl;
  final String landXAddressPoint;
  final String landYAddressPoint;
  final String status;
  final String? addressMyenv;
  final String? awardedDate;
  final String? implementationDate;
  final String? infoOnCoLocators;
  final String? estOriginalCompletionDate;
  final String? hupCompletionDate;
  final String numberOfCookedFoodStalls;
  final double? distance;

  OneMapHawkerCentre({
    required super.name,
    required super.description,
    required super.addressBlockHouseNumber,
    required super.addressPostalCode,
    required super.addressStreetName,
    required super.latlng,
    required super.iconName,
    this.addressBuildingName,
    this.photoUrl,
    required this.landXAddressPoint,
    required this.landYAddressPoint,
    required this.status,
    this.addressMyenv,
    this.awardedDate,
    this.implementationDate,
    this.infoOnCoLocators,
    this.estOriginalCompletionDate,
    this.hupCompletionDate,
    required this.numberOfCookedFoodStalls,
    required this.distance,
  });

  @override
  OneMapHawkerCentre.fromJson(super.data)
      : addressBuildingName = data['ADDRESSBUILDINGNAME'],
        photoUrl = data['PHOTOURL'],
        landXAddressPoint = data['LANDXADDRESSPOINT'],
        landYAddressPoint = data['LANDYADDRESSPOINT'],
        status = data['STATUS'],
        addressMyenv = data['ADDRESS_MYENV'],
        awardedDate = data['AWARDED_DATE'],
        implementationDate = data['IMPLEMENTATION_DATE'],
        infoOnCoLocators = data['INFO_ON_CO_LOCATORS'],
        estOriginalCompletionDate = data['EST_ORIGINAL_COMPLETION_DATE'],
        hupCompletionDate = data['HUP_COMPLETION_DATE'],
        numberOfCookedFoodStalls = data['NUMBER_OF_COOKED_FOOD_STALLS'],
        distance = double.tryParse(data['DISTANCE'].toString()),
        super.fromJson();

  @override
  Map<String, dynamic> toJson() => {
        if (addressBuildingName != null)
          "ADDRESSBUILDINGNAME": addressBuildingName,
        if (photoUrl != null) "PHOTOURL": photoUrl,
        "LANDXADDRESSPOINT": landXAddressPoint,
        "LANDYADDRESSPOINT": landYAddressPoint,
        "STATUS": status,
        if (addressMyenv != null) "ADDRESS_MYENV": addressMyenv,
        if (awardedDate != null) "AWARDED_DATE": awardedDate,
        if (implementationDate != null)
          "IMPLEMENTATION_DATE": implementationDate,
        if (infoOnCoLocators != null) "INFO_ON_CO_LOCATORS": infoOnCoLocators,
        if (estOriginalCompletionDate != null)
          "EST_ORIGINAL_COMPLETION_DATE": estOriginalCompletionDate,
        if (hupCompletionDate != null) "HUP_COMPLETION_DATE": hupCompletionDate,
        "NUMBER_OF_COOKED_FOOD_STALLS": numberOfCookedFoodStalls,
        "DISTANCE": distance,
        ...super.toJson(),
      };
}
