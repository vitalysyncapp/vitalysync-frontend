import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/features/log/data/check_in_models.dart';
import 'package:vitalysync/shared/assistant/floating_smart_nudge_assistant.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(configureTestAssets);
  tearDownAll(clearTestAssets);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('assistant uses a compact centered surface in landscape', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 450));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpTestApp(tester, _assistantPanel());
    await tester.pump();

    final surface = find.byKey(
      const ValueKey('assistant-experience-panel-surface'),
    );
    final surfaceSize = tester.getSize(surface);

    expect(surfaceSize.width, 664);
    expect(tester.getCenter(surface).dx, 500);
    expect(tester.takeException(), isNull);
  });

  testWidgets('assistant keeps its edge-to-edge portrait sizing', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpTestApp(tester, _assistantPanel());
    await tester.pump();

    final surface = find.byKey(
      const ValueKey('assistant-experience-panel-surface'),
    );

    expect(tester.getSize(surface).width, 374);
    expect(tester.getCenter(surface).dx, 195);
    expect(tester.takeException(), isNull);
  });
}

Widget _assistantPanel() {
  return AssistantExperiencePanel(
    message: 'Take a calm moment.',
    emoji: 'heart',
    recommendations: const [],
    adaptiveNudges: const [],
    hasLoadedAdaptiveNudges: true,
    hasLoadedNutritionInsight: true,
    onRefreshRecommendations: () async => const [],
    onRefreshAdaptiveNudges: ({bool forceRefresh = false}) async => const [],
    onRefreshNutritionInsight: ({bool forceRefresh = false}) async => null,
    onRefreshEnvironment: () async => null,
    checkInStatusLoader: () async => _incompleteStatus,
    todayLogLoader: () async => {
      'streak': {'current_streak': 0},
    },
    useSafeAreaPadding: false,
  );
}

const _incompleteStatus = CheckInStatus(
  requiredMode: CheckInMode.daily,
  hasTodayLog: false,
  schedule: CheckInSchedule(),
);
