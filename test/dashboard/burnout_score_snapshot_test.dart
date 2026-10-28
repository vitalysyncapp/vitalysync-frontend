import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalysync/features/dashboard/data/burnout_score_api.dart';
import 'package:vitalysync/features/dashboard/presentation/widgets/burnout_risk_trend_card.dart';

void main() {
  test(
    'burnout score parses weekly pulse freshness from its source snapshot',
    () {
      final score = BurnoutScoreSnapshot.fromJson({
        'score_date': '2026-05-22',
        'overall_score': 52,
        'risk_level': 'moderate',
        'confidence_score': 94,
        'completeness_score': 100,
        'scoring_version': 'phase3_v1',
        'missing_fields': <String>[],
        'contributing_factors': <Map<String, dynamic>>[],
        'source_snapshot': {
          'weekly_pulse': {
            'response_date': '2026-05-18',
            'due_date': '2026-05-18',
            'age_days': 4,
            'freshness': 'current',
          },
        },
      });

      expect(score.scoringVersion, 'phase3_v1');
      expect(score.weeklyContext, isNotNull);
      expect(score.weeklyContext!.responseDate, '2026-05-18');
      expect(score.weeklyContext!.ageDays, 4);
      expect(score.weeklyContext!.isCurrent, isTrue);
    },
  );

  test('burnout score supports daily-only context before the first pulse', () {
    final score = BurnoutScoreSnapshot.fromJson({
      'score_date': '2026-05-15',
      'overall_score': 36,
      'risk_level': 'moderate',
      'confidence_score': 90,
      'completeness_score': 100,
      'source_snapshot': {'weekly_pulse': null},
    });

    expect(score.weeklyContext, isNull);
  });

  test('burnout score parses backend-owned evidence basis', () {
    final score = BurnoutScoreSnapshot.fromJson({
      'baseline_epoch_id': 12,
      'score_date': '2026-07-28',
      'overall_score': 42,
      'risk_level': 'moderate',
      'confidence_score': 90,
      'completeness_score': 100,
      'scoring_version': 'burnout_engine_v4_decay_v1',
      'missing_fields': <String>[],
      'contributing_factors': <Map<String, dynamic>>[],
      'evidence_basis': {
        'scoring_version': 'burnout_engine_v4_decay_v1',
        'baseline_weight': 0.35,
        'baseline_epoch_started_at': '2026-07-28',
        'window_used': '1_day',
        'weekly_pulse_count_since_epoch': 0,
        'log_coverage_percent': 100,
        'confidence_score': 90,
        'missing_fields': <String>[],
        'top_factor_keys': ['sleep_recovery'],
      },
      'explanation_note':
          'This is a pattern estimate based on your recent logs, not a medical diagnosis.',
      'source_snapshot': {'weekly_pulse': null},
    });

    expect(score.baselineEpochId, 12);
    expect(score.evidenceBasis.baselineWeight, 0.35);
    expect(score.evidenceBasis.windowUsed, '1_day');
    expect(score.evidenceBasis.logCoveragePercent, 100);
    expect(score.evidenceBasis.topFactorKeys, ['sleep_recovery']);
    expect(score.explanationNote, contains('not a medical diagnosis'));
  });

  test('burnout pattern summary parses a refresh epoch marker', () {
    final summary = BurnoutPatternSummary.fromJson({
      'baseline_epoch': {
        'id': 14,
        'started_at': '2026-07-28',
        'reset_reason': 'thirty_day_return',
      },
      'windows': <String, dynamic>{},
      'patterns': <dynamic>[],
      'timeline': <dynamic>[],
    });

    expect(summary.baselineEpoch?.id, 14);
    expect(summary.baselineEpoch?.isRefresh, isTrue);
    expect(summary.baselineEpoch?.startedAt, '2026-07-28');
  });

  testWidgets('trend card labels a recent refreshed baseline', (tester) async {
    final summary = BurnoutPatternSummary.fromJson({
      'baseline_epoch': {
        'id': 14,
        'started_at': '2026-07-28',
        'reset_reason': 'thirty_day_return',
      },
      'windows': {
        '7_day': {
          'window_days': 7,
          'trend_direction': 'stable',
          'points': [
            {
              'score_date': '2026-07-28',
              'overall_score': 44,
              'risk_level': 'moderate',
              'confidence_score': 70,
            },
            {
              'score_date': '2026-07-29',
              'overall_score': 42,
              'risk_level': 'moderate',
              'confidence_score': 74,
            },
          ],
        },
      },
      'patterns': <dynamic>[],
      'timeline': <dynamic>[],
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BurnoutRiskTrendCard(summary: summary, isLoading: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Baseline refreshed · 2026-07-28'), findsOneWidget);
  });
}
