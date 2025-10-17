import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('widget smoke builds MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('ok')),
        ),
      ),
    );

    // Bounded pump to avoid unbounded settling on web
    await tester.pump(const Duration(milliseconds: 1));

    expect(find.text('ok'), findsOneWidget);
  });
}
