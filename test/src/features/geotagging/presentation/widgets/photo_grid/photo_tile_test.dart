import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:geotag/src/features/geotagging/domain/entities/location_info.dart';
import 'package:geotag/src/features/geotagging/domain/entities/photo.dart';
import 'package:geotag/src/features/geotagging/presentation/widgets/photo_grid/photo_tile.dart';

void main() {
  group('PhotoTile', () {
    testWidgets('displays photo title', (WidgetTester tester) async {
      final photo = Photo(
        id: '1',
        title: 'vacation.jpg',
        takenAt: DateTime(2024, 1, 1),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoTile(
              photo: photo,
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.text('vacation.jpg'), findsOneWidget);
    });

    testWidgets('shows Location set when photo has location',
        (WidgetTester tester) async {
      const location = LocationInfo(latitude: 48.8, longitude: 2.3);
      final photo = Photo(
        id: '1',
        title: 'x.jpg',
        takenAt: DateTime(2024, 1, 1),
        location: location,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoTile(
              photo: photo,
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.text('Location set'), findsOneWidget);
    });

    testWidgets('shows No location when photo has no location',
        (WidgetTester tester) async {
      final photo = Photo(
        id: '1',
        title: 'x.jpg',
        takenAt: DateTime(2024, 1, 1),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoTile(
              photo: photo,
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.text('No location'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
      final photo = Photo(
        id: '1',
        title: 'x.jpg',
        takenAt: DateTime(2024, 1, 1),
      );
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoTile(
              photo: photo,
              isSelected: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(PhotoTile));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('calls onLongPress when long pressed', (WidgetTester tester) async {
      final photo = Photo(
        id: '1',
        title: 'x.jpg',
        takenAt: DateTime(2024, 1, 1),
      );
      var longPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoTile(
              photo: photo,
              isSelected: false,
              onTap: () {},
              onLongPress: () => longPressed = true,
            ),
          ),
        ),
      );
      await tester.longPress(find.byType(PhotoTile));
      await tester.pump();
      expect(longPressed, isTrue);
    });

    testWidgets('shows check icon when selected', (WidgetTester tester) async {
      final photo = Photo(
        id: '1',
        title: 'x.jpg',
        takenAt: DateTime(2024, 1, 1),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoTile(
              photo: photo,
              isSelected: true,
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });
}
