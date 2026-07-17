import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/app/app.dart';
import 'package:vitalysync/features/activity/data/activity_service.dart';
import 'package:vitalysync/features/tutorial/services/core_tutorial_replay_controller.dart';
import 'package:vitalysync/features/tutorial/services/core_tutorial_service.dart';

import 'test_helpers.dart';

Future<void> pumpStartup(WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 2500));
  await tester.pump();
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

    expect(
      find.text('Feel your rhythm before burnout gets loud'),
      findsOneWidget,
    );
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
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.text('Feel your rhythm before burnout gets loud'),
      findsOneWidget,
    );
    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);
    expect(
      tester.getRect(find.byKey(const ValueKey('auth-welcome-sign-up'))).bottom,
      lessThanOrEqualTo(tester.view.physicalSize.height),
    );

    await tester.ensureVisible(find.text('Sign up'));
    await tester.pump();
    await tester.tap(find.text('Sign up'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('auth carousel advances to feature slides', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await pumpStartup(tester);

    expect(
      find.text('Feel your rhythm before burnout gets loud'),
      findsOneWidget,
    );

    expect(find.byKey(const ValueKey('auth-welcome-previous')), findsNothing);
    expect(find.byKey(const ValueKey('auth-welcome-next')), findsNothing);

    final carousel = find.byKey(const ValueKey('auth-welcome-carousel'));
    Future<void> swipeToNextSlide() async {
      await tester.fling(carousel, const Offset(-400, 0), 1200);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
    }

    await swipeToNextSlide();

    expect(find.text('Track the signals that matter'), findsOneWidget);
    expect(find.text('Hydration'), findsOneWidget);

    await swipeToNextSlide();

    expect(find.text('Get nudges that fit your day'), findsOneWidget);

    await swipeToNextSlide();
    expect(find.text('See progress over time'), findsOneWidget);

    await swipeToNextSlide();
    expect(
      find.text('Feel your rhythm before burnout gets loud'),
      findsOneWidget,
    );
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
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Welcome to your VitalySync tour'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await ActivityService.instance.disposeTracking();
  });

  testWidgets('main navigation shows tutorial when replay is requested', (
    WidgetTester tester,
  ) async {
    configureLoggedInSession(onboardingCompleted: true);

    await pumpStartup(tester);

    expect(find.text('Welcome to your VitalySync tour'), findsNothing);

    CoreTutorialReplayController.instance.requestReplay();
    await tester.pump();
    await tester.pump();

    expect(find.text('Welcome to your VitalySync tour'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('core-tutorial-skip-button')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Welcome to your VitalySync tour'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await ActivityService.instance.disposeTracking();
  });

  testWidgets('shows pending tutorial and skip completes it', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'email': 'tester@example.com',
      'user_id': 1,
      'username': 'Tester',
      'auth_access_token': 'test-token',
      'onboarding_completed': true,
      '${CoreTutorialService.storageKeyPrefix}pending_1': true,
    });

    await pumpStartup(tester);

    expect(find.text('Welcome to your VitalySync tour'), findsOneWidget);

    await tester.tapAt(tester.getCenter(find.text('Nutrition')));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Welcome to your VitalySync tour'), findsOneWidget);
    expect(find.text('Nutrition keeps meals in context'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('core-tutorial-next-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));

    expect(find.text('Home is your daily snapshot'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('core-tutorial-next-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 520));

    expect(find.text('Nutrition keeps meals in context'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('core-tutorial-next-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 520));

    expect(find.text('Log is your daily check-in'), findsOneWidget);
    expect(find.text('Log your day'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('core-tutorial-skip-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Log is your daily check-in'), findsNothing);

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getBool('${CoreTutorialService.storageKeyPrefix}completed_1'),
      isTrue,
    );
    expect(
      prefs.containsKey('${CoreTutorialService.storageKeyPrefix}pending_1'),
      isFalse,
    );

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
