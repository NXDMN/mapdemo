import 'package:flutter_test/flutter_test.dart';

/*
Tap on map:
  - if the map tapped, assign LatLng to _currentLatLng, marker show at the location, camera focus the location
  - Only one current tapped marker will show at a time, tap on another location will make previous marker disappear
Nearby places:
  - When selected, search the place within visible bounds (screen)
  - ONE_MAP_TOKEN must be active to use (3 days expiration)
  - if found, map to _nearbyPlaces, set marker icon and unfocus current location
  else, show Not Found dialog
  - The nearby places shown one type at a time, choosing another will make previous disappear,
  places shown are all within current bound only, those previously shown places will disappear if not within the bounds,
  if no nearby places found, those previously shown places will remain visible
Search:
  - Tap on search bar will open the suggestion list
  - Tap back button will close the suggestion list, clear the text, unfocus searchbar
  - Suggestion:
    - if no text entered, show default suggestion list (assume text entered is "a")
    - if found, map to suggestion list with search value and address (both from response data) 
    else, show "No results found"
    - tap on suggestion item will close the suggestion list, clear the text, unfocus searchbar,
      assign LatLng to _currentLatLng, marker show at the location, camera focus the location
    - if text entered is latlng, suggestion list shown are not the location on entered latlng (unless use api that retrieve place with latlng?)
  - ViewOnSubmitted (press enter):
    - close the suggestion list, unfocus searchbar, but the text entered will still exist
    - if found, assume the location selected is first in suggestion list,
      assign LatLng to _currentLatLng, marker show at the location, camera focus the location
      else, show "Try other values" dialog
    - if text entered is latlng, convert to LatLng, if failed show "Invalid latlng" dialog,
      else, check the latlng is within Singapore bounds, if failed show "Exceed bounds" dialog,
      else, assign LatLng to _currentLatLng, marker show at the location, camera focus the location
Street view:
  - if there is current marker plotted by tapping on map, use the location (_currentLatLng),
    else, get current location, if failed use default location
  - if panorama exists at the location using Street View Static API (need MAPS_API_KEY but no charge incurred), navigate to StreetViewPage
    else, show "Not found" dialog
Current location:
  - If permission granted, will focus current location
    else, will show "Location Error" dialog
*/
void main() {
  group("FlutterMapPage", () {});
}
