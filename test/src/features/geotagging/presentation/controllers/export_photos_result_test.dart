import 'package:flutter_test/flutter_test.dart';

import 'package:geotag/src/features/geotagging/presentation/controllers/export_photos_result.dart';

void main() {
  group('ExportPhotosResult', () {
    test('ExportPhotosSuccess holds path', () {
      const path = '/storage/GeoTag';
      final result = ExportPhotosSuccess(path);
      expect(result.path, path);
    });

    test('ExportPhotosNoLocation is subtype', () {
      final result = ExportPhotosNoLocation();
      expect(result, isA<ExportPhotosResult>());
    });

    test('ExportPhotosCancelled is subtype', () {
      final result = ExportPhotosCancelled();
      expect(result, isA<ExportPhotosResult>());
    });
  });
}
