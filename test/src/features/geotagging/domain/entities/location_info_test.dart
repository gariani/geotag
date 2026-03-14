import 'package:flutter_test/flutter_test.dart';

import 'package:geotag/src/features/geotagging/domain/entities/location_info.dart';

void main() {
  group('LocationInfo', () {
    test('creates with required latitude and longitude', () {
      const loc = LocationInfo(latitude: 48.8566, longitude: 2.3522);
      expect(loc.latitude, 48.8566);
      expect(loc.longitude, 2.3522);
      expect(loc.label, isNull);
    });

    test('creates with label', () {
      const loc = LocationInfo(
        latitude: -33.8688,
        longitude: 151.2093,
        label: 'Sydney, Australia',
      );
      expect(loc.label, 'Sydney, Australia');
    });

    test('handles negative coordinates', () {
      const loc = LocationInfo(latitude: -90, longitude: -180);
      expect(loc.latitude, -90);
      expect(loc.longitude, -180);
    });
  });
}
