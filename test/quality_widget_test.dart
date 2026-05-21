import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalysync/features/auth/presentation/pages/login_page.dart';
import 'package:vitalysync/features/dashboard/presentation/widgets/dashboard_header_card.dart';
import 'package:vitalysync/features/log/presentation/widgets/log_widgets.dart';
import 'package:vitalysync/features/notifications/presentation/pages/notification_page.dart';
import 'package:vitalysync/features/nutrition/presentation/widgets/today_nutrition_card.dart';
import 'package:vitalysync/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:vitalysync/shared/notifications/notification_feed_service.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(configureTestAssets);
  tearDownAll(clearTestAssets);

  testWidgets('login page renders primary sign-in controls', (tester) async {
    await pumpTestApp(tester, const LoginPage());

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('onboarding starts with the profile question', (tester) async {
    configureLoggedInSession(onboardingCompleted: false);

    await pumpTestApp(tester, const OnboardingPage(userId: 1));
    await tester.pump();

    expect(find.text('What best describes you?'), findsWidgets);
    expect(find.text('Student'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('logging widgets render daily check-in sections', (tester) async {
    await pumpTestApp(
      tester,
      SingleChildScrollView(
        child: LogWidgets(
          sleepHours: 7,
          sleepQuality: 2,
          moodIndex: 3,
          energyLevel: 1,
          hydration: 1.5,
          workloadHoursBand: '3-4 hours',
          perceivedStressLevel: 3,
          breakQualityLevel: 3,
          selectedExercises: const {'Walking'},
          selectedSymptoms: const {'None'},
          selectedHabits: const {'Mindful break'},
          sleepLabels: const ['Poor', 'Fair', 'Good', 'Very Good', 'Excellent'],
          sleepStars: const [1, 2, 3, 4, 5],
          moods: const ['sad', 'low', 'okay', 'good', 'great'],
          exercises: const ['Walking', 'Running', 'None'],
          symptoms: const ['Headache', 'Fatigue', 'None'],
          habits: const ['Mindful break', 'Outdoor light', 'None'],
          exerciseGoalLabel: '3-4 days',
          workloadOptions: const ['None', '3-4 hours', '8-9 hours'],
          onSleepChanged: (_) {},
          onSleepQualityChanged: (_) {},
          onMoodChanged: (_) {},
          onEnergyChanged: (_) {},
          onHydrationAdd: (_) {},
          onHydrationSubtract: () {},
          onHydrationReset: () {},
          onWorkloadChanged: (_) {},
          onPerceivedStressChanged: (_) {},
          onBreakQualityChanged: (_) {},
          onExerciseToggle: (_) {},
          onSymptomToggle: (_) {},
          onHabitToggle: (_) {},
        ),
      ),
    );

    expect(find.text('Sleep Duration'), findsOneWidget);
    expect(find.text('Hydration'), findsOneWidget);
    expect(find.text('Recovery Habits'), findsOneWidget);
  });

  testWidgets('dashboard header renders analytics copy', (tester) async {
    await pumpTestApp(tester, const DashboardHeaderCard());

    expect(find.text('Your Wellness Analytics Dashboard'), findsOneWidget);
    expect(find.byIcon(Icons.insights_rounded), findsOneWidget);
  });

  testWidgets('nutrition summary card renders calories and macros', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      const TodayNutritionCard(
        calories: 1450,
        proteinG: 75,
        carbsG: 180,
        fatG: 42,
      ),
    );

    expect(find.text("Today's Nutrition"), findsOneWidget);
    expect(find.text('1450'), findsOneWidget);
    expect(find.text('Protein'), findsOneWidget);
    expect(find.text('Carbs'), findsOneWidget);
    expect(find.text('Fats'), findsOneWidget);
  });

  testWidgets('notification card renders report metrics and priority', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      NotificationCard(
        item: AppNotificationItem(
          id: 'report_1',
          category: 'daily',
          title: 'Daily wellness report',
          message: 'Sleep is 7h and hydration is 2L.',
          sourceLabel: 'Daily report',
          priority: 'medium',
          createdAt: DateTime(2026, 5, 21, 9),
          updatedAt: DateTime(2026, 5, 21, 9),
          metricChips: const ['Sleep 7h', 'Hydration 2L'],
          isUnread: true,
          reportType: 'daily',
        ),
        onTap: () {},
      ),
    );

    expect(find.text('Daily wellness report'), findsOneWidget);
    expect(find.text('Sleep 7h'), findsOneWidget);
    expect(find.text('MEDIUM'), findsOneWidget);
  });
}
