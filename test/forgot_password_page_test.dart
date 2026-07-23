import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalysync/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:vitalysync/features/auth/presentation/pages/login_page.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(configureTestAssets);
  tearDownAll(clearTestAssets);

  testWidgets('forgot password page sends a reset email request', (
    tester,
  ) async {
    String? requestedEmail;

    await tester.pumpWidget(
      MaterialApp(
        home: ForgotPasswordPage(
          requestPasswordReset: (email) async {
            requestedEmail = email;
            return 'If this email belongs to a VitalySync account, a password reset link has been sent.';
          },
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextFormField), ' Student@Example.COM ');
    await tester.tap(find.text('Send reset link'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(requestedEmail, 'student@example.com');
    expect(find.text('Reset email sent'), findsOneWidget);
    expect(
      find.textContaining('password reset link has been sent'),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 3000));

    expect(find.text('Send reset link again'), findsOneWidget);
  });

  testWidgets('forgot password page blocks invalid email locally', (
    tester,
  ) async {
    var requestCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: ForgotPasswordPage(
          requestPasswordReset: (_) async {
            requestCount++;
            return 'sent';
          },
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextFormField), 'bad-email');
    await tester.tap(find.text('Send reset link'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(requestCount, 0);
    expect(find.text('Check your email'), findsOneWidget);
    expect(find.text('Enter a valid email'), findsOneWidget);
  });

  testWidgets('login forgot password link opens reset request page', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey('login-forgot-password-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byKey(const ValueKey('forgot-password-page')), findsOneWidget);
    expect(find.text('Reset password'), findsOneWidget);
  });
}
