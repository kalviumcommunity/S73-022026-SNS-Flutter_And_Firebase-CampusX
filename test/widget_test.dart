// This is a basic Flutter widget test for Campus Connect app.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campus_connect/app.dart';

void main() {
  testWidgets('App starts successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: CampusConnectApp(),
      ),
    );

    // Wait for any async operations to complete
    await tester.pumpAndSettle();

    // Verify that the app loads (this is a basic smoke test)
    expect(find.byType(CampusConnectApp), findsOneWidget);
  });
}
