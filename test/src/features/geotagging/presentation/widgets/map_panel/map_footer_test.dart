import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:geotag/src/features/geotagging/domain/entities/location_info.dart';
import 'package:geotag/src/features/geotagging/presentation/widgets/map_panel/map_footer.dart';

void main() {
  group('MapFooter', () {
    testWidgets('shows tap hint when no location', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapFooter(
              location: null,
              hasSelection: false,
              onApply: () async {},
              onApplyAndExport: () async {},
            ),
          ),
        ),
      );
      expect(find.text('Tap the map or search to set a pin'), findsOneWidget);
    });

    testWidgets('shows coordinates when location set', (WidgetTester tester) async {
      const location = LocationInfo(latitude: 48.8566, longitude: 2.3522);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapFooter(
              location: location,
              hasSelection: false,
              onApply: () async {},
              onApplyAndExport: () async {},
            ),
          ),
        ),
      );
      expect(find.textContaining('°'), findsWidgets);
      expect(find.textContaining("'"), findsWidgets);
    });

    testWidgets('shows label when location has label', (WidgetTester tester) async {
      const location = LocationInfo(
        latitude: 48.8566,
        longitude: 2.3522,
        label: 'Paris, France',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapFooter(
              location: location,
              hasSelection: false,
              onApply: () async {},
              onApplyAndExport: () async {},
            ),
          ),
        ),
      );
      expect(find.text('Paris, France'), findsOneWidget);
    });

    testWidgets('shows Apply to Selected and Apply & Export Copies buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapFooter(
              location: null,
              hasSelection: false,
              onApply: () async {},
              onApplyAndExport: () async {},
            ),
          ),
        ),
      );
      expect(find.text('Apply to Selected'), findsOneWidget);
      expect(find.text('Apply & Export Copies'), findsOneWidget);
    });

    testWidgets('enables Apply button when has selection and location',
        (WidgetTester tester) async {
      const location = LocationInfo(latitude: 48.8, longitude: 2.3);
      var applyCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapFooter(
              location: location,
              hasSelection: true,
              onApply: () async => applyCalled = true,
              onApplyAndExport: () async {},
            ),
          ),
        ),
      );
      await tester.tap(find.text('Apply to Selected'));
      await tester.pumpAndSettle();
      expect(applyCalled, isTrue);
    });
  });
}
