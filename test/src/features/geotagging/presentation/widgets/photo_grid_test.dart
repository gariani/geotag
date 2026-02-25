import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:geotag/src/features/geotagging/domain/entities/location_info.dart';
import 'package:geotag/src/features/geotagging/domain/entities/photo.dart';
import 'package:geotag/src/features/geotagging/domain/repositories/photo_repository.dart';
import 'package:geotag/src/features/geotagging/presentation/controllers/geotagging_controller.dart';
import 'package:geotag/src/features/geotagging/presentation/widgets/photo_grid.dart';

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
}

void main() {
  group('PhotoGrid', () {
    testWidgets('shows static header and empty state when no photos',
        (WidgetTester tester) async {
      final repo = FakePhotoRepository();
      final controller = GeotaggingController(repo);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoGrid(
              controller: controller,
              onSetLocationPressed: () {},
              onExportCopiesPressed: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Photos'), findsOneWidget);
      expect(find.text('No photos yet'), findsOneWidget);
      expect(find.text('Import'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('grid uses 3 columns and smaller tiles', (WidgetTester tester) async {
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
        ),
      ];
      final repo = FakePhotoRepository(initialPhotos: photos);
      final controller = GeotaggingController(repo);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoGrid(
              controller: controller,
              onSetLocationPressed: () {},
              onExportCopiesPressed: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate = gridView.gridDelegate;
      expect(delegate, isA<SliverGridDelegateWithFixedCrossAxisCount>());
      final fixedDelegate = delegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(fixedDelegate.crossAxisCount, 3);
      expect(fixedDelegate.childAspectRatio, 1.15);

      controller.dispose();
    });

    testWidgets('shows static footer when photos are selected',
        (WidgetTester tester) async {
      final photos = [
        Photo(
          id: '1',
          title: 'photo1',
          takenAt: DateTime(2024, 1, 1),
        ),
      ];
      final repo = FakePhotoRepository(initialPhotos: photos);
      final controller = GeotaggingController(repo);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: controller,
              builder: (context, _) => PhotoGrid(
                controller: controller,
                onSetLocationPressed: () {},
                onExportCopiesPressed: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Set Location for 1 selected'), findsNothing);

      controller.toggleMultiSelectMode();
      controller.togglePhotoSelection('1');
      await tester.pumpAndSettle();

      expect(find.text('Set Location for 1 selected'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('Export button enabled only when selected photos have location',
        (WidgetTester tester) async {
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

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: controller,
              builder: (context, _) => PhotoGrid(
                controller: controller,
                onSetLocationPressed: () {},
                onExportCopiesPressed: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      controller.toggleMultiSelectMode();
      controller.togglePhotoSelection('1');
      await tester.pumpAndSettle();

      var exportInkWell = tester.widget<InkWell>(
        find.ancestor(
          of: find.text('Export'),
          matching: find.byType(InkWell),
        ),
      );
      expect(exportInkWell.onTap, isNull);

      controller.togglePhotoSelection('2');
      await tester.pumpAndSettle();

      exportInkWell = tester.widget<InkWell>(
        find.ancestor(
          of: find.text('Export'),
          matching: find.byType(InkWell),
        ),
      );
      expect(exportInkWell.onTap, isNotNull);

      controller.dispose();
    });
  });
}
