import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalysync/features/auth/data/email_validator.dart';
import 'package:vitalysync/features/auth/presentation/pages/sign_up_page.dart';
import 'package:vitalysync/features/profile/presentation/pages/edit_profile_page.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(configureTestAssets);
  tearDownAll(clearTestAssets);

  test('email validator accepts valid-looking addresses', () {
    expect(
      EmailValidator.validate(
        '  Student.Name+app@Example.COM  ',
        emptyMessage: 'Enter your email',
      ),
      isNull,
    );
    expect(
      EmailValidator.normalize('  Student.Name+app@Example.COM  '),
      'student.name+app@example.com',
    );
  });

  test('email validator rejects malformed addresses', () {
    const invalidEmails = [
      '',
      'student',
      'student@',
      '@example.com',
      'student@example',
      'student@@example.com',
      'student name@example.com',
      '.student@example.com',
      'student.@example.com',
      'student..name@example.com',
      'student@example..com',
      'student@-example.com',
    ];

    expect(
      EmailValidator.validate('', emptyMessage: 'Enter your email'),
      'Enter your email',
    );

    for (final email in invalidEmails.skip(1)) {
      expect(
        EmailValidator.validate(email, emptyMessage: 'Enter your email'),
        EmailValidator.invalidMessage,
      );
    }
  });

  testWidgets('signup rejects malformed email locally', (tester) async {
    await pumpTestApp(tester, const SignUpPage());

    await tester.enterText(find.byType(TextFormField).first, 'new@example');
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    final createButton = find.widgetWithText(ElevatedButton, 'Create account');
    await tester.ensureVisible(createButton);
    await tester.pump();
    final button = tester.widget<ElevatedButton>(createButton);
    expect(button.onPressed, isNotNull);
    button.onPressed!();
    await tester.pump();

    expect(find.text('Enter a valid email'), findsOneWidget);
  });

  testWidgets('edit profile rejects malformed email locally', (tester) async {
    var saved = false;

    await pumpTestApp(
      tester,
      EditProfilePage(
        initialUsername: 'Student',
        initialEmail: 'student@example.com',
        initialAge: 21,
        initialGender: 'Other',
        initialUserType: 'Student',
        onSave:
            ({
              required username,
              required email,
              required age,
              required gender,
              required userType,
            }) async {
              saved = true;
              return true;
            },
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(1), 'new@example');
    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pump();

    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(saved, isFalse);
  });
}
