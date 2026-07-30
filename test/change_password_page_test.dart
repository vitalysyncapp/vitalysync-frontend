import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/features/auth/presentation/pages/auth_start_page.dart';
import 'package:vitalysync/features/settings/presentation/pages/change_password_page.dart';
import 'package:vitalysync/features/settings/presentation/pages/settings_page.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(configureTestAssets);
  tearDownAll(clearTestAssets);

  testWidgets(
    'change password submits verified and new passwords then signs out',
    (tester) async {
      String? currentPassword;
      String? newPassword;
      var resetCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: ChangePasswordPage(
            verifiedPassword: 'current-secret',
            changePassword: (current, next, confirmation) async {
              currentPassword = current;
              newPassword = next;
              expect(confirmation, next);
              return 'Password changed successfully.';
            },
            resetSession: () async {
              resetCount++;
            },
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(
        find.byKey(const ValueKey('new-password-field')),
        'new-secret',
      );
      await tester.enterText(
        find.byKey(const ValueKey('confirm-password-field')),
        'new-secret',
      );
      await tester.tap(
        find.byKey(const ValueKey('submit-change-password-button')),
      );
      await tester.pump();

      expect(currentPassword, 'current-secret');
      expect(newPassword, 'new-secret');
      expect(find.text('Password changed successfully.'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1900));
      await tester.pump(const Duration(milliseconds: 300));

      expect(resetCount, 1);
      expect(find.byType(AuthStartPage), findsOneWidget);
    },
  );

  testWidgets('change password requires matching confirmation', (tester) async {
    var submitCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ChangePasswordPage(
          verifiedPassword: 'current-secret',
          changePassword: (_, _, _) async {
            submitCount++;
            return 'changed';
          },
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(
      find.byKey(const ValueKey('new-password-field')),
      'new-secret',
    );
    await tester.enterText(
      find.byKey(const ValueKey('confirm-password-field')),
      'different',
    );
    await tester.tap(
      find.byKey(const ValueKey('submit-change-password-button')),
    );
    await tester.pump();

    expect(submitCount, 0);
    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('account settings includes the change password action', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
    await tester.pump();

    expect(find.text('Account settings'), findsOneWidget);
    expect(find.text('Change password'), findsOneWidget);
    expect(
      find.text('Update your password and sign out every device'),
      findsNothing,
    );
    expect(find.text('Sign in to change your password'), findsOneWidget);
  });
}
