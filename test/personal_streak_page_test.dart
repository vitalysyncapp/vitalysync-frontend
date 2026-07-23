import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalysync/features/streaks/data/streak_models.dart';
import 'package:vitalysync/features/streaks/presentation/pages/personal_streak_page.dart';
import 'package:vitalysync/features/streaks/presentation/pages/streak_leaderboard_page.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(configureTestAssets);
  tearDownAll(clearTestAssets);

  testWidgets('shows global and local badges for top-100 current streaks', (
    tester,
  ) async {
    final calls = <_LeaderboardCall>[];

    Future<StreakLeaderboard> loadLeaderboard({
      required String section,
      required String metric,
      required int limit,
    }) async {
      calls.add(_LeaderboardCall(section, metric, limit));
      return _leaderboard(section: section, rank: section == 'global' ? 7 : 42);
    }

    await _pumpPage(tester, loadLeaderboard: loadLeaderboard);

    expect(
      find.byKey(const ValueKey('personal-streak-global-rank')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('personal-streak-local-rank')),
      findsOneWidget,
    );
    expect(find.text('Global #7'), findsOneWidget);
    expect(find.text('Local #42'), findsOneWidget);
    expect(find.bySemanticsLabel('Global streak rank 7'), findsOneWidget);
    expect(find.bySemanticsLabel('Local streak rank 42'), findsOneWidget);

    expect(calls, hasLength(2));
    expect(calls.map((call) => call.section).toSet(), {'global', 'area'});
    expect(calls.every((call) => call.metric == 'current'), isTrue);
    expect(calls.every((call) => call.limit == 100), isTrue);
  });

  testWidgets('includes ranks 1 and 100 in the badges', (tester) async {
    Future<StreakLeaderboard> loadLeaderboard({
      required String section,
      required String metric,
      required int limit,
    }) async {
      return _leaderboard(
        section: section,
        rank: section == 'global' ? 1 : 100,
      );
    }

    await _pumpPage(tester, loadLeaderboard: loadLeaderboard);

    expect(find.text('Global #1'), findsOneWidget);
    expect(find.text('Local #100'), findsOneWidget);
  });

  testWidgets('hides unavailable and out-of-range leaderboard badges', (
    tester,
  ) async {
    Future<StreakLeaderboard> loadLeaderboard({
      required String section,
      required String metric,
      required int limit,
    }) async {
      return _leaderboard(
        section: section,
        available: section != 'global',
        rank: section == 'global' ? 5 : 101,
      );
    }

    await _pumpPage(tester, loadLeaderboard: loadLeaderboard);

    expect(find.byKey(const ValueKey('personal-streak-ranks')), findsNothing);
    expect(find.textContaining('Global #'), findsNothing);
    expect(find.textContaining('Local #'), findsNothing);
  });

  testWidgets('keeps one badge when the other leaderboard request fails', (
    tester,
  ) async {
    Future<StreakLeaderboard> loadLeaderboard({
      required String section,
      required String metric,
      required int limit,
    }) async {
      if (section == 'area') throw Exception('Local ranking unavailable');
      return _leaderboard(section: section, rank: 9);
    }

    await _pumpPage(tester, loadLeaderboard: loadLeaderboard);

    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('Global #9'), findsOneWidget);
    expect(find.textContaining('Local #'), findsNothing);
    expect(find.text('Unable to load your streak right now.'), findsNothing);
  });

  testWidgets('refresh reloads the overview and both badge rankings', (
    tester,
  ) async {
    var overviewCalls = 0;
    final rankCalls = <String, int>{};

    Future<StreakOverview> loadOverview() async {
      overviewCalls++;
      return _overview(displayName: 'Test User $overviewCalls');
    }

    Future<StreakLeaderboard> loadLeaderboard({
      required String section,
      required String metric,
      required int limit,
    }) async {
      final call = (rankCalls[section] ?? 0) + 1;
      rankCalls[section] = call;
      final initialRank = section == 'global' ? 7 : 42;
      return _leaderboard(section: section, rank: initialRank + call - 1);
    }

    await _pumpPage(
      tester,
      loadOverview: loadOverview,
      loadLeaderboard: loadLeaderboard,
    );
    expect(find.text('Global #7'), findsOneWidget);
    expect(find.text('Local #42'), findsOneWidget);

    final refreshIndicator = tester.widget<RefreshIndicator>(
      find.byType(RefreshIndicator),
    );
    await refreshIndicator.onRefresh();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();

    expect(overviewCalls, 2);
    expect(rankCalls, {'global': 2, 'area': 2});
    expect(find.text('Test User 2'), findsOneWidget);
    expect(find.text('Global #8'), findsOneWidget);
    expect(find.text('Local #43'), findsOneWidget);
  });

  testWidgets('top-100 badges fit on a compact screen with scaled text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    Future<StreakLeaderboard> loadLeaderboard({
      required String section,
      required String metric,
      required int limit,
    }) async {
      return _leaderboard(section: section, rank: 100);
    }

    await _pumpPage(
      tester,
      loadOverview: () async =>
          _overview(displayName: 'A very long VitalySync display name'),
      loadLeaderboard: loadLeaderboard,
      mediaSize: const Size(320, 700),
      textScaler: const TextScaler.linear(1.2),
    );

    expect(find.text('Global #100'), findsOneWidget);
    expect(find.text('Local #100'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('streak saver help explains rewards and is easily dismissed', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      loadLeaderboard:
          ({required section, required metric, required limit}) async =>
              _leaderboard(section: section, rank: null),
    );

    await tester.tap(find.byKey(const ValueKey('streak-saver-help')));
    await tester.pumpAndSettle();

    expect(find.text('How streak savers work'), findsOneWidget);
    expect(find.textContaining('protect one missed day'), findsOneWidget);
    expect(find.textContaining('first 7-day streak'), findsOneWidget);
    expect(find.textContaining('10 check-ins'), findsOneWidget);
    expect(find.textContaining('4 days in a week'), findsOneWidget);
    expect(find.text('Got it'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('streak-saver-dialog-close')));
    await tester.pumpAndSettle();

    expect(find.text('How streak savers work'), findsNothing);
  });
}

Future<void> _pumpPage(
  WidgetTester tester, {
  StreakOverviewLoader? loadOverview,
  required StreakLeaderboardLoader loadLeaderboard,
  Size mediaSize = const Size(390, 844),
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: mediaSize,
          disableAnimations: true,
          textScaler: textScaler,
        ),
        child: PersonalStreakPage(
          loadOverview: loadOverview ?? () async => _overview(),
          loadLeaderboard: loadLeaderboard,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

StreakOverview _overview({String displayName = 'Test User'}) {
  return StreakOverview(
    userId: 1,
    displayName: displayName,
    streak: const StreakSnapshot(
      currentStreak: 3,
      longestStreak: 14,
      lastLoggedDate: '2026-07-16',
    ),
    savers: const StreakSavers(
      periodMonth: '2026-07-01',
      baseSavers: 3,
      earnedSavers: 0,
      usedSavers: 0,
      availableSavers: 3,
    ),
    protectedDayCount: 0,
    recentEvents: const [],
  );
}

StreakLeaderboard _leaderboard({
  required String section,
  required int? rank,
  bool available = true,
}) {
  return StreakLeaderboard(
    section: section,
    metric: 'current',
    available: available,
    sectionLabel: section == 'area' ? 'Manila' : 'Global',
    currentUserRank: rank,
    rows: const [],
  );
}

class _LeaderboardCall {
  const _LeaderboardCall(this.section, this.metric, this.limit);

  final String section;
  final String metric;
  final int limit;
}
