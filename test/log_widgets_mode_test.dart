import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalysync/features/log/presentation/widgets/log_widgets.dart';

void main() {
  testWidgets('daily mode hides weekly reflections and dimension headers', (
    tester,
  ) async {
    await _pumpLogWidgets(tester, showWeeklyQuestions: false);

    expect(find.text('Sleep duration'), findsOneWidget);
    expect(find.text('Recovery habits'), findsOneWidget);
    expect(find.text("This week's pressure"), findsNothing);
    expect(find.text('Weekly detachment'), findsNothing);
    expect(find.text('Weekly focus'), findsNothing);
    expect(find.text('Weekly accomplishment'), findsNothing);
    expect(find.text('Emotional exhaustion'), findsNothing);
    expect(find.text('Reduced accomplishment'), findsNothing);
  });

  testWidgets('weekly mode adds all five reflection inputs', (tester) async {
    await _pumpLogWidgets(tester, showWeeklyQuestions: true);

    expect(find.text("This week's pressure"), findsOneWidget);
    expect(find.text('Weekly detachment'), findsOneWidget);
    expect(find.text('Recovery breaks'), findsOneWidget);
    expect(find.text('Weekly focus'), findsOneWidget);
    expect(find.text('Weekly accomplishment'), findsOneWidget);
    expect(find.text('Emotional exhaustion'), findsNothing);
    expect(find.text('Reduced accomplishment'), findsNothing);
  });

  testWidgets('logging cards use a staggered calm entrance', (tester) async {
    await _pumpLogWidgets(tester, showWeeklyQuestions: false);

    final firstCard = find.byKey(const ValueKey('log-card-sleep-duration'));
    final lastCard = find.byKey(const ValueKey('log-card-exercise'));
    expect(firstCard, findsOneWidget);
    expect(lastCard, findsOneWidget);

    final firstFade = find.descendant(
      of: firstCard,
      matching: find.byType(FadeTransition),
    );
    expect(firstFade, findsOneWidget);
    expect(tester.widget<FadeTransition>(firstFade).opacity.value, lessThan(1));

    await tester.pump(const Duration(milliseconds: 800));

    expect(tester.widget<FadeTransition>(firstFade).opacity.value, 1);
    expect(find.byType(AnimatedScale), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('exercise choices use activity-specific icons', (tester) async {
    await _pumpLogWidgets(
      tester,
      showWeeklyQuestions: false,
      exercises: const [
        'Walking',
        'Jogging',
        'Running',
        'Bodyweight',
        'Stretching',
        'Breathing',
        'Yoga',
        'Gym',
        'Cycling',
        'Swimming',
        'None',
      ],
      workloadOptions: const ['3-4 hours'],
    );

    for (final icon in const [
      Icons.directions_walk_rounded,
      Icons.directions_run_rounded,
      Icons.run_circle_rounded,
      Icons.sports_gymnastics_rounded,
      Icons.accessibility_new_rounded,
      Icons.air_rounded,
      Icons.self_improvement_rounded,
      Icons.fitness_center_rounded,
      Icons.directions_bike_rounded,
      Icons.pool_rounded,
      Icons.block_rounded,
    ]) {
      expect(find.byIcon(icon), findsOneWidget);
    }
  });
}

Future<void> _pumpLogWidgets(
  WidgetTester tester, {
  required bool showWeeklyQuestions,
  List<String> exercises = const ['Walking', 'None'],
  List<String> workloadOptions = const ['None', '3-4 hours'],
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: LogWidgets(
            showWeeklyQuestions: showWeeklyQuestions,
            sleepHours: 7,
            sleepQuality: 2,
            moodIndex: 3,
            energyLevel: 3,
            hydration: 1.5,
            workloadHoursBand: '3-4 hours',
            perceivedStressLevel: 3,
            breakQualityLevel: 3,
            dailyDetachmentLevel: 3,
            dailyFocusLevel: 3,
            dailyAccomplishmentLevel: 3,
            selectedExercises: const {'Walking'},
            selectedSymptoms: const {'None'},
            selectedHabits: const {'Quiet break'},
            sleepLabels: const [
              'Poor',
              'Fair',
              'Good',
              'Very good',
              'Excellent',
            ],
            sleepStars: const [1, 2, 3, 4, 5],
            moods: const ['sad', 'low', 'okay', 'good', 'great'],
            exercises: exercises,
            symptoms: const ['Fatigue', 'None'],
            habits: const ['Quiet break', 'None'],
            exerciseGoalLabel: '3-4 days',
            workloadOptions: workloadOptions,
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
      ),
    ),
  );
}
