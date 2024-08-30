import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapdemo/extensions.dart';

void main() {
  group("Extensions Test", () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test("LatLngExtension.checkWithinBounds", () {
      const testLatLng = LatLng(1.2, 103.7);
      final testLatLngBounds = LatLngBounds(
        const LatLng(1.144, 103.585),
        const LatLng(1.494, 104.122),
      );
      expect(testLatLng.checkWithinBounds(testLatLngBounds), true);
    });

    test("StringExtension.toLatLng", () {
      const testString = "1.2, 103.7";
      const expectedLatLng = LatLng(1.2, 103.7);
      expect(testString.toLatLng(), expectedLatLng);
    });
  });
}
