import 'package:flutter_test/flutter_test.dart';

import 'package:geotag/src/features/geotagging/domain/entities/location_info.dart';
import 'package:geotag/src/features/geotagging/domain/entities/photo.dart';

void main() {
  group('Photo', () {
    test('creates with required fields', () {
      final photo = Photo(
        id: '1',
        title: 'test.jpg',
        takenAt: DateTime(2024, 1, 15),
      );
      expect(photo.id, '1');
      expect(photo.title, 'test.jpg');
      expect(photo.takenAt, DateTime(2024, 1, 15));
      expect(photo.imagePath, isNull);
      expect(photo.location, isNull);
      expect(photo.exportedAt, isNull);
    });

    test('creates with all fields', () {
      const location = LocationInfo(latitude: 48.8, longitude: 2.3);
      final exportedAt = DateTime(2024, 2, 1);
      final photo = Photo(
        id: '2',
        title: 'photo.jpg',
        takenAt: DateTime(2024, 1, 10),
        imagePath: '/path/to/photo.jpg',
        location: location,
        exportedAt: exportedAt,
      );
      expect(photo.imagePath, '/path/to/photo.jpg');
      expect(photo.location, location);
      expect(photo.exportedAt, exportedAt);
    });

    test('copyWith updates only specified fields', () {
      const location = LocationInfo(latitude: 48.8, longitude: 2.3);
      final photo = Photo(
        id: '1',
        title: 'original.jpg',
        takenAt: DateTime(2024, 1, 1),
      );

      final updated = photo.copyWith(location: location);

      expect(updated.id, '1');
      expect(updated.title, 'original.jpg');
      expect(updated.takenAt, DateTime(2024, 1, 1));
      expect(updated.location, location);
      expect(updated.exportedAt, isNull);
    });

    test('copyWith updates imagePath', () {
      final photo = Photo(
        id: '1',
        title: 'x.jpg',
        takenAt: DateTime(2024, 1, 1),
        imagePath: '/old/path.jpg',
      );
      final updated = photo.copyWith(imagePath: '/new/path.jpg');
      expect(updated.imagePath, '/new/path.jpg');
    });

    test('copyWith updates exportedAt', () {
      final photo = Photo(
        id: '1',
        title: 'x.jpg',
        takenAt: DateTime(2024, 1, 1),
      );
      final exportedAt = DateTime(2024, 3, 1);
      final updated = photo.copyWith(exportedAt: exportedAt);
      expect(updated.exportedAt, exportedAt);
    });
  });
}
