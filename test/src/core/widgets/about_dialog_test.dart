import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:geotag/src/core/widgets/about_dialog.dart';

void main() {
  group('AboutDialog', () {
    testWidgets('shows dialog with GetTag title and OpenStreetMap links',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showAppAboutDialog(context),
                child: const Text('About'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();

      expect(find.text('About GetTag'), findsOneWidget);
      expect(find.text('OpenStreetMap'), findsWidgets);
      expect(find.text('Buy me a coffee'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });
  });
}
