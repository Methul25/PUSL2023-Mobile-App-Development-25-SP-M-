import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furn_app/screens/login_screen.dart';

void main() {
  testWidgets('Login screen renders FURN title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LoginScreen()),
    );

    expect(find.text('FURN'), findsOneWidget);
    expect(find.text('FURNITURE STORE'), findsOneWidget);
    expect(find.text('PROCEED'), findsOneWidget);
  });
}
