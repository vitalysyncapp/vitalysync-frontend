import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalysync/features/log/presentation/widgets/log_widgets.dart';

void main() {
  testWidgets('daily mode displays all fourteen inputs', (tester) async {
    await _pumpLogWidgets(tester, showWeeklyQuestions: false);

    expect(find.text('Sleep duration'), findsOneWidget);
    expect(find.text('Recovery habits'), findsOneWidget);
    expect(find.text("Today's pressure"), findsOneWidget);
    expect(find.text('Daily detachment'), findsOneWidget);
    expect(find.text('Daily focus'), findsOneWidget);
    expect(find.text('Daily accomplishment'), findsOneWidget);
    expect(find.text('Emotional exhaustion'), findsNothing);
    expect(find.text('Reduced accomplishment'), findsNothing);
  });

  testWidgets(
    'weekly mode keeps nine practical inputs and omits five daily reflections',
    (tester) async {
      await _pumpLogWidgets(tester, showWeeklyQuestions: true);

      expect(find.text('Sleep duration'), findsOneWidget);
      expect(find.text('Recovery habits'), findsOneWidget);
      expect(find.text("Today's pressure"), findsNothing);
      expect(find.text('Daily detachment'), findsNothing);
      expect(find.text('Recovery breaks'), findsNothing);
      expect(find.text('Daily focus'), findsNothing);
      expect(find.text('Daily accomplishment'), findsNothing);
      expect(find.text('Emotional exhaustion'), findsNothing);
      expect(find.text('Reduced accomplishment'), findsNothing);
    },
  );

  testWidgets('daily reflection inputs follow the sleep cards', (tester) async {
    await _pumpLogWidgets(tester, showWeeklyQuestions: false);

    final orderedCardIds = [
      'sleep-duration',
      'sleep-quality',
      'daily-pressure',
      'daily-detachment',
      'recovery-breaks',
      'daily-focus',
      'daily-accomplishment',
      'energy',
    ];

    final cardOffsets = orderedCardIds
        .map((id) => tester.getTopLeft(find.byKey(ValueKey('log-card-$id'))).dy)
        .toList();

    for (var index = 1; index < cardOffsets.length; index++) {
      expect(cardOffsets[index], greaterThan(cardOffsets[index - 1]));
    }
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

  testWidgets('disabled entrance motion keeps questionnaire cards visible', (
    tester,
  ) async {
    await _pumpLogWidgets(
      tester,
      showWeeklyQuestions: false,
      revealCards: false,
    );

    final firstCard = find.byKey(const ValueKey('log-card-sleep-duration'));
    expect(firstCard, findsOneWidget);
    expect(
      find.descendant(of: firstCard, matching: find.byType(FadeTransition)),
      findsNothing,
    );
    expect(find.text('Sleep duration'), findsOneWidget);
    expect(tester.getSize(firstCard).height, greaterThan(0));
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
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('log-card-exercise')),
          matching: find.byIcon(icon),
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets(
    'workload hours card renders corrected display bands without changing backend option values',
    (tester) async {
      String? selectedBand;
      await _pumpLogWidgets(
        tester,
        showWeeklyQuestions: false,
        workloadOptions: const [
          'None',
          '1-2 hours',
          '3-4 hours',
          '5-6 hours',
          '6-7 hours',
          '8-9 hours',
          '10-12 hours',
        ],
        onWorkloadChanged: (value) => selectedBand = value,
      );

      final workloadCard = find.byKey(const ValueKey('log-card-workload'));
      for (final label in const [
        'None',
        '1-2 hours',
        '3-4 hours',
        '5-6 hours',
        '7-8 hours',
        '9-10 hours',
        '11-12 hours',
      ]) {
        expect(
          find.descendant(of: workloadCard, matching: find.text(label)),
          findsOneWidget,
        );
      }
      expect(
        find.descendant(of: workloadCard, matching: find.text('6-7 hours')),
        findsNothing,
      );
      expect(
        find.descendant(of: workloadCard, matching: find.text('8-9 hours')),
        findsNothing,
      );
      expect(
        find.descendant(of: workloadCard, matching: find.text('10-12 hours')),
        findsNothing,
      );

      await tester.ensureVisible(
        find.descendant(of: workloadCard, matching: find.text('9-10 hours')),
      );
      await tester.tap(
        find.descendant(of: workloadCard, matching: find.text('9-10 hours')),
      );
      await tester.pump();
      expect(selectedBand, '8-9 hours');
    },
  );
}

Future<void> _pumpLogWidgets(
  WidgetTester tester, {
  required bool showWeeklyQuestions,
  bool revealCards = true,
  List<String> exercises = const ['Walking', 'None'],
  List<String> workloadOptions = const ['None', '3-4 hours'],
  ValueChanged<String>? onWorkloadChanged,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: LogWidgets(
            revealCards: revealCards,
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
            onWorkloadChanged: onWorkloadChanged ?? (_) {},
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
