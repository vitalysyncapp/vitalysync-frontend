import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalysync/features/auth/presentation/pages/email_verification_page.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('email verification page sends and shows confirmation guidance', (
    tester,
  ) async {
    configureLoggedInSession(emailVerified: false);
    var sendCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: EmailVerificationPage(
          sendVerificationEmail: () async {
            sendCount++;
            return 'sent';
          },
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Verify your email'), findsOneWidget);
    expect(find.text('tester@example.com'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('send-email-verification-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(sendCount, 1);
    expect(find.text('Email has been sent'), findsOneWidget);
    expect(
      find.textContaining('We sent a verification link to tester@example.com'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('email-verification-sent-guidance')),
      findsOneWidget,
    );
  });

  testWidgets(
    'email verification page disables sending for verified accounts',
    (tester) async {
      configureLoggedInSession(emailVerified: true);

      await tester.pumpWidget(const MaterialApp(home: EmailVerificationPage()));
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.byKey(const ValueKey('send-email-verification-button')),
      );

      expect(find.text('Email verified'), findsOneWidget);
      expect(button.onPressed, isNull);
    },
  );
}
