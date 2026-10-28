import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/features/log/data/log_api.dart';
import 'package:vitalysync/features/streaks/data/streak_models.dart';

String daysAgo(int days) {
  final now = DateTime.now();
  return DateTime.utc(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: days)).toIso8601String().substring(0, 10);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'active count expires on calendar days while preserving recent logs',
    () {
      final now = DateTime(2026, 6, 6, 0, 1);
      expect(LogApi.activeStreakCount(7, '2026-06-06', now: now), 7);
      expect(LogApi.activeStreakCount(7, '2026-06-05', now: now), 7);
      expect(LogApi.activeStreakCount(7, '2026-06-04', now: now), 0);
      expect(LogApi.activeStreakCount(7, '2026-06-01', now: now), 0);
      expect(LogApi.activeStreakCount(7, null, now: now), 0);
    },
  );

  test('cached streak overview expires without losing the personal best', () {
    final overview = StreakOverview.fromJson({
      'streak': {
        'current_streak': 7,
        'longest_streak': 12,
        'last_logged_date': daysAgo(5),
      },
    }, isOffline: true);

    expect(overview.streak.currentStreak, 0);
    expect(overview.streak.longestStreak, 12);
  });

  test(
    'cache refresh expires a streak even with no pending check-ins',
    () async {
      final streak = {
        'current_streak': 7,
        'longest_streak': 12,
        'last_logged_date': daysAgo(5),
      };
      SharedPreferences.setMockInitialValues({
        'user_id': 1,
        'log_streak': 7,
        'longest_log_streak': 12,
        'last_log_date': daysAgo(5),
        'synced_log_streak_1': jsonEncode(streak),
      });

      expect(await LogApi.syncPendingLogs(), 0);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('log_streak'), 0);
      expect(prefs.getInt('longest_log_streak'), 12);
      // Keep the server snapshot for reconciling queued historical logs.
      expect(jsonDecode(prefs.getString('synced_log_streak_1')!), streak);
    },
  );

  test(
    'offline retries across both queues only count a new date once',
    () async {
      SharedPreferences.setMockInitialValues({
        'user_id': 1,
        'synced_log_streak_1': jsonEncode({
          'current_streak': 7,
          'longest_streak': 12,
          'last_logged_date': daysAgo(1),
        }),
        'offline_pending_logs_1': jsonEncode([
          {'log_date': daysAgo(0)},
          {'log_date': daysAgo(1)},
          {'log_date': daysAgo(2)},
        ]),
        'unified_pending_check_ins_v1_1': jsonEncode([
          {'log_date': daysAgo(0), 'daily': <String, dynamic>{}},
        ]),
      });

      final streak = await http.runWithClient(
        LogApi.syncStreakFromBackend,
        () => MockClient((_) async => throw http.ClientException('offline')),
      );

      expect(streak?['current_streak'], 8);
      expect(streak?['longest_streak'], 12);
      expect(streak?['last_logged_date'], daysAgo(0));
    },
  );
}
