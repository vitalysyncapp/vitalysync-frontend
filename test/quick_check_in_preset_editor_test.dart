import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalysync/features/log/data/check_in_models.dart';
import 'package:vitalysync/features/log/data/quick_check_in_preset.dart';
import 'package:vitalysync/features/log/presentation/widgets/quick_check_in_preset_widgets.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(configureTestAssets);
  tearDownAll(clearTestAssets);

  testWidgets(
    'art picker scrolls to additional choices and saves the selection',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      QuickCheckInPreset? saved;
      await _openEditor(
        tester,
        CheckInMode.daily,
        onSaved: (preset) => saved = preset,
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('quick-check-in-name')),
        'Rest day',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      final grid = find.byKey(const ValueKey('quick-check-in-avatar-grid'));
      await tester.ensureVisible(grid);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('quick-avatar-unwell')),
        200,
        scrollable: find.descendant(
          of: grid,
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('quick-avatar-unwell')));
      await tester.tap(find.text('Save quick check-in'));
      await tester.pumpAndSettle();
      expect(saved?.avatarId, 'unwell');
      expect(saved?.name, 'Rest day');
      expect(saved?.draft.sleepHours, _draft.sleepHours);
    },
  );

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

Future<void> _openEditor(
  WidgetTester tester,
  CheckInMode mode, {
  ValueChanged<QuickCheckInPreset?>? onSaved,
}) async {
  await pumpTestApp(
    tester,
    Builder(
      builder: (context) => Center(
        child: FilledButton(
          onPressed: () async {
            final preset = await showQuickCheckInPresetEditor(
              context: context,
              mode: mode,
              initialDraft: _draft,
              exerciseGoalLabel: '3-4 days',
            );
            onSaved?.call(preset);
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
