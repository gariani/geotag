import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:geotag/src/features/geotagging/presentation/widgets/photo_grid/primary_action_button.dart';

void main() {
  group('PrimaryActionButton', () {
    testWidgets('displays label and icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryActionButton(
              icon: Icons.add,
              label: 'Add Item',
              enabled: true,
              onPressed: () {},
            ),
          ),
        ),
      );
      expect(find.text('Add Item'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('calls onPressed when enabled and tapped',
        (WidgetTester tester) async {
      var pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryActionButton(
              icon: Icons.add,
              label: 'Add',
              enabled: true,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Add'));
      await tester.pump();
      expect(pressed, isTrue);
    });

    testWidgets('does not call onPressed when disabled',
        (WidgetTester tester) async {
      var pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryActionButton(
              icon: Icons.add,
              label: 'Add',
              enabled: false,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Add'));
      await tester.pump();
      expect(pressed, isFalse);
    });
  });
}
