import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalysync/features/auth/presentation/pages/login_page.dart';
import 'package:vitalysync/features/dashboard/presentation/widgets/dashboard_header_card.dart';
import 'package:vitalysync/features/log/presentation/widgets/log_widgets.dart';
import 'package:vitalysync/features/notifications/presentation/pages/notification_page.dart';
import 'package:vitalysync/features/nutrition/presentation/widgets/today_nutrition_card.dart';
import 'package:vitalysync/features/onboarding/data/burnout_baseline_questions.dart';
import 'package:vitalysync/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:vitalysync/features/profile/presentation/pages/profile_page.dart';
import 'package:vitalysync/features/profile/presentation/pages/edit_wellness_profile_page.dart';
import 'package:vitalysync/features/profile/presentation/pages/retake_baseline_questionnaire_page.dart';
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

  testWidgets('onboarding requires valid height and weight on one step', (
    tester,
  ) async {
    configureLoggedInSession(onboardingCompleted: false);

    await pumpTestApp(tester, const OnboardingPage(userId: 1));
    await tester.pump();

    await _selectOnboardingOptionAndContinue(tester, 'Student');
    await _selectOnboardingOptionAndContinue(tester, 'Lightly active');
    await _selectOnboardingOptionAndContinue(tester, 'Improve sleep');

    final heightField = find.byKey(const ValueKey('onboarding-height-field'));
    final weightField = find.byKey(const ValueKey('onboarding-weight-field'));

    expect(find.text('What are your height and weight?'), findsWidgets);
    expect(heightField, findsOneWidget);
    expect(weightField, findsOneWidget);
    expect(find.text('cm'), findsOneWidget);
    expect(find.text('kg'), findsOneWidget);
    expect(_onboardingNextButton(tester).onTap, isNull);

    await tester.enterText(heightField, '99');
    await tester.enterText(weightField, '501');
    await tester.pump();

    expect(find.text('Height must be between 100 and 250 cm'), findsOneWidget);
    expect(find.text('Weight must be between 20 and 500 kg'), findsOneWidget);
    expect(_onboardingNextButton(tester).onTap, isNull);

    await tester.enterText(heightField, '');
    await tester.pump();

    expect(find.text('Enter your height'), findsOneWidget);

    await tester.enterText(heightField, '170.5');
    await tester.enterText(weightField, '65.2');
    await tester.pump();

    expect(find.text('Enter your height'), findsNothing);
    expect(find.textContaining('must be between'), findsNothing);
    expect(_onboardingNextButton(tester).onTap, isNotNull);
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
          dailyDetachmentLevel: 2,
          dailyFocusLevel: 4,
          dailyAccomplishmentLevel: 4,
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
          onDailyDetachmentChanged: (_) {},
          onDailyFocusChanged: (_) {},
          onDailyAccomplishmentChanged: (_) {},
          onExerciseToggle: (_) {},
          onSymptomToggle: (_) {},
          onHabitToggle: (_) {},
        ),
      ),
    );

    expect(find.text('Sleep duration'), findsOneWidget);
    expect(find.text('Hydration'), findsOneWidget);
    expect(find.text('Recovery habits'), findsOneWidget);
  });

  testWidgets('dashboard header renders analytics copy', (tester) async {
    await pumpTestApp(tester, const DashboardHeaderCard());

    expect(find.text('Your wellness analytics dashboard'), findsOneWidget);
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

    expect(find.text('Eaten today'), findsOneWidget);
    expect(find.text('1,450 kcal'), findsOneWidget);
    expect(find.text('750'), findsOneWidget);
    expect(find.text('Protein'), findsOneWidget);
    expect(find.text('Carbs'), findsOneWidget);
    expect(find.text('Fat'), findsOneWidget);
    expect(find.text('2,200 kcal'), findsOneWidget);
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
              heightCm: 170,
              weightKg: 65,
              isSaving: false,
              isSavingBaseline: false,
              onEdit: () {},
              onRetakeBaseline: () {},
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

    expect(find.text('Wellness profile'), findsOneWidget);
    expect(find.text('Edit wellness profile'), findsOneWidget);
    expect(find.text('Retake baseline'), findsOneWidget);
    expect(find.text('Height'), findsOneWidget);
    expect(find.text('170 cm'), findsOneWidget);
    expect(find.text('Weight'), findsOneWidget);
    expect(find.text('65 kg'), findsOneWidget);
    expect(find.text('BMI'), findsOneWidget);
    expect(find.text('22.5'), findsOneWidget);
    expect(find.text('Daily water goal'), findsNothing);
    expect(find.text('Exercise target'), findsNothing);

    expect(find.text('My goals'), findsOneWidget);
    expect(find.text('Wellness goal'), findsOneWidget);
    expect(find.text('Sleep goal'), findsOneWidget);
    expect(find.text('Hydration goal'), findsOneWidget);
    expect(find.text('Activity goal'), findsOneWidget);
    expect(find.text('Daily steps'), findsOneWidget);
    expect(find.text('Nutrition goal'), findsOneWidget);
  });

  testWidgets('edit wellness validates and saves height and weight', (
    tester,
  ) async {
    double? savedHeightCm;
    double? savedWeightKg;

    await pumpTestApp(
      tester,
      EditWellnessProfilePage(
        initialRole: 'Student',
        initialLifestyle: 'Moderately Active',
        initialWorkIntensity: 'Medium',
        initialSleepSchedule: '10:30 PM - 6:30 AM',
        initialHeightCm: 170,
        initialWeightKg: 65,
        onSave:
            ({
              required role,
              required lifestyleType,
              required workIntensity,
              required sleepSchedule,
              required heightCm,
              required weightKg,
            }) async {
              savedHeightCm = heightCm;
              savedWeightKg = weightKg;
              return true;
            },
      ),
    );

    final heightField = find.byKey(const ValueKey('profile-height-field'));
    final weightField = find.byKey(const ValueKey('profile-weight-field'));
    final saveButton = find.text('Save changes');

    expect(heightField, findsOneWidget);
    expect(weightField, findsOneWidget);
    expect(find.text('cm'), findsOneWidget);
    expect(find.text('kg'), findsOneWidget);

    await tester.enterText(heightField, '99');
    await tester.enterText(weightField, '501');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pump();

    expect(find.text('Height must be between 100 and 250 cm'), findsOneWidget);
    expect(find.text('Weight must be between 20 and 500 kg'), findsOneWidget);
    expect(savedHeightCm, isNull);
    expect(savedWeightKg, isNull);

    await tester.pump(const Duration(seconds: 2));
    await tester.enterText(heightField, '171.5');
    await tester.enterText(weightField, '66.2');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pump();

    expect(savedHeightCm, 171.5);
    expect(savedWeightKg, 66.2);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('edit wellness allows legacy profiles without metrics', (
    tester,
  ) async {
    var saved = false;
    double? savedHeightCm = -1;
    double? savedWeightKg = -1;

    await pumpTestApp(
      tester,
      EditWellnessProfilePage(
        initialRole: 'Student',
        initialLifestyle: 'Moderately Active',
        initialWorkIntensity: 'Medium',
        initialSleepSchedule: '10:30 PM - 6:30 AM',
        initialHeightCm: null,
        initialWeightKg: null,
        onSave:
            ({
              required role,
              required lifestyleType,
              required workIntensity,
              required sleepSchedule,
              required heightCm,
              required weightKg,
            }) async {
              saved = true;
              savedHeightCm = heightCm;
              savedWeightKg = weightKg;
              return true;
            },
      ),
    );

    final saveButton = find.text('Save changes');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pump();

    expect(saved, isTrue);
    expect(savedHeightCm, isNull);
    expect(savedWeightKg, isNull);
    expect(find.text('Check wellness details'), findsNothing);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('wellness profile card triggers retake baseline action', (
    tester,
  ) async {
    var tapped = false;

    await pumpTestApp(
      tester,
      SingleChildScrollView(
        child: WellnessProfileCard(
          lifestyleType: 'Moderately Active',
          currentRole: 'Student',
          usualSleepTime: '10:30 PM',
          usualWakeTime: '6:30 AM',
          workIntensity: 'Medium',
          burnoutLevel: 'Low',
          burnoutScore: 24,
          heightCm: 171.5,
          weightKg: 66.2,
          isSaving: false,
          isSavingBaseline: false,
          onEdit: () {},
          onRetakeBaseline: () => tapped = true,
        ),
      ),
    );

    await tester.ensureVisible(find.text('Retake baseline'));
    await tester.pump();
    await tester.tap(find.text('Retake baseline'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('retake baseline requires the visible section before next', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      RetakeBaselineQuestionnairePage(
        initialAnswers: const {},
        onSave: (_) async => true,
      ),
    );

    final nextButton = tester.widget<ElevatedButton>(_retakePrimaryButton);

    expect(nextButton.onPressed, isNull);
  });

  testWidgets('retake baseline prefills answers and saves full payload', (
    tester,
  ) async {
    List<Map<String, dynamic>>? savedPayload;
    final firstSectionAnswers = _answersForSection(0, 4);

    await pumpTestApp(
      tester,
      RetakeBaselineQuestionnairePage(
        initialAnswers: firstSectionAnswers,
        onSave: (answers) async {
          savedPayload = answers;
          return true;
        },
      ),
    );

    final nextButton = tester.widget<ElevatedButton>(_retakePrimaryButton);
    expect(nextButton.onPressed, isNotNull);

    await _advanceRetakeSection(tester, nextPage: 1);
    await _answerSection(tester, sectionIndex: 1, value: 3);

    await _advanceRetakeSection(tester, nextPage: 2);
    await _answerSection(tester, sectionIndex: 2, value: 5);

    tester.widget<ElevatedButton>(_retakePrimaryButton).onPressed!();
    await tester.pump();

    expect(savedPayload, isNotNull);
    expect(savedPayload, hasLength(15));
    expect(
      savedPayload!.firstWhere(
        (answer) => answer['question_key'] == 'ee_01',
      )['numeric_value'],
      4,
    );
    expect(
      savedPayload!.firstWhere(
        (answer) => answer['question_key'] == 'dp_01',
      )['numeric_value'],
      3,
    );
    expect(
      savedPayload!.firstWhere(
        (answer) => answer['question_key'] == 'pa_01',
      )['numeric_value'],
      5,
    );
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
          periodStart: '2026-05-20',
          periodEnd: '2026-05-20',
        ),
        onTap: () {},
      ),
    );

    expect(find.text('Daily wellness report'), findsWidgets);
    expect(find.text('Sleep'), findsOneWidget);
    expect(find.text('7h'), findsOneWidget);
    expect(find.text('Medium'), findsOneWidget);
    expect(find.textContaining('For May 20'), findsOneWidget);
  });
}

Map<String, int> _answersForSection(int sectionIndex, int value) {
  return {
    for (final question in kBurnoutBaselineSections[sectionIndex].questions)
      question.questionKey: value,
  };
}

final Finder _retakePrimaryButton = find.byKey(
  const ValueKey('retake-baseline-primary-button'),
);

InkWell _onboardingNextButton(WidgetTester tester) {
  return tester.widget<InkWell>(
    find.ancestor(of: find.text('Next'), matching: find.byType(InkWell)).last,
  );
}

Future<void> _selectOnboardingOptionAndContinue(
  WidgetTester tester,
  String option,
) async {
  await tester.tap(find.text(option));
  await tester.pump();
  final nextButton = _onboardingNextButton(tester);
  final pageController = tester
      .widget<PageView>(find.byType(PageView))
      .controller!;
  final nextPage = (pageController.page ?? 0).round() + 1;
  expect(nextButton.onTap, isNotNull);
  nextButton.onTap!();
  await tester.pump();
  pageController.jumpToPage(nextPage);
  await tester.pump();
}

Future<void> _advanceRetakeSection(
  WidgetTester tester, {
  required int nextPage,
}) async {
  final nextButton = tester.widget<ElevatedButton>(_retakePrimaryButton);
  final pageController = tester
      .widget<PageView>(find.byType(PageView))
      .controller!;
  expect(nextButton.onPressed, isNotNull);
  nextButton.onPressed!();
  await tester.pump();
  pageController.jumpToPage(nextPage);
  await tester.pump();
}

Future<void> _answerSection(
  WidgetTester tester, {
  required int sectionIndex,
  required int value,
}) async {
  final optionLabel = _labelForLikertValue(value);

  for (final question in kBurnoutBaselineSections[sectionIndex].questions) {
    final questionFinder = find.byKey(
      ValueKey('baseline-${question.questionKey}'),
    );
    await tester.ensureVisible(questionFinder);
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: questionFinder,
        matching: find.byTooltip('$value - $optionLabel'),
      ),
    );
    await tester.pump();
  }
}

String _labelForLikertValue(int value) {
  return kBurnoutBaselineScale
      .firstWhere((option) => option.value == value)
      .label;
}
