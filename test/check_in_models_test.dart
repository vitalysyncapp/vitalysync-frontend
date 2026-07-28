import 'package:flutter_test/flutter_test.dart';
import 'package:vitalysync/features/log/data/check_in_models.dart';

void main() {
  test('daily recovery habits use the approved option set and order', () {
    expect(CheckInFormOptions.habits, const [
      'Quiet break',
      'Sunlight or fresh air',
      'Deep breathing',
      'Meditation',
      'Less screen time',
      'Talked with someone',
      'Read a book',
      'Listened to music',
      'Hobby or creative activity',
      'None',
    ]);
  });

  const completeDailyDraft = CheckInDraft(
    sleepHours: 7.5,
    sleepQuality: 3,
    moodIndex: 3,
    energyLevel: 4,
    hydrationLiters: 2,
    workloadHoursBand: '5-6 hours',
    exerciseNames: {'Walking'},
    symptomNames: {'None'},
    habitNames: {'Quiet break'},
  );

  test('daily validation does not require weekly reflection fields', () {
    expect(completeDailyDraft.validationErrors(CheckInMode.daily), isEmpty);
  });

  test('weekly validation requires all five reflection fields', () {
    expect(
      completeDailyDraft.validationErrors(CheckInMode.weekly),
      containsAll([
        'pressure',
        'recovery breaks',
        'detachment',
        'focus',
        'accomplishment',
      ]),
    );

    final weeklyDraft = completeDailyDraft.copyWith(
      perceivedPressureLevel: 4,
      recoveryRestLevel: 2,
      detachmentLevel: 3,
      productivityFocusLevel: 4,
      accomplishmentLevel: 5,
    );
    expect(weeklyDraft.validationErrors(CheckInMode.weekly), isEmpty);
    expect(weeklyDraft.weeklyJson(), {
      'perceived_pressure_level': 4,
      'recovery_rest_level': 2,
      'detachment_level': 3,
      'productivity_focus_level': 4,
      'accomplishment_level': 5,
    });
  });

  test('existing weekly values override legacy daily dimension values', () {
    final draft = CheckInDraft.fromJson(
      daily: {
        'sleep_hours': 6,
        'sleep_quality': 2,
        'mood_index': 1,
        'energy_level': 2,
        'hydration_liters': 1.5,
        'workload_hours_band': '8-9 hours',
        'exercise_names': ['None'],
        'symptom_names': ['Fatigue'],
        'habit_names': ['Mindful break'],
        'perceived_stress_level': 2,
        'daily_focus_level': 2,
      },
      weekly: {'perceived_pressure_level': 5, 'productivity_focus_level': 4},
    );

    expect(draft.perceivedPressureLevel, 5);
    expect(draft.productivityFocusLevel, 4);
    expect(draft.habitNames, {'Quiet break'});
  });

  test('offline status promotes a passed due date to weekly mode', () {
    final status = CheckInStatus.fromJson(
      {
        'required_mode': 'daily',
        'has_today_log': false,
        'schedule': {
          'is_due': false,
          'is_overdue': false,
          'completed_today': false,
          'next_due_date': '2026-07-20',
        },
        'existing_check_in': <String, dynamic>{},
      },
      isOffline: true,
      localDate: '2026-07-26',
    );

    expect(status.requiredMode, CheckInMode.weekly);
    expect(status.isComplete, isFalse);
  });

  test(
    'pending short answers remain available when weekly mode is required',
    () {
      final status = CheckInStatus.fromJson(
        {
          'required_mode': 'weekly',
          'has_today_log': false,
          'schedule': {'is_overdue': true, 'completed_today': false},
          'existing_check_in': <String, dynamic>{},
        },
        pendingPayload: {
          'check_in_type': 'daily',
          'daily': completeDailyDraft.dailyJson(),
        },
        pendingSyncCount: 1,
        localDate: '2026-07-26',
      );

      expect(status.requiredMode, CheckInMode.weekly);
      expect(status.daily?['sleep_hours'], 7.5);
      expect(status.hasTodayLog, isTrue);
      expect(status.isComplete, isFalse);
    },
  );

  test('status parses the thirty-day baseline refresh contract', () {
    final status = CheckInStatus.fromJson({
      'required_mode': 'daily',
      'has_today_log': false,
      'requires_baseline_refresh': true,
      'baseline_refresh_reason': 'thirty_day_return',
      'last_logged_date': '2026-06-28',
      'days_since_last_log': 30,
      'schedule': <String, dynamic>{},
      'existing_check_in': <String, dynamic>{},
    });

    expect(status.requiresBaselineRefresh, isTrue);
    expect(status.baselineRefreshReason, 'thirty_day_return');
    expect(status.lastLoggedDate, '2026-06-28');
    expect(status.daysSinceLastLog, 30);
    expect(status.isComplete, isFalse);
  });
}
