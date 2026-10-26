import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:salon_app/theme/salon_theme.dart';
import 'package:salon_app/screens/auth/login_screen.dart';
import 'package:salon_app/screens/auth/signup_screen.dart';
import 'package:salon_app/services/auth_service.dart';

void main() {
  test('Network authentication errors have a useful message', () {
    final message = AuthService.errorMessage(
      FirebaseAuthException(code: 'network-request-failed'),
    );
    expect(message, contains('Check your internet connection'));
    expect(message, isNot(contains('Exception')));
  });

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

  testWidgets('Password reset asks for a valid email', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: SalonTheme.light,
      home: const LoginScreen(),
    ));

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(find.text('Reset your password'), findsOneWidget);

    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter your email'), findsOneWidget);
  });

  testWidgets('Owner sign-in explains account access', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: SalonTheme.light,
      home: const LoginScreen(),
    ));

    expect(find.text('Customer'), findsOneWidget);
    await tester.tap(find.text('Salon owner'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Owner access is verified automatically'), findsOneWidget);
    expect(find.textContaining("Don't have an account?"), findsNothing);
    expect(find.text('Need an owner account? Request access'), findsOneWidget);
  });

  testWidgets('Signup lets an owner submit an approval request', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: SalonTheme.light,
      home: const SignupScreen(),
    ));

    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Salon owner'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);

    await tester.tap(find.text('Salon owner'));
    await tester.pumpAndSettle();
    expect(find.text('Full Name'), findsOneWidget);
    expect(
      find.text('Create an owner request. An existing admin must approve it.'),
      findsOneWidget,
    );
    expect(find.text('REQUEST OWNER ACCOUNT'), findsOneWidget);
  });
}
