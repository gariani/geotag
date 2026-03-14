import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:geotag/src/core/widgets/splash_screen.dart';

void main() {
  group('SplashScreen', () {
    testWidgets('displays GeoTag title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(),
        ),
      );
      expect(find.text('GeoTag'), findsOneWidget);
    });

    testWidgets('displays tagline', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(),
        ),
      );
      expect(find.text('CAPTURE THE MOMENT'), findsOneWidget);
    });

    testWidgets('displays loading indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays loading text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(),
        ),
      );
      expect(find.text('LOADING...'), findsOneWidget);
    });

    testWidgets('displays map pin icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(),
        ),
      );
      expect(find.byIcon(Icons.place), findsOneWidget);
    });
  });
}
