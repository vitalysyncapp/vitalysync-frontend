import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalysync/features/log/data/check_in_models.dart';
import 'package:vitalysync/features/log/presentation/widgets/quick_check_in_preset_widgets.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(configureTestAssets);
  tearDownAll(clearTestAssets);

  testWidgets('daily preset editor reveals the complete daily questionnaire', (
    tester,
  ) async {
    await _openEditor(tester, CheckInMode.daily);

    expect(
      find.byKey(const ValueKey('quick-check-in-questionnaire-skeleton')),
      findsOneWidget,
    );
    expect(find.text('Sleep duration'), findsNothing);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 350));

    expect(
      find.byKey(const ValueKey('quick-check-in-questionnaire-skeleton')),
      findsNothing,
    );
    expect(find.text('Sleep duration'), findsOneWidget);
    expect(find.text("Today's pressure"), findsOneWidget);
    expect(find.text('Daily accomplishment'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('weekly-reflection-inline')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'weekly preset editor reveals practical and reflection questions',
    (tester) async {
      await _openEditor(tester, CheckInMode.weekly);

      expect(
        find.byKey(const ValueKey('quick-check-in-questionnaire-skeleton')),
        findsOneWidget,
      );

      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Sleep duration'), findsOneWidget);
      expect(find.text("Today's pressure"), findsNothing);
      expect(
        find.byKey(const ValueKey('weekly-reflection-inline')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('log-card-weekly-ee_01')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _openEditor(WidgetTester tester, CheckInMode mode) async {
  await pumpTestApp(
    tester,
    Builder(
      builder: (context) => Center(
        child: FilledButton(
          onPressed: () async {
            await showQuickCheckInPresetEditor(
              context: context,
              mode: mode,
              initialDraft: _draft,
              exerciseGoalLabel: '3-4 days',
            );
          },
          child: const Text('Open editor'),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Open editor'));
  await tester.pump();
}

const _draft = CheckInDraft(
  sleepHours: 7,
  sleepQuality: 3,
  moodIndex: 3,
  energyLevel: 4,
  hydrationLiters: 1.5,
  workloadHoursBand: '5-6 hours',
  exerciseNames: {'Walking'},
  symptomNames: {'None'},
  habitNames: {'Quiet break'},
  perceivedPressureLevel: 3,
  recoveryRestLevel: 3,
  detachmentLevel: 3,
  productivityFocusLevel: 4,
  accomplishmentLevel: 4,
);
