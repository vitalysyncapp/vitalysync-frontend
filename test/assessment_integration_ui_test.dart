import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/features/assessment/data/assessment_api.dart';
import 'package:vitalysync/features/assessment/data/assessment_models.dart';
import 'package:vitalysync/features/assessment/data/assessment_store.dart';
import 'package:vitalysync/features/assessment/presentation/widgets/assessment_overview_card.dart';
import 'package:vitalysync/features/dashboard/data/weekly_user_metrics.dart';
import 'package:vitalysync/features/adaptive/data/adaptive_nudge_api.dart';
import 'package:vitalysync/features/adaptive/data/insight_report_api.dart';

class _Api extends AssessmentApi {
  final Future<List<AssessmentRecord>> Function() load;
  _Api(this.load);
  @override
  Future<AssessmentRecord?> latest(int userId) async =>
      (await load()).firstOrNull;
  @override
  Future<AssessmentHistory> history(int userId, {String? cursor}) async =>
      AssessmentHistory(await load(), null);
}

AssessmentRecord _record() => AssessmentRecord.fromJson({
  'assessment_id': '1',
  'submission_id': 'saved',
  'definition_version': 'cbi-pb-context-en-1.0.0',
  'completed_at': '2026-08-01T12:00:00Z',
  'completion_status': 'complete',
  'result': {'display_score': '54.2'},
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting('en'));
  setUp(() {
    SharedPreferences.setMockInitialValues({'user_id': 1});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (_) async => null,
        );
  });

  test(
    'cutover rejects obsolete advice and labels archived reports without rewriting them',
    () {
      final response = AdaptiveNudgeResponse.fromJson({
        'recommendations': [
          {'title': 'Old risk advice', 'metadata': {}},
          {
            'title': 'Approved action',
            'metadata': {'policy_version': 'cbi-wellness-1.0.0'},
          },
        ],
      });
      expect(response.recommendations.single.title, 'Approved action');
      expect(response.recommendations.single.userFacingSeverity, 'wellness');
      final archived = InsightReport.fromJson({
        'title': 'Original title',
        'summary': 'Original summary',
      });
      expect(archived.isLegacy, isTrue);
      expect(archived.methodologyLabel, contains('Legacy methodology'));
      expect(archived.title, 'Original title');
      expect(archived.summary, 'Original summary');
    },
  );

  Future<void> pump(
    WidgetTester tester,
    AssessmentApi api, {
    bool dark = false,
    bool observations = false,
  }) async {
    await tester.binding.setSurfaceSize(const Size(320, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: dark ? ThemeData.dark() : ThemeData.light(),
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: SingleChildScrollView(
              child: AssessmentOverviewCard(
                api: api,
                showObservations: observations,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'empty overview offers assessment history without a fabricated score or logging gate',
    (tester) async {
      await pump(tester, _Api(() async => []));
      expect(
        find.textContaining('No completed assessment yet.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('recording your daily wellness'),
        findsOneWidget,
      );
      expect(find.text('40 / 100'), findsNothing);
      expect(find.textContaining('risk band'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'dated CBI observations and optional reminder fit narrow dark large-text layouts',
    (tester) async {
      await pump(
        tester,
        _Api(() async => [_record()]),
        dark: true,
        observations: true,
      );
      expect(find.text('54.2 / 100'), findsOneWidget);
      expect(find.textContaining('Complete · Aug 1, 2026'), findsOneWidget);
      expect(find.text('Recorded CBI observations'), findsOneWidget);
      expect(find.textContaining('clinical conclusions'), findsOneWidget);
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isFalse,
      );
      expect(
        find.textContaining('Your last assessment was at least'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('offline overview identifies the saved dated result', (
    tester,
  ) async {
    await tester.runAsync(
      () => AssessmentStore.instance.cacheLatest(1, _record()),
    );
    await pump(tester, _Api(() async => throw Exception('offline')));
    expect(find.text('54.2 / 100'), findsOneWidget);
    expect(
      find.textContaining('Showing the last saved assessment'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  test(
    'wellness averages include recorded zeros while excluding absent days',
    () {
      final metrics = WeeklyUserMetrics(
        days: List.generate(
          3,
          (index) => DailyUserMetric(
            date: DateTime(2026, 10, index + 1),
            dateKey: '2026-10-0${index + 1}',
            dayLabel: '$index',
            log: index == 2
                ? null
                : {
                    'sleep_hours': index == 0 ? 0 : 8,
                    'hydration_liters': index == 0 ? 0 : 2,
                  },
            activity: null,
          ),
        ),
      );
      expect(metrics.sleepRecordedDays, 2);
      expect(metrics.averageSleep, 4);
      expect(metrics.hydrationRecordedDays, 2);
      expect(metrics.averageHydration, 1);
      expect(metrics.activityRecordedDays, 0);
    },
  );
}
