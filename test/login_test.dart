import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safety/main.dart';

void main() {
  testWidgets('Login rejects invalid credentials', (tester) async {
    await tester.pumpWidget(const SafetyApp());
    await tester.enterText(find.byType(TextField).first, 'wrong');
    await tester.enterText(find.byType(TextField).last, 'wrong');
    await tester.tap(find.text('Enter monitoring station →'));
    await tester.pump();
    expect(find.text('Incorrect official ID or password'), findsOneWidget);
    expect(find.text('Race overview'), findsNothing);
  });
}
