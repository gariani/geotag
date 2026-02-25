import 'package:flutter_test/flutter_test.dart';

import 'package:geotag/src/features/geotagging/domain/entities/location_info.dart';
import 'package:geotag/src/features/geotagging/domain/entities/photo.dart';
import 'package:geotag/src/features/geotagging/domain/repositories/photo_repository.dart';
import 'package:geotag/src/features/geotagging/presentation/controllers/export_photos_result.dart';
import 'package:geotag/src/features/geotagging/presentation/controllers/geotagging_controller.dart';

class FakePhotoRepository implements PhotoRepository {
  FakePhotoRepository({List<Photo>? initialPhotos})
      : _photos = List.from(initialPhotos ?? []);

  final List<Photo> _photos;

  @override
  Future<List<Photo>> fetchPhotos() async => List<Photo>.from(_photos);

  @override
  Future<void> updatePhotos(List<Photo> photos) async {
    _photos
      ..clear()
      ..addAll(photos);
  }

  @override
  Future<void> persistPhotos(List<Photo> photos) async {
    _photos
      ..clear()
      ..addAll(photos);
  }

  @override
  Future<void> writeExifForPhotos(List<Photo> photos) async {}
}

void main() {
  group('GeotaggingController', () {
    Future<void> waitForLoad(GeotaggingController controller) async {
      while (!controller.hasCompletedInitialLoad) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    }

    test('hasSelectedPhotosWithLocation returns false when no selection',
        () async {
      const location = LocationInfo(latitude: 48.8, longitude: 2.3);
      final photos = [
        Photo(
          id: '1',
          title: 'photo1',
          takenAt: DateTime(2024, 1, 1),
          location: location,
        ),
      ];
      final repo = FakePhotoRepository(initialPhotos: photos);
      final controller = GeotaggingController(repo);
      await waitForLoad(controller);

      expect(controller.hasSelectedPhotosWithLocation, isFalse);
      controller.dispose();
    });

    test('hasSelectedPhotosWithLocation returns false when selected has no location',
        () async {
      final photos = [
        Photo(
          id: '1',
          title: 'photo1',
          takenAt: DateTime(2024, 1, 1),
        ),
      ];
      final repo = FakePhotoRepository(initialPhotos: photos);
      final controller = GeotaggingController(repo);
      await waitForLoad(controller);

      controller.toggleMultiSelectMode();
      controller.togglePhotoSelection('1');

      expect(controller.hasSelectedPhotosWithLocation, isFalse);
      controller.dispose();
    });

    test('hasSelectedPhotosWithLocation returns true when selected has location',
        () async {
      const location = LocationInfo(latitude: 48.8, longitude: 2.3);
      final photos = [
        Photo(
          id: '1',
          title: 'photo1',
          takenAt: DateTime(2024, 1, 1),
          location: location,
        ),
      ];
      final repo = FakePhotoRepository(initialPhotos: photos);
      final controller = GeotaggingController(repo);
      await waitForLoad(controller);

      controller.toggleMultiSelectMode();
      controller.togglePhotoSelection('1');

      expect(controller.hasSelectedPhotosWithLocation, isTrue);
      controller.dispose();
    });

    test('exportPhotosWithExistingLocation returns ExportPhotosNoLocation when none have location',
        () async {
      final photos = [
        Photo(
          id: '1',
          title: 'photo1',
          takenAt: DateTime(2024, 1, 1),
        ),
      ];
      final repo = FakePhotoRepository(initialPhotos: photos);
      final controller = GeotaggingController(repo);
      await waitForLoad(controller);

      controller.toggleMultiSelectMode();
      controller.togglePhotoSelection('1');

      final result = await controller.exportPhotosWithExistingLocation();

      expect(result, isA<ExportPhotosNoLocation>());
      controller.dispose();
    });
  });
}
