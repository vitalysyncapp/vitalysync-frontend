import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalysync/features/dashboard/data/weekly_user_metrics.dart';
import 'package:vitalysync/features/dashboard/presentation/widgets/mood_volatility_card.dart';
import 'package:vitalysync/features/dashboard/presentation/widgets/symptom_frequency_card.dart';

void main() {
  test('symptom frequency counts each symptom once per day', () {
    final metrics = _metrics(
      moods: const [2, 2, 2, 2, 2, 2, 2],
      symptoms: const [
        ['Headache', 'headache', ' Headache '],
        ['HEADACHE'],
        [],
        [],
        [],
        [],
        [],
      ],
    );

    expect(metrics.symptomCounts, {'Headache': 2});
  });

  testWidgets('mood card plots daily values and preserves missing-day gaps', (
    tester,
  ) async {
    final metrics = _metrics(
      moods: const [1, null, 2, 3, null, 4, 4],
      symptoms: const [[], [], [], [], [], [], []],
    );

    await _pumpCard(
      tester,
      MoodVolatilityCard(metrics: metrics, isLoading: false),
    );

    expect(find.text('Daily check-ins over the last 7 days'), findsOneWidget);
    expect(find.text('Good'), findsOneWidget);
    expect(find.text('3.8/5 average - 5/7 logged'), findsOneWidget);
    expect(find.text('Improving'), findsOneWidget);
    expect(find.byKey(const ValueKey('mood-trend-chart')), findsOneWidget);

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    final spots = chart.data.lineBarsData.single.spots;
    expect(spots, hasLength(7));
    expect(spots[0], const FlSpot(0, 2));
    expect(spots[1], FlSpot.nullSpot);
    expect(spots[4], FlSpot.nullSpot);
    expect(spots[6], const FlSpot(6, 5));
    expect(chart.data.minY, lessThan(1));
    expect(chart.data.maxY, greaterThan(5));
    expect(
      chart.data.maxY - spots[6].y,
      greaterThanOrEqualTo(0.25),
      reason: 'A maximum-score marker needs room below the clipped top edge.',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('symptom card ranks reports and uses a seven-part scale', (
    tester,
  ) async {
    final metrics = _metrics(
      moods: const [2, 2, 3, 3, 4, 4, 4],
      symptoms: const [
        ['Headache', 'Fatigue'],
        ['Headache'],
        ['Fatigue'],
        ['Headache', 'Nausea'],
        ['Headache'],
        ['Fatigue'],
        ['Dizziness'],
      ],
    );

    await _pumpCard(
      tester,
      SymptomFrequencyCard(metrics: metrics, isLoading: false),
    );

    expect(
      find.text('How often symptoms were reported this week'),
      findsOneWidget,
    );
    expect(find.text('Most reported'), findsOneWidget);
    expect(find.text('4 of 7 days'), findsOneWidget);
    expect(find.text('7-day scale'), findsOneWidget);
    final headacheSemantics = tester.widget<Semantics>(
      find.byKey(const ValueKey('symptom-frequency-Headache')),
    );
    final fatigueSemantics = tester.widget<Semantics>(
      find.byKey(const ValueKey('symptom-frequency-Fatigue')),
    );
    expect(
      headacheSemantics.properties.label,
      'Headache reported on 4 of 7 days',
    );
    expect(
      fatigueSemantics.properties.label,
      'Fatigue reported on 3 of 7 days',
    );

    final headacheBar = find.byKey(
      const ValueKey('symptom-frequency-bar-Headache'),
    );
    expect(
      find.descendant(of: headacheBar, matching: find.byType(Container)),
      findsNWidgets(7),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('cards provide useful empty states', (tester) async {
    final noLogs = _metrics(
      moods: const [null, null, null, null, null, null, null],
      symptoms: const [[], [], [], [], [], [], []],
      markDaysLogged: false,
    );

    await _pumpCard(
      tester,
      Column(
        children: [
          MoodVolatilityCard(metrics: noLogs, isLoading: false),
          const SizedBox(height: 12),
          SymptomFrequencyCard(metrics: noLogs, isLoading: false),
        ],
      ),
    );

    expect(find.text('Your mood trend will appear here'), findsOneWidget);
    expect(find.text('No symptom data yet'), findsOneWidget);
    expect(find.byType(LineChart), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpCard(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

WeeklyUserMetrics _metrics({
  required List<int?> moods,
  required List<List<String>> symptoms,
  bool markDaysLogged = true,
}) {
  final start = DateTime(2026, 7, 27);
  const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  return WeeklyUserMetrics(
    days: List.generate(7, (index) {
      final date = start.add(Duration(days: index));
      final mood = moods[index];
      return DailyUserMetric(
        date: date,
        dateKey: date.toIso8601String().substring(0, 10),
        dayLabel: dayLabels[index],
        log: markDaysLogged
            ? {'mood_index': ?mood, 'symptom_names': symptoms[index]}
            : null,
        activity: null,
      );
    }),
  );
}
