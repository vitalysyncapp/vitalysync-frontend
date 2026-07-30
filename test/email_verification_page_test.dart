import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/features/auth/presentation/pages/email_verification_page.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('email verification sends and verifies a six-digit code', (
    tester,
  ) async {
    configureLoggedInSession(emailVerified: false);
    var sendCount = 0;
    String? verifiedCode;

    await tester.pumpWidget(
      MaterialApp(
        home: EmailVerificationPage(
          resendCooldown: Duration.zero,
          sendVerificationEmail: () async {
            sendCount++;
            return 'A verification code has been sent.';
          },
          verifyCode: (code) async {
            verifiedCode = code;
            return 'Email verified successfully.';
          },
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Verify your email'), findsOneWidget);
    expect(find.text('tester@example.com'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('verification-code-field')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('send-email-verification-button')),
    );
    await tester.pump();

    expect(sendCount, 1);
    expect(find.text('Verification code sent'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1900));
    await tester.enterText(
      find.byKey(const ValueKey('verification-code-field')),
      '123456',
    );
    await tester.tap(find.byKey(const ValueKey('verify-email-code-button')));
    await tester.pump();

    expect(verifiedCode, '123456');
    expect(find.text('Email verified'), findsWidgets);
    expect(find.text('Email verified successfully.'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1900));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('email_verified'), true);
    expect(
      find.byKey(const ValueKey('verify-email-code-button')),
      findsNothing,
    );
  });

  testWidgets('email verification hides code actions for verified accounts', (
    tester,
  ) async {
    configureLoggedInSession(emailVerified: true);

    await tester.pumpWidget(const MaterialApp(home: EmailVerificationPage()));
    await tester.pump();

    expect(find.text('Email verified'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('send-email-verification-button')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('verification-code-field')), findsNothing);
  });
}
