import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:geotag/src/features/geotagging/presentation/widgets/photo_grid/filter_tab.dart';

void main() {
  group('FilterTab', () {
    testWidgets('displays label', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterTab(
              label: 'Test Filter',
              isSelected: false,
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.text('Test Filter'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterTab(
              label: 'Tap Me',
              isSelected: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap Me'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('shows underline when selected', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterTab(
              label: 'Selected',
              isSelected: true,
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.byType(Container), findsWidgets);
    });
  });
}
