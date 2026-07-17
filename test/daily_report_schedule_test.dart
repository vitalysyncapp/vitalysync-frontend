import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/features/adaptive/data/daily_report_schedule.dart';
import 'package:vitalysync/features/adaptive/data/insight_report_api.dart';
import 'package:vitalysync/shared/offline/offline_cache_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'user_id': 42});
  });

  test('daily report is not due before 7 AM local time', () {
    final reportDate = DailyReportSchedule.reportDateDueAt(
      DateTime(2026, 7, 16, 6, 59),
    );

    expect(reportDate, isNull);
  });

  test('daily report becomes due at 7 AM for yesterday', () {
    final reportDate = DailyReportSchedule.reportDateDueAt(
      DateTime(2026, 7, 16, 7),
    );

    expect(reportDate, '2026-07-15');
  });

  test('daily report keeps the same target for the rest of the day', () {
    expect(
      DailyReportSchedule.reportDateDueAt(DateTime(2026, 7, 16, 23, 59)),
      '2026-07-15',
    );
  });

  test('daily report target crosses month, leap year, and year boundaries', () {
    expect(
      DailyReportSchedule.reportDateDueAt(DateTime(2026, 3, 1, 7)),
      '2026-02-28',
    );
    expect(
      DailyReportSchedule.reportDateDueAt(DateTime(2024, 3, 1, 7)),
      '2024-02-29',
    );
    expect(
      DailyReportSchedule.reportDateDueAt(DateTime(2026, 1, 1, 7)),
      '2025-12-31',
    );
  });

  test(
    'successful target date suppresses another generation that day',
    () async {
      final now = DateTime(2026, 7, 16, 7);
      expect(
        await InsightReportApi.isScheduledRefreshPending(now: now),
        isTrue,
      );

      await OfflineCacheStore.saveJson(
        namespace: scheduledInsightReportGenerationCacheNamespace,
        scope: '42',
        data: {'completed_report_date': '2026-07-15'},
      );

      expect(
        await InsightReportApi.isScheduledRefreshPending(now: now),
        isFalse,
      );
      expect(
        await InsightReportApi.isScheduledRefreshPending(
          now: DateTime(2026, 7, 17, 7),
        ),
        isTrue,
      );
    },
  );
}
