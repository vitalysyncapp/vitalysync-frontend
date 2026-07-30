import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalysync/features/auth/presentation/pages/auth_start_page.dart';
import 'package:vitalysync/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:vitalysync/features/auth/presentation/pages/login_page.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(configureTestAssets);
  tearDownAll(clearTestAssets);

  testWidgets('forgot password completes email, code, and password stages', (
    tester,
  ) async {
    String? requestedEmail;
    String? verifiedCode;
    String? submittedPassword;
    var resetCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: ForgotPasswordPage(
          resendCooldown: Duration.zero,
          requestPasswordReset: (email) async {
            requestedEmail = email;
            return 'A password reset code has been sent.';
          },
          verifyPasswordResetCode: (email, code) async {
            expect(email, 'student@example.com');
            verifiedCode = code;
            return 'opaque-reset-grant';
          },
          confirmPasswordReset: (token, password, confirmation) async {
            expect(token, 'opaque-reset-grant');
            expect(confirmation, password);
            submittedPassword = password;
            return 'Password reset successfully.';
          },
          resetSession: () async => resetCount++,
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextFormField), ' Student@Example.COM ');
    await tester.tap(find.byKey(const ValueKey('send-reset-code-button')));
    await tester.pump();

    expect(requestedEmail, 'student@example.com');
    expect(find.text('Reset code sent'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1900));
    await tester.enterText(
      find.byKey(const ValueKey('verification-code-field')),
      '123456',
    );
    await tester.tap(find.byKey(const ValueKey('verify-reset-code-button')));
    await tester.pump();

    expect(verifiedCode, '123456');
    expect(find.text('Choose a new password'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('new-password-field')),
      'newsecret',
    );
    await tester.enterText(
      find.byKey(const ValueKey('confirm-password-field')),
      'newsecret',
    );
    await tester.tap(
      find.byKey(const ValueKey('confirm-password-reset-button')),
    );
    await tester.pump();

    expect(submittedPassword, 'newsecret');
    expect(find.text('Password changed'), findsWidgets);

    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pump(const Duration(milliseconds: 300));

    expect(resetCount, 1);
    expect(find.byType(AuthStartPage), findsOneWidget);
  });

  testWidgets('forgot password validates email and supports code resend', (
    tester,
  ) async {
    var requestCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: ForgotPasswordPage(
          resendCooldown: Duration.zero,
          requestPasswordReset: (_) async {
            requestCount++;
            return 'Code sent.';
          },
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextFormField), 'bad-email');
    await tester.tap(find.byKey(const ValueKey('send-reset-code-button')));
    await tester.pump();

    expect(requestCount, 0);
    expect(find.text('Check your email'), findsOneWidget);
    expect(find.text('Enter a valid email'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1600));
    await tester.enterText(find.byType(TextFormField), 'student@example.com');
    await tester.tap(find.byKey(const ValueKey('send-reset-code-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1900));

    await tester.tap(find.byKey(const ValueKey('resend-reset-code-button')));
    await tester.pump();
    expect(requestCount, 2);
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
    expect(find.text('Send reset code'), findsOneWidget);
  });
}
