import 'package:shared_preferences/shared_preferences.dart';

import '../../adaptive/data/adaptive_nudge_api.dart';
import '../../adaptive/data/insight_report_api.dart';
import '../../dashboard/data/burnout_score_api.dart';

class RecoveryModeSnapshot {
  final int userId;
  final bool isActive;
  final double? score;
  final String riskLevel;
  final DateTime? activatedAt;
  final BurnoutScoreSnapshot? latestScore;
  final BurnoutPatternSummary? patternSummary;
  final List<AdaptiveNudgeRecommendation> nudges;
  final List<InsightReport> insightReports;
  final bool supportGenerated;

  const RecoveryModeSnapshot({
    required this.userId,
    required this.isActive,
    required this.score,
    required this.riskLevel,
    required this.activatedAt,
    required this.latestScore,
    required this.patternSummary,
    required this.nudges,
    required this.insightReports,
    required this.supportGenerated,
  });

  int? get scorePercent => score?.round().clamp(0, 100);

  AdaptiveNudgeRecommendation? get primaryNudge {
    if (nudges.isEmpty) {
      return null;
    }

    return nudges.first;
  }

  BurnoutPatternInsight? get primaryPattern {
    final patterns =
        patternSummary?.patterns ?? const <BurnoutPatternInsight>[];
    if (patterns.isEmpty) {
      return null;
    }

    return patterns.first;
  }
}

// Retired score-triggered intervention. Exercise recovery safeguards use the
// current sleep and energy observations in ExerciseRecoveryAssessment instead.
class RecoveryModeService {
  RecoveryModeService._();
  static final instance = RecoveryModeService._();
  static const double criticalThreshold = 75; // Legacy page compatibility only.
  Future<RecoveryModeSnapshot?> evaluate({bool generateSupport = true}) async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys().where(
      (key) => key.startsWith('recovery_mode_'),
    )) {
      await prefs.remove(key);
    }
    return null;
  }
}
