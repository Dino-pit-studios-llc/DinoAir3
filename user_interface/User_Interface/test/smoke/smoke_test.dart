import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('smoke renders a simple Container', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(width: 100, height: 100),
          ),
        ),
      ),
    );

    expect(find.byType(SizedBox), findsOneWidget);
  });
}
