import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:geotag/src/features/geotagging/domain/entities/photo.dart';
import 'package:geotag/src/features/geotagging/presentation/widgets/photo_grid/photo_preview.dart';

void main() {
  group('PhotoPreview', () {
    testWidgets('shows placeholder when imagePath is null',
        (WidgetTester tester) async {
      final photo = Photo(
        id: '1',
        title: 'no-path.jpg',
        takenAt: DateTime(2024, 1, 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoPreview(photo: photo),
          ),
        ),
      );

      expect(find.byIcon(Icons.photo), findsOneWidget);
    });

    testWidgets('shows placeholder for non-existent RAW path',
        (WidgetTester tester) async {
      final photo = Photo(
        id: '1',
        title: 'missing.arw',
        takenAt: DateTime(2024, 1, 1),
        imagePath: '/nonexistent/path/photo_${DateTime.now().millisecondsSinceEpoch}.arw',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoPreview(photo: photo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.photo), findsOneWidget);
    });

    testWidgets('shows placeholder while loading RAW thumbnail',
        (WidgetTester tester) async {
      final photo = Photo(
        id: '1',
        title: 'loading.arw',
        takenAt: DateTime(2024, 1, 1),
        imagePath: '/nonexistent/loading_${DateTime.now().millisecondsSinceEpoch}.arw',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoPreview(photo: photo),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.photo), findsOneWidget);
    });

    testWidgets('uses ClipRRect for rounded corners', (WidgetTester tester) async {
      final photo = Photo(
        id: '1',
        title: 'x.jpg',
        takenAt: DateTime(2024, 1, 1),
        imagePath: '/nonexistent/any.jpg',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoPreview(photo: photo),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ClipRRect), findsOneWidget);
    });
  });
}
