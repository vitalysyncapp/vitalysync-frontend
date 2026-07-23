import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalysync/features/settings/presentation/pages/privacy_security_page.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('privacy security shows resend for unverified email', (
    tester,
  ) async {
    configureLoggedInSession(emailVerified: false);

    await tester.pumpWidget(const MaterialApp(home: PrivacySecurityPage()));
    await tester.pump();

    expect(find.text('Email verification'), findsOneWidget);
    expect(find.text('Not verified - tester@example.com'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('resend-email-verification-button')),
      findsOneWidget,
    );
  });

  testWidgets('privacy security hides resend for verified email', (
    tester,
  ) async {
    configureLoggedInSession(emailVerified: true);

    await tester.pumpWidget(const MaterialApp(home: PrivacySecurityPage()));
    await tester.pump();

    expect(find.text('Verified - tester@example.com'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('resend-email-verification-button')),
      findsNothing,
    );
  });
}
