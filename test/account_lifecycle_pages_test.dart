import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/features/settings/data/account_lifecycle_api.dart';
import 'package:vitalysync/features/auth/presentation/pages/reactivate_account_page.dart';
import 'package:vitalysync/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:vitalysync/features/settings/presentation/pages/clear_account_data_page.dart';
import 'package:vitalysync/features/settings/presentation/pages/deactivate_account_gate_page.dart';
import 'package:vitalysync/features/settings/presentation/pages/settings_page.dart';
import 'package:vitalysync/shared/preferences/user_session.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'user_id': 7,
      'email': 'student@example.com',
      'username': 'Student',
      'auth_access_token': 'access-token',
      'onboarding_completed': true,
      'email_verified': true,
    });
  });

  testWidgets('deactivation dialog requires password and exact CONFIRM', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: DeactivateAccountGatePage()),
    );

    ElevatedButton button() => tester.widget<ElevatedButton>(
      find.byKey(const ValueKey('deactivate-confirm-button')),
    );

    expect(button().onPressed, isNull);
    await tester.enterText(
      find.byKey(const ValueKey('deactivate-current-password')),
      'last-password',
    );
    await tester.pump();
    expect(button().onPressed, isNotNull);

    await tester.tap(find.byKey(const ValueKey('deactivate-confirm-button')));
    await tester.pumpAndSettle();

    TextButton dialogButton() => tester.widget<TextButton>(
      find.byKey(const ValueKey('deactivate-dialog-confirm-button')),
    );

    expect(dialogButton().onPressed, isNull);
    await tester.enterText(
      find.byKey(const ValueKey('deactivate-confirmation')),
      'confirm',
    );
    await tester.pump();
    expect(dialogButton().onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('deactivate-confirmation')),
      'CONFIRM',
    );
    await tester.pump();
    expect(dialogButton().onPressed, isNotNull);
    expect(find.textContaining('40 days'), findsWidgets);
    expect(find.textContaining('five years'), findsOneWidget);
  });

  testWidgets('clear-data dialog requires exact CONFIRM', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ClearAccountDataPage(verifiedPassword: 'last-password'),
      ),
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Clear account data'));
    await tester.pumpAndSettle();

    TextButton button() => tester.widget<TextButton>(
      find.byKey(const ValueKey('clear-data-confirm-button')),
    );

    expect(button().onPressed, isNull);
    await tester.enterText(
      find.byKey(const ValueKey('clear-data-confirmation')),
      'confirm',
    );
    await tester.pump();
    expect(button().onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('clear-data-confirmation')),
      'CONFIRM',
    );
    await tester.pump();
    expect(button().onPressed, isNotNull);
  });

  testWidgets('settings exposes deactivation and removes permanent deletion', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
    await tester.pumpAndSettle();

    expect(find.text('Deactivate account'), findsOneWidget);
    expect(find.text('Delete account'), findsNothing);
  });

  testWidgets('clear-data failure keeps the signed-in local session', (
    tester,
  ) async {
    final api = AccountLifecycleApi(
      client: MockClient(
        (_) async => http.Response('{"message":"Server clear failed"}', 500),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ClearAccountDataPage(verifiedPassword: 'last-password', api: api),
      ),
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Clear account data'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('clear-data-confirmation')),
      'CONFIRM',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('clear-data-confirm-button')));
    await tester.pumpAndSettle();

    expect(find.text('Server clear failed'), findsOneWidget);
    final session = await UserSessionController.instance.load();
    expect(session.isLoggedIn, isTrue);
  });

  testWidgets('reactivation confirmation restores the normal signed-in flow', (
    tester,
  ) async {
    final challenge = AccountReactivationChallenge(
      reactivationToken: 'grant',
      reactivationDeadline: DateTime.utc(2026, 9, 8),
      retentionExpiresAt: DateTime.utc(2031, 7, 30),
    );
    final api = AccountLifecycleApi(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'access_token': 'new-access-token',
            'user': {
              'user_id': 7,
              'username': 'Student',
              'email': 'student@example.com',
              'email_verified': true,
              'onboarding_completed': false,
            },
            'streak': {
              'current_streak': 0,
              'longest_streak': 0,
              'last_logged_date': null,
            },
          }),
          200,
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ReactivateAccountPage(challenge: challenge, api: api),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('reactivate-account-button')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(OnboardingPage), findsOneWidget);
    final session = await UserSessionController.instance.load();
    expect(session.authToken, 'new-access-token');
    expect(session.onboardingCompleted, isFalse);
  });
}
