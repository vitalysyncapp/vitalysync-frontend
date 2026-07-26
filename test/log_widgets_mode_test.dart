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
}

Future<void> _pumpLogWidgets(
  WidgetTester tester, {
  required bool showWeeklyQuestions,
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
            exercises: const ['Walking', 'None'],
            symptoms: const ['Fatigue', 'None'],
            habits: const ['Quiet break', 'None'],
            exerciseGoalLabel: '3-4 days',
            workloadOptions: const ['None', '3-4 hours'],
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
