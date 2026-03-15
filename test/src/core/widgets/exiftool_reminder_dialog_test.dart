import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:geotag/src/core/widgets/exiftool_reminder_dialog.dart';

void main() {
  group('ExiftoolReminderOverlay', () {
    testWidgets('renders child', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ExiftoolReminderOverlay(
            child: Text('Child'),
          ),
        ),
      );
      expect(find.text('Child'), findsOneWidget);
    });
  });

  group('showExiftoolReminderDialog', () {
    testWidgets('shows exiftool message and don\'t show again checkbox',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showExiftoolReminderDialog(
                  context: context,
                  onDontShowAgain: (_) async {},
                ),
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('exiftool not found'), findsOneWidget);
      expect(find.text("Don't show this again"), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('OK closes dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showExiftoolReminderDialog(
                  context: context,
                  onDontShowAgain: (_) async {},
                ),
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();
      expect(find.text('OK'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('exiftool not found'), findsNothing);
    });
  });
}
