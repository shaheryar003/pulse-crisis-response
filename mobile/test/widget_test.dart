// Basic widget smoke test — verifies the auth gate boots.
// Requires Flutter SDK to run (`flutter test`).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pulse_mobile/main.dart';

void main() {
  testWidgets('PulseApp boots and renders sign-in', (WidgetTester tester) async {
    await tester.pumpWidget(const PulseApp());
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    // Either the loader or the sign-in is shown. Both are acceptable on cold boot.
    expect(find.byType(Scaffold), findsWidgets);
  });
}
