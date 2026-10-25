import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salon_app/theme/salon_theme.dart';

void main() {
  testWidgets('Primary booking action meets a readable touch target', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: SalonTheme.light,
      home: Scaffold(
        body: Center(child: ElevatedButton(
          onPressed: () {}, child: const Text('Book a service'))),
      ),
    ));

    final button = tester.getSize(find.byType(ElevatedButton));
    expect(button.height, greaterThanOrEqualTo(48));
    expect(find.text('Book a service'), findsOneWidget);
  });
}
