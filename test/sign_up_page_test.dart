import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/features/auth/presentation/pages/sign_up_page.dart';
import 'package:vitalysync/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:vitalysync/shared/preferences/session_expiration_coordinator.dart';
import 'package:vitalysync/shared/widgets/validation_dialog.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(configureTestAssets);
  tearDownAll(clearTestAssets);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => SessionExpirationCoordinator.instance.detach());

  testWidgets('successful signup opens onboarding without a success dialog', (
    tester,
  ) async {
    var requests = 0;
    await http.runWithClient(
      () async {
        await _submitSignUp(tester);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(requests, 1);
        expect(find.byType(ValidationDialog), findsNothing);
        expect(find.byType(OnboardingPage), findsOneWidget);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('user_id'), 1);
        expect(prefs.getString('auth_access_token'), isNotEmpty);
        expect(tester.takeException(), isNull);
      SessionExpirationCoordinator.instance.detach();
        await tester.pumpWidget(const SizedBox.shrink());
      },
      () => MockClient((_) async {
        requests++;
        return _successResponse();
      }),
    );
  });

  testWidgets('leaving during signup ignores the late response safely', (
    tester,
  ) async {
    final response = Completer<http.Response>();
    var requests = 0;
    await http.runWithClient(
      () async {
        await _submitSignUp(tester);
        await tester.pump();
        expect(requests, 1);

        await tester.pumpWidget(const MaterialApp(home: Text('Other screen')));
        response.complete(_successResponse());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(find.text('Other screen'), findsOneWidget);
        expect(find.byType(OnboardingPage), findsNothing);
        expect(find.byType(ValidationDialog), findsNothing);
        expect(tester.takeException(), isNull);
      },
      () => MockClient((_) {
        requests++;
        return response.future;
      }),
    );
  });

  testWidgets('missing signup token shows an error and allows retry', (
    tester,
  ) async {
    await http.runWithClient(() async {
      await _submitSignUp(tester);
      await tester.pump();
      expect(find.byType(ValidationDialog), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 350));

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Create account'),
      );
      expect(button.onPressed, isNotNull);
      expect(find.byType(OnboardingPage), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }, () => MockClient((_) async => http.Response('{}', 201)));
  });
}

http.Response _successResponse() => http.Response(
  jsonEncode({
    'access_token': testAuthToken(),
    'user': {
      'user_id': 1,
      'username': 'Student',
      'email': 'student@example.com',
      'onboarding_completed': false,
    },
  }),
  201,
);

Future<void> _submitSignUp(WidgetTester tester) async {
  await pumpTestApp(tester, const SignUpPage());
  for (final field in {
    'signup-email-field': 'student@example.com',
    'signup-username-field': 'Student',
    'signup-age-field': '21',
    'signup-password-field': 'secret123',
    'signup-confirm-password-field': 'secret123',
  }.entries) {
    await tester.enterText(find.byKey(ValueKey(field.key)), field.value);
  }

  final gender = find.byType(DropdownButtonFormField<String>);
  await tester.ensureVisible(gender);
  await tester.tap(gender);
  await tester.pump(const Duration(milliseconds: 350));
  await tester.tap(find.text('Other').last);
  await tester.pump(const Duration(milliseconds: 350));
  await tester.ensureVisible(find.byType(Checkbox));
  await tester.tap(find.byType(Checkbox));
  await tester.pump();

  final createButton = find.widgetWithText(ElevatedButton, 'Create account');
  await tester.ensureVisible(createButton);
  await tester.pump();
  await tester.tap(createButton);
}
