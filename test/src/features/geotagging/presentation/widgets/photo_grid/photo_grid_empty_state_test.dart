import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:geotag/src/features/geotagging/presentation/widgets/photo_grid/photo_grid_empty_state.dart';

void main() {
  group('PhotoGridEmptyState', () {
    testWidgets('displays no photos message', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoGridEmptyState(
              isLoading: false,
              onImport: () {},
            ),
          ),
        ),
      );
      expect(find.text('No photos yet'), findsOneWidget);
      expect(find.text('Import photos to start tagging locations.'), findsOneWidget);
    });

    testWidgets('shows Import photos button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoGridEmptyState(
              isLoading: false,
              onImport: () {},
            ),
          ),
        ),
      );
      expect(find.text('Import photos'), findsOneWidget);
    });

    testWidgets('calls onImport when button tapped', (WidgetTester tester) async {
      var importCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoGridEmptyState(
              isLoading: false,
              onImport: () => importCalled = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Import photos'));
      await tester.pump();
      expect(importCalled, isTrue);
    });

    testWidgets('disables button when loading', (WidgetTester tester) async {
      var importCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoGridEmptyState(
              isLoading: true,
              onImport: () => importCalled = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Import photos'));
      await tester.pump();
      expect(importCalled, isFalse);
    });
  });
}
