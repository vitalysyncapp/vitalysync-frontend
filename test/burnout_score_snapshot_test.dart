import 'package:flutter_test/flutter_test.dart';
import 'package:vitalysync/features/dashboard/data/burnout_score_api.dart';

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
}
