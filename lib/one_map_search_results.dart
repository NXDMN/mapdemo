class OneMapSearchResults {
  final int found;
  final int totalNumPages;
  final int pageNum;
  final List<AddressResult> results;

  OneMapSearchResults({
    required this.found,
    required this.totalNumPages,
    required this.pageNum,
    required this.results,
  });

  OneMapSearchResults.fromJson(Map<String, dynamic> data)
      : found = int.tryParse(data['found'].toString()) ?? 0,
        totalNumPages = int.tryParse(data['totalNumPages'].toString()) ?? 0,
        pageNum = int.tryParse(data['pageNum'].toString()) ?? 0,
        results = List<AddressResult>.from((data['results'] as List)
            .map((model) => AddressResult.fromJson(model)));

  Map<String, dynamic> toJson() => {
        'found': found,
        'totalNumPages': totalNumPages,
        'pageNum': pageNum,
        'results': results.map((e) => e.toJson()),
      };
}

class AddressResult {
  final String searchVal;
  final String blkNo;
  final String roadName;
  final String building;
  final String address;
  final String postal;
  final double? x;
  final double? y;
  final double? lat;
  final double? lng;

  AddressResult({
    required this.searchVal,
    required this.blkNo,
    required this.roadName,
    required this.building,
    required this.address,
    required this.postal,
    required this.x,
    required this.y,
    required this.lat,
    required this.lng,
  });

  AddressResult.fromJson(Map<String, dynamic> data)
      : searchVal = data['SEARCHVAL'],
        blkNo = data['BLK_NO'],
        roadName = data['ROAD_NAME'],
        building = data['BUILDING'],
        address = data['ADDRESS'],
        postal = data['POSTAL'],
        x = double.tryParse(data['X'].toString()),
        y = double.tryParse(data['Y'].toString()),
        lat = double.tryParse(data['LATITUDE'].toString()),
        lng = double.tryParse(data['LONGITUDE'].toString());

  Map<String, dynamic> toJson() => {
        'SEARCHVAL': searchVal,
        'BLK_NO': blkNo,
        'ROAD_NAME': roadName,
        'BUILDING': building,
        'ADDRESS': address,
        'POSTAL': postal,
        'X': x,
        'Y': y,
        'LATITUDE': lat,
        'LONGITUDE': lng,
      };
}
