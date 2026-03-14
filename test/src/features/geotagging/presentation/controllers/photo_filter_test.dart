import 'package:flutter_test/flutter_test.dart';

import 'package:geotag/src/features/geotagging/presentation/controllers/photo_filter.dart';

void main() {
  group('PhotoFilter', () {
    test('has expected enum values', () {
      expect(PhotoFilter.values, contains(PhotoFilter.all));
      expect(PhotoFilter.values, contains(PhotoFilter.missingLocation));
      expect(PhotoFilter.values, contains(PhotoFilter.recent));
      expect(PhotoFilter.values, contains(PhotoFilter.hasLocation));
      expect(PhotoFilter.values, contains(PhotoFilter.exported));
      expect(PhotoFilter.values.length, 5);
    });
  });
}
