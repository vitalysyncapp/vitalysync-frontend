import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/features/log/data/check_in_models.dart';
import 'package:vitalysync/features/log/data/check_in_state_coordinator.dart';
import 'package:vitalysync/features/log/presentation/widgets/check_in_success_view.dart';
import 'package:vitalysync/shared/assistant/floating_smart_nudge_assistant.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(configureTestAssets);
  tearDownAll(clearTestAssets);

  testWidgets('shared completion view shows validation, streak, and redo', (
    tester,
  ) async {
    var redoPressed = false;

    await pumpTestApp(
      tester,
      SizedBox(
        height: 720,
        child: CheckInSuccessView(
          isOffline: false,
          hasPendingSync: false,
          pendingSyncCount: 0,
          currentStreak: 15,
          onRedo: () => redoPressed = true,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Check-in saved!'), findsOneWidget);
    expect(
      find.textContaining('Your daily wellness log has been recorded.'),
      findsOneWidget,
    );
    expect(find.text('15 day streak'), findsOneWidget);

    await tester.tap(find.text('Redo today\'s log'));
    expect(redoPressed, isTrue);
  });

  testWidgets('assistant orders check-in before exercise', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await _pumpAssistant(tester, status: _incompleteStatus);

    final nudgesX = tester.getCenter(find.text('Nudges')).dx;
    final checkInX = tester.getCenter(find.text('Check-in')).dx;
    final exerciseX = tester.getCenter(find.text('Exercise')).dx;

    expect(nudgesX, lessThan(checkInX));
    expect(checkInX, lessThan(exerciseX));
  });

  testWidgets('assistant refreshes to shared completion after external save', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    var status = _incompleteStatus;

    await _pumpAssistant(
      tester,
      statusLoader: () async => status,
      todayLogLoader: () async => {
        'streak': {'current_streak': 9},
      },
    );

    await tester.tap(find.text('Check-in'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Check-in saved!'), findsNothing);

    status = _completeStatus;
    CheckInStateCoordinator.instance.markChanged(Object());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Check-in saved!'), findsOneWidget);
    expect(find.text('9 day streak'), findsOneWidget);
    expect(find.text('Redo today\'s log'), findsOneWidget);
  });
}

Future<void> _pumpAssistant(
  WidgetTester tester, {
  CheckInStatus? status,
  Future<CheckInStatus> Function()? statusLoader,
  Future<Map<String, dynamic>> Function()? todayLogLoader,
}) async {
  await pumpTestApp(
    tester,
    SizedBox(
      width: 390,
      height: 700,
      child: AssistantExperiencePanel(
        message: 'Take a calm moment.',
        emoji: 'heart',
        recommendations: const [],
        adaptiveNudges: const [],
        hasLoadedAdaptiveNudges: true,
        hasLoadedNutritionInsight: true,
        onRefreshRecommendations: () async => const [],
        onRefreshAdaptiveNudges: ({bool forceRefresh = false}) async =>
            const [],
        onRefreshNutritionInsight: ({bool forceRefresh = false}) async => null,
        onRefreshEnvironment: () async => null,
        checkInStatusLoader: statusLoader ?? () async => status!,
        todayLogLoader:
            todayLogLoader ??
            () async => {
              'streak': {'current_streak': 0},
            },
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

const _incompleteStatus = CheckInStatus(
  requiredMode: CheckInMode.daily,
  hasTodayLog: false,
  schedule: CheckInSchedule(),
);

const _completeStatus = CheckInStatus(
  requiredMode: CheckInMode.daily,
  hasTodayLog: true,
  schedule: CheckInSchedule(),
);
