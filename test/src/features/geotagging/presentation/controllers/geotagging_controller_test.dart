import 'package:flutter_test/flutter_test.dart';

import 'package:geotag/src/features/geotagging/domain/entities/location_info.dart';
import 'package:geotag/src/features/geotagging/domain/entities/photo.dart';
import 'package:geotag/src/features/geotagging/domain/repositories/photo_repository.dart';
import 'package:geotag/src/features/geotagging/presentation/controllers/export_photos_result.dart';
import 'package:geotag/src/features/geotagging/presentation/controllers/geotagging_controller.dart';
import 'package:geotag/src/features/geotagging/presentation/controllers/photo_filter.dart';

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

    test('hasLocation filter returns only photos with location', () async {
      const location = LocationInfo(latitude: 48.8, longitude: 2.3);
      final photos = [
        Photo(
          id: '1',
          title: 'photo1',
          takenAt: DateTime(2024, 1, 1),
        ),
        Photo(
          id: '2',
          title: 'photo2',
          takenAt: DateTime(2024, 1, 2),
          location: location,
        ),
      ];
      final repo = FakePhotoRepository(initialPhotos: photos);
      final controller = GeotaggingController(repo);
      await waitForLoad(controller);

      controller.setFilter(PhotoFilter.hasLocation);

      expect(controller.photos.length, 1);
      expect(controller.photos.first.id, '2');
      expect(controller.photos.first.location, isNotNull);
      controller.dispose();
    });

    test('all filter returns all photos', () async {
      final photos = [
        Photo(id: '1', title: 'a', takenAt: DateTime(2024, 1, 1)),
        Photo(id: '2', title: 'b', takenAt: DateTime(2024, 1, 2)),
      ];
      final repo = FakePhotoRepository(initialPhotos: photos);
      final controller = GeotaggingController(repo);
      await waitForLoad(controller);

      controller.setFilter(PhotoFilter.all);

      expect(controller.photos.length, 2);
      controller.dispose();
    });

    test('missingLocation filter returns only photos without location',
        () async {
      const location = LocationInfo(latitude: 48.8, longitude: 2.3);
      final photos = [
        Photo(id: '1', title: 'a', takenAt: DateTime(2024, 1, 1)),
        Photo(
          id: '2',
          title: 'b',
          takenAt: DateTime(2024, 1, 2),
          location: location,
        ),
      ];
      final repo = FakePhotoRepository(initialPhotos: photos);
      final controller = GeotaggingController(repo);
      await waitForLoad(controller);

      controller.setFilter(PhotoFilter.missingLocation);

      expect(controller.photos.length, 1);
      expect(controller.photos.first.id, '1');
      controller.dispose();
    });

    test('recent filter returns at most 50 photos sorted by takenAt descending',
        () async {
      final photos = List.generate(
        60,
        (i) => Photo(
          id: '$i',
          title: 'p$i',
          takenAt: DateTime(2024, 1, 1).add(Duration(days: i)),
        ),
      );
      final repo = FakePhotoRepository(initialPhotos: photos);
      final controller = GeotaggingController(repo);
      await waitForLoad(controller);

      controller.setFilter(PhotoFilter.recent);

      expect(controller.photos.length, 50);
      expect(controller.photos.first.takenAt.isAfter(
        controller.photos.last.takenAt,
      ), isTrue);
      controller.dispose();
    });

    test('setFilter updates filter', () async {
      final repo = FakePhotoRepository();
      final controller = GeotaggingController(repo);
      await waitForLoad(controller);

      expect(controller.filter, PhotoFilter.all);
      controller.setFilter(PhotoFilter.missingLocation);
      expect(controller.filter, PhotoFilter.missingLocation);
      controller.dispose();
    });

    test('togglePhotoSelection in single mode keeps at most one', () async {
      final photos = [
        Photo(id: '1', title: 'a', takenAt: DateTime(2024, 1, 1)),
        Photo(id: '2', title: 'b', takenAt: DateTime(2024, 1, 2)),
      ];
      final repo = FakePhotoRepository(initialPhotos: photos);
      final controller = GeotaggingController(repo);
      await waitForLoad(controller);

      controller.togglePhotoSelection('1');
      expect(controller.selectedPhotoIds, {'1'});

      controller.togglePhotoSelection('2');
      expect(controller.selectedPhotoIds, {'2'});

      controller.togglePhotoSelection('2');
      expect(controller.selectedPhotoIds, isEmpty);

      controller.dispose();
    });

    test('togglePhotoSelection in multi mode allows multiple', () async {
      final photos = [
        Photo(id: '1', title: 'a', takenAt: DateTime(2024, 1, 1)),
        Photo(id: '2', title: 'b', takenAt: DateTime(2024, 1, 2)),
      ];
      final repo = FakePhotoRepository(initialPhotos: photos);
      final controller = GeotaggingController(repo);
      await waitForLoad(controller);

      controller.toggleMultiSelectMode();
      controller.togglePhotoSelection('1');
      controller.togglePhotoSelection('2');
      expect(controller.selectedPhotoIds, {'1', '2'});

      controller.togglePhotoSelection('1');
      expect(controller.selectedPhotoIds, {'2'});
      controller.dispose();
    });

    test('clearSelection empties selection', () async {
      final photos = [
        Photo(id: '1', title: 'a', takenAt: DateTime(2024, 1, 1)),
      ];
      final repo = FakePhotoRepository(initialPhotos: photos);
      final controller = GeotaggingController(repo);
      await waitForLoad(controller);

      controller.togglePhotoSelection('1');
      expect(controller.selectedPhotoIds, isNotEmpty);

      controller.clearSelection();
      expect(controller.selectedPhotoIds, isEmpty);
      controller.dispose();
    });

    test('setLocation updates selectedLocation', () async {
      final repo = FakePhotoRepository();
      final controller = GeotaggingController(repo);
      await waitForLoad(controller);

      expect(controller.selectedLocation, isNull);

      const location = LocationInfo(latitude: 51.5, longitude: -0.1);
      controller.setLocation(location);
      expect(controller.selectedLocation, location);
      controller.dispose();
    });

    test('toggleMultiSelectMode when leaving clears to one if multiple selected',
        () async {
      final photos = [
        Photo(id: '1', title: 'a', takenAt: DateTime(2024, 1, 1)),
        Photo(id: '2', title: 'b', takenAt: DateTime(2024, 1, 2)),
      ];
      final repo = FakePhotoRepository(initialPhotos: photos);
      final controller = GeotaggingController(repo);
      await waitForLoad(controller);

      controller.toggleMultiSelectMode();
      controller.togglePhotoSelection('1');
      controller.togglePhotoSelection('2');
      expect(controller.selectedPhotoIds.length, 2);

      controller.toggleMultiSelectMode();
      expect(controller.selectedPhotoIds.length, 1);
      controller.dispose();
    });

    test('applyLocationToSelection updates photos and clears selection',
        () async {
      const location = LocationInfo(latitude: 48.8, longitude: 2.3);
      final photos = [
        Photo(id: '1', title: 'a', takenAt: DateTime(2024, 1, 1)),
      ];
      final repo = FakePhotoRepository(initialPhotos: photos);
      final controller = GeotaggingController(repo);
      await waitForLoad(controller);

      controller.setLocation(location);
      controller.togglePhotoSelection('1');
      final result = await controller.applyLocationToSelection();

      expect(result, isTrue);
      expect(controller.selectedPhotoIds, isEmpty);
      expect(controller.photos.first.location, location);
      controller.dispose();
    });

    test('applyLocationToSelection returns false when no selection', () async {
      const location = LocationInfo(latitude: 48.8, longitude: 2.3);
      final photos = [
        Photo(id: '1', title: 'a', takenAt: DateTime(2024, 1, 1)),
      ];
      final repo = FakePhotoRepository(initialPhotos: photos);
      final controller = GeotaggingController(repo);
      await waitForLoad(controller);

      controller.setLocation(location);
      final result = await controller.applyLocationToSelection();

      expect(result, isFalse);
      controller.dispose();
    });

    test('applyLocationToSelection returns false when no location', () async {
      final photos = [
        Photo(id: '1', title: 'a', takenAt: DateTime(2024, 1, 1)),
      ];
      final repo = FakePhotoRepository(initialPhotos: photos);
      final controller = GeotaggingController(repo);
      await waitForLoad(controller);

      controller.togglePhotoSelection('1');
      final result = await controller.applyLocationToSelection();

      expect(result, isFalse);
      controller.dispose();
    });

    test('exported filter returns only photos without exportedAt', () async {
      final exportedAt = DateTime(2024, 1, 15);
      final photos = [
        Photo(
          id: '1',
          title: 'photo1',
          takenAt: DateTime(2024, 1, 1),
        ),
        Photo(
          id: '2',
          title: 'photo2',
          takenAt: DateTime(2024, 1, 2),
          exportedAt: exportedAt,
        ),
      ];
      final repo = FakePhotoRepository(initialPhotos: photos);
      final controller = GeotaggingController(repo);
      await waitForLoad(controller);

      controller.setFilter(PhotoFilter.exported);

      expect(controller.photos.length, 1);
      expect(controller.photos.first.id, '1');
      expect(controller.photos.first.exportedAt, isNull);
      controller.dispose();
    });
  });
}
