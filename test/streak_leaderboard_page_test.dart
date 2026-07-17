import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/features/streaks/data/streak_api.dart';
import 'package:vitalysync/features/streaks/data/streak_models.dart';
import 'package:vitalysync/features/streaks/presentation/pages/streak_leaderboard_page.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(configureTestAssets);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  tearDownAll(clearTestAssets);

  testWidgets('shows centered 3-by-2 filters and minimal streak rows', (
    tester,
  ) async {
    final calls = <_LeaderboardCall>[];

    Future<StreakLeaderboard> load({
      required String section,
      required String metric,
      required int limit,
    }) async {
      calls.add(_LeaderboardCall(section, metric, limit));
      return _leaderboard(
        section: section,
        metric: metric,
        score: metric == 'longest' ? 31 : 12,
      );
    }

    await _pumpLeaderboard(tester, load);

    expect(
      tester.getSize(find.byKey(const ValueKey('leaderboard-hero'))).height,
      lessThanOrEqualTo(135),
    );
    expect(find.text('Global'), findsOneWidget);
    expect(find.text('Local'), findsOneWidget);
    expect(find.text('Role'), findsOneWidget);
    expect(find.text('Goal'), findsNothing);
    expect(
      find.byKey(const ValueKey('leaderboard-option-current')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('leaderboard-option-longest')),
      findsOneWidget,
    );
    expect(find.text('Month'), findsNothing);

    final sectionWrap = tester.widget<Wrap>(
      find.descendant(
        of: find.byKey(const ValueKey('leaderboard-section-options')),
        matching: find.byType(Wrap),
      ),
    );
    final metricWrap = tester.widget<Wrap>(
      find.descendant(
        of: find.byKey(const ValueKey('leaderboard-metric-options')),
        matching: find.byType(Wrap),
      ),
    );
    expect(sectionWrap.alignment, WrapAlignment.center);
    expect(metricWrap.alignment, WrapAlignment.center);

    expect(find.byKey(const ValueKey('leaderboard-avatar-2')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('leaderboard-podium-user-2')),
      findsOneWidget,
    );
    expect(find.text('Taylor'), findsOneWidget);
    expect(find.text('12 days'), findsOneWidget);
    expect(find.text('Current streak'), findsNothing);
    expect(find.text('#1'), findsNothing);
    expect(find.textContaining('protected day'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('leaderboard-option-longest')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(calls.last.section, 'global');
    expect(calls.last.metric, 'longest');
    expect(find.text('31 days'), findsOneWidget);
    expect(find.text('Best streak'), findsNothing);
    expect(calls.first.limit, 50);

    await tester.tap(find.byKey(const ValueKey('leaderboard-option-area')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(calls.last.section, 'area');
    expect(calls.last.metric, 'longest');

    await tester.tap(find.byKey(const ValueKey('leaderboard-option-role')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(calls.last.section, 'role');
    expect(calls.last.metric, 'longest');
  });

  testWidgets('uses a top-three podium and numbered rows through rank 50', (
    tester,
  ) async {
    Future<StreakLeaderboard> load({
      required String section,
      required String metric,
      required int limit,
    }) async {
      return _leaderboard(
        section: section,
        metric: metric,
        score: 50,
        ranks: const [1, 3, 4, 50, 51],
      );
    }

    await _pumpLeaderboard(tester, load);

    expect(find.byKey(const ValueKey('leaderboard-podium')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('leaderboard-podium-user-2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('leaderboard-podium-user-4')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('leaderboard-ranked-list')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('leaderboard-number-row-5')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('leaderboard-number-marker-5')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('leaderboard-number-row-51')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('leaderboard-number-marker-51')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('leaderboard-divider-4')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('leaderboard-number-row-52')),
      findsNothing,
    );

    expect(
      find.byKey(const ValueKey('leaderboard-podium-user-5')),
      findsNothing,
    );
    expect(find.text('50'), findsOneWidget);
    expect(find.text('#50'), findsNothing);
    expect(find.byKey(const ValueKey('leaderboard-avatar-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('leaderboard-avatar-5')), findsOneWidget);
    expect(find.byKey(const ValueKey('leaderboard-avatar-51')), findsOneWidget);
    expect(find.textContaining('protected day'), findsNothing);
  });

  testWidgets('uses the signed-in role and gender for current user avatar', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'user_id': 2,
      'gender': 'Female',
      'user_type': 'Student',
    });

    Future<StreakLeaderboard> load({
      required String section,
      required String metric,
      required int limit,
    }) async {
      return _leaderboard(
        section: section,
        metric: metric,
        score: 12,
        currentUserId: 2,
      );
    }

    await _pumpLeaderboard(tester, load);
    await tester.pumpAndSettle();

    final image = tester.widget<Image>(
      find.descendant(
        of: find.byKey(const ValueKey('leaderboard-avatar-2')),
        matching: find.byType(Image),
      ),
    );
    final provider = image.image as AssetImage;

    expect(provider.assetName, 'assets/images/female Student.png');
  });

  testWidgets('puts rank four in the list below a partial top three', (
    tester,
  ) async {
    Future<StreakLeaderboard> load({
      required String section,
      required String metric,
      required int limit,
    }) async {
      return _leaderboard(
        section: section,
        metric: metric,
        score: 20,
        rowCount: 4,
      );
    }

    await _pumpLeaderboard(tester, load);

    for (var userId = 2; userId <= 4; userId++) {
      expect(
        find.byKey(ValueKey('leaderboard-podium-user-$userId')),
        findsOneWidget,
      );
    }
    final firstPlace = tester.getTopLeft(
      find.byKey(const ValueKey('leaderboard-podium-user-2')),
    );
    final secondPlace = tester.getTopLeft(
      find.byKey(const ValueKey('leaderboard-podium-user-3')),
    );
    final thirdPlace = tester.getTopLeft(
      find.byKey(const ValueKey('leaderboard-podium-user-4')),
    );
    expect(secondPlace.dx, lessThan(firstPlace.dx));
    expect(firstPlace.dx, lessThan(thirdPlace.dx));
    expect(firstPlace.dy, lessThan(secondPlace.dy));
    expect(secondPlace.dy, lessThan(thirdPlace.dy));
    expect(
      find.byKey(const ValueKey('leaderboard-podium-user-5')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('leaderboard-number-row-5')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('retry reloads the selected leaderboard after an API error', (
    tester,
  ) async {
    var attempts = 0;

    Future<StreakLeaderboard> load({
      required String section,
      required String metric,
      required int limit,
    }) async {
      attempts++;
      if (attempts == 1) {
        throw const StreakApiException('Leaderboard service is unavailable.');
      }
      return _leaderboard(section: section, metric: metric, score: 7);
    }

    await _pumpLeaderboard(tester, load);

    expect(find.text('Unable to load rankings'), findsOneWidget);
    expect(find.text('Leaderboard service is unavailable.'), findsOneWidget);

    await tester.ensureVisible(find.text('Try again'));
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(attempts, 2);
    expect(find.text('Taylor'), findsOneWidget);
    expect(find.text('7 days'), findsOneWidget);
    expect(find.text('Unable to load rankings'), findsNothing);
  });

  testWidgets('filters and streak rows remain usable on a narrow screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    Future<StreakLeaderboard> load({
      required String section,
      required String metric,
      required int limit,
    }) async {
      return _leaderboard(
        section: section,
        metric: metric,
        score: 10800,
        rowCount: 12,
        firstDisplayName: 'A very long leaderboard username',
      );
    }

    await _pumpLeaderboard(
      tester,
      load,
      textScaler: const TextScaler.linear(1.2),
      mediaSize: const Size(320, 700),
    );

    expect(find.text('Global'), findsOneWidget);
    expect(find.text('Local'), findsOneWidget);
    expect(find.text('Role'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('leaderboard-option-current')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('leaderboard-option-longest')),
      findsOneWidget,
    );
    expect(find.text('A very long leaderboard username'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const ValueKey('leaderboard-number-row-13')),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('leaderboard-number-marker-13')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpLeaderboard(
  WidgetTester tester,
  StreakLeaderboardLoader loader, {
  TextScaler textScaler = TextScaler.noScaling,
  Size mediaSize = const Size(390, 844),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: mediaSize,
          disableAnimations: true,
          textScaler: textScaler,
        ),
        child: StreakLeaderboardPage(loadLeaderboard: loader),
      ),
    ),
  );
  await tester.pump();
}

StreakLeaderboard _leaderboard({
  required String section,
  required String metric,
  required int score,
  int rowCount = 1,
  List<int>? ranks,
  String firstDisplayName = 'Taylor',
  int? currentUserId,
}) {
  final resolvedRanks =
      ranks ?? List<int>.generate(rowCount, (index) => index + 1);
  final rows = <StreakLeaderboardRow>[];

  for (var index = 0; index < resolvedRanks.length; index++) {
    final rank = resolvedRanks[index];
    final rowScore = score - index;
    rows.add(
      StreakLeaderboardRow(
        rank: rank,
        userId: rank + 1,
        displayName: index == 0 ? firstDisplayName : 'User $rank',
        initials: 'U$rank',
        avatarColor: '#1D8CA8',
        score: rowScore > 0 ? rowScore : 0,
        protectedDayCount: 3,
        isCurrentUser: currentUserId == rank + 1,
      ),
    );
  }

  return StreakLeaderboard(
    section: section,
    metric: metric,
    available: true,
    sectionLabel: switch (section) {
      'area' => 'Manila',
      'role' => 'Student',
      _ => 'Global',
    },
    currentUserRank: null,
    rows: rows,
  );
}

class _LeaderboardCall {
  const _LeaderboardCall(this.section, this.metric, this.limit);

  final String section;
  final String metric;
  final int limit;
}
