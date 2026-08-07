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

  testWidgets('assistant uses a thin scaled surface in landscape', (
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
    final scaleViewport = find.byKey(
      const ValueKey('assistant-landscape-content-scale'),
    );
    final layoutCanvas = find.byKey(
      const ValueKey('assistant-landscape-layout-canvas'),
    );

    expect(surfaceSize, const Size(704, 320));
    expect(tester.getCenter(surface).dx, 500);
    expect(
      tester.getSize(layoutCanvas).width,
      greaterThan(tester.getSize(scaleViewport).width * 1.35),
    );
    expect(
      tester.getSize(layoutCanvas).height,
      greaterThan(tester.getSize(scaleViewport).height * 1.35),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('landscape quick hydration stays inside the thin surface', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 450));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpTestApp(tester, _assistantPanel());
    await tester.pump();
    await tester.tap(find.text('Log water'));
    await tester.pump();

    final surface = find.byKey(
      const ValueKey('assistant-experience-panel-surface'),
    );
    final hydration = find.byKey(
      const ValueKey('assistant-hydration-quick-log'),
    );
    final quickLogBar = find.byKey(const ValueKey('assistant-quick-log-bar'));
    final surfaceRect = tester.getRect(surface);
    final hydrationRect = tester.getRect(hydration);
    final quickLogRect = tester.getRect(quickLogBar);

    expect(hydration, findsOneWidget);
    expect(hydrationRect.top, greaterThanOrEqualTo(surfaceRect.top));
    expect(hydrationRect.bottom, lessThanOrEqualTo(quickLogRect.top));
    expect(quickLogRect.bottom, lessThanOrEqualTo(surfaceRect.bottom));
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
    expect(
      find.byKey(const ValueKey('assistant-landscape-content-scale')),
      findsNothing,
    );
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
