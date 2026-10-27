import 'package:flutter_test/flutter_test.dart';
import 'package:vitalysync/features/log/data/check_in_models.dart';
import 'package:vitalysync/features/log/data/quick_check_in_preset.dart';

void main() {
  const draft = CheckInDraft(
    sleepHours: 7.5,
    sleepQuality: 3,
    moodIndex: 4,
    energyLevel: 4,
    hydrationLiters: 2,
    workloadHoursBand: '5-6 hours',
    exerciseNames: {'Walking'},
    symptomNames: {'None'},
    habitNames: {'Quiet break'},
    perceivedPressureLevel: 3,
    recoveryRestLevel: 4,
    detachmentLevel: 2,
    productivityFocusLevel: 4,
    accomplishmentLevel: 5,
  );

  test('daily preset round trips the complete daily questionnaire', () {
    final preset = QuickCheckInPreset(
      presetId: 11,
      name: 'Productive',
      mode: CheckInMode.daily,
      avatarId: 'focused',
      draft: draft,
    );
    final decoded = QuickCheckInPreset.fromJson(preset.toJson());

    expect(decoded.presetId, 11);
    expect(decoded.name, 'Productive');
    expect(decoded.mode, CheckInMode.daily);
    expect(decoded.draft.sleepHours, 7.5);
    expect(decoded.draft.hydrationLiters, 2);
    expect(
      preset.toMutationJson()['daily']['questionnaire_version'],
      'daily_14_v2',
    );
    expect(preset.toMutationJson()['weekly_answers'], isNull);
  });

  test('weekly preset keeps its answers and uses the nine-input version', () {
    final preset = QuickCheckInPreset(
      presetId: 12,
      name: 'Weekly reset',
      mode: CheckInMode.weekly,
      avatarId: 'calm',
      draft: draft,
      weeklyAnswers: const {'ee_01': 3, 'pa_01': 4},
    );
    final decoded = QuickCheckInPreset.fromJson(preset.toJson());

    expect(decoded.weeklyAnswers, {'ee_01': 3, 'pa_01': 4});
    expect(
      preset.toMutationJson()['daily']['questionnaire_version'],
      'daily_core9_v3',
    );
    expect(
      preset.toMutationJson()['daily'].containsKey('daily_focus_level'),
      isFalse,
    );
  });

  test('expanded avatar catalog preserves existing preset choices', () {
    expect(QuickCheckInAvatarCatalog.entries, hasLength(36));
    expect(
      QuickCheckInAvatarCatalog.entries.map((entry) => entry.id),
      containsAll([
        'tired',
        'focused',
        'celebrating',
        'energized',
        'productive',
        'mindful',
      ]),
    );
  });
}
