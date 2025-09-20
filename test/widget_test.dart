import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:healthmap_ai/main.dart';

void main() {
  testWidgets('HealthMap app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HealthMapApp());

    // Verify that the app loads
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}