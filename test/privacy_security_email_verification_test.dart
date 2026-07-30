import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalysync/features/settings/presentation/pages/privacy_security_page.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('privacy security opens the code verification flow', (
    tester,
  ) async {
    configureLoggedInSession(emailVerified: false);

    await tester.pumpWidget(const MaterialApp(home: PrivacySecurityPage()));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('Email verification'), findsOneWidget);
    expect(find.text('Not verified - tester@example.com'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('open-email-verification-button')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('open-email-verification-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('email-verification-page-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('verification-code-field')),
      findsOneWidget,
    );
  });

  testWidgets('privacy security hides resend for verified email', (
    tester,
  ) async {
    configureLoggedInSession(emailVerified: true);

    await tester.pumpWidget(const MaterialApp(home: PrivacySecurityPage()));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('Verified - tester@example.com'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('open-email-verification-button')),
      findsNothing,
    );
  });
}
