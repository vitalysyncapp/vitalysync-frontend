import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/app/app.dart';
import 'package:vitalysync/features/activity/data/activity_service.dart';

import 'test_helpers.dart';

Future<void> pumpStartup(WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(configureTestAssets);
  tearDownAll(clearTestAssets);

  testWidgets('shows the auth start page when no saved session exists', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await pumpStartup(tester);

    expect(find.text('Your gentle wellness companion'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);

    await tester.ensureVisible(find.text('Log in'));
    await tester.pump();
    await tester.tap(find.text('Log in'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('returns to auth start when a saved session has no token', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'email': 'tester@example.com',
      'user_id': 1,
      'username': 'Tester',
      'onboarding_completed': true,
    });

    await pumpStartup(tester);

    expect(find.text('Your gentle wellness companion'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);

    await tester.ensureVisible(find.text('Sign up'));
    await tester.pump();
    await tester.tap(find.text('Sign up'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Create your Account'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
  });

  testWidgets('uses cached completed session to enter the main app quickly', (
    WidgetTester tester,
  ) async {
    configureLoggedInSession(onboardingCompleted: true);

    await pumpStartup(tester);

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Log'), findsOneWidget);
    expect(find.text('Nutrition'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await ActivityService.instance.disposeTracking();
  });

  testWidgets('uses cached incomplete session to continue onboarding quickly', (
    WidgetTester tester,
  ) async {
    configureLoggedInSession(onboardingCompleted: false);

    await pumpStartup(tester);

    expect(find.text('What best describes you?'), findsWidgets);
    expect(find.text('Next'), findsOneWidget);
  });
}
