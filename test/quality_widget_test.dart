import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalysync/features/auth/presentation/pages/login_page.dart';
import 'package:vitalysync/features/dashboard/presentation/widgets/dashboard_header_card.dart';
import 'package:vitalysync/features/log/presentation/widgets/log_widgets.dart';
import 'package:vitalysync/features/notifications/presentation/pages/notification_page.dart';
import 'package:vitalysync/features/nutrition/presentation/widgets/today_nutrition_card.dart';
import 'package:vitalysync/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:vitalysync/features/profile/presentation/pages/profile_page.dart';
import 'package:vitalysync/features/profile/presentation/widgets/wellness_profile_card.dart';
import 'package:vitalysync/shared/goals/user_goals.dart';
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
          selectedHabits: const {'Quiet break'},
          sleepLabels: const ['Poor', 'Fair', 'Good', 'Very Good', 'Excellent'],
          sleepStars: const [1, 2, 3, 4, 5],
          moods: const ['sad', 'low', 'okay', 'good', 'great'],
          exercises: const ['Walking', 'Running', 'None'],
          symptoms: const ['Headache', 'Fatigue', 'None'],
          habits: const ['Quiet break', 'Sunlight or fresh air', 'None'],
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
        calorieGoal: 2200,
      ),
    );

    expect(find.text("Today's Nutrition"), findsOneWidget);
    expect(find.text('1450'), findsOneWidget);
    expect(find.text('Protein'), findsOneWidget);
    expect(find.text('Carbs'), findsOneWidget);
    expect(find.text('Fats'), findsOneWidget);
    expect(find.text('Goal: 2,200'), findsOneWidget);
  });

  testWidgets('profile wellness and goals sections are separated', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      SingleChildScrollView(
        child: Column(
          children: [
            WellnessProfileCard(
              lifestyleType: 'Moderately Active',
              currentRole: 'Student',
              usualSleepTime: '10:30 PM',
              usualWakeTime: '6:30 AM',
              workIntensity: 'Medium',
              burnoutLevel: 'Low',
              burnoutScore: 24,
              isSaving: false,
              onEdit: () {},
            ),
            MyGoalsCard(
              goals: UserGoalsSnapshot.defaults(
                wellnessGoal: 'Improve sleep',
                sleepHours: 8,
                hydrationLiters: 2.5,
                activityDaysPerWeek: 4,
                dailySteps: 7000,
                nutritionCalories: 2200,
              ),
              isSaving: false,
              onEdit: () {},
            ),
          ],
        ),
      ),
    );

    expect(find.text('Wellness Profile'), findsOneWidget);
    expect(find.text('Edit Wellness Profile'), findsOneWidget);
    expect(find.text('Daily Water Goal'), findsNothing);
    expect(find.text('Exercise Target'), findsNothing);

    expect(find.text('My Goals'), findsOneWidget);
    expect(find.text('Wellness Goal'), findsOneWidget);
    expect(find.text('Sleep Goal'), findsOneWidget);
    expect(find.text('Hydration Goal'), findsOneWidget);
    expect(find.text('Activity Goal'), findsOneWidget);
    expect(find.text('Daily Steps'), findsOneWidget);
    expect(find.text('Nutrition Goal'), findsOneWidget);
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

    expect(find.text('Daily wellness report'), findsWidgets);
    expect(find.text('Sleep'), findsOneWidget);
    expect(find.text('7h'), findsOneWidget);
    expect(find.text('MEDIUM'), findsOneWidget);
  });
}
