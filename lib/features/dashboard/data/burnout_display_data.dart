import '../../log/data/log_api.dart';
import '../../onboarding/services/onboarding_service.dart';
import 'burnout_score_api.dart';

/// The same source and wording for the home and dashboard risk estimates.
class BurnoutDisplayData {
  final BurnoutScoreSnapshot? latestScore;
  final BurnoutPatternSummary? patternSummary;
  final OnboardingDefaults baseline;
  final bool hasPendingCheckIn;

  const BurnoutDisplayData({
    this.latestScore,
    this.patternSummary,
    this.baseline = const OnboardingDefaults(),
    this.hasPendingCheckIn = false,
  });

  int? get score => (latestScore?.overallScore ?? baseline.initialBurnoutScore)
      ?.round()
      .clamp(0, 100);

  bool get isBaseline => latestScore == null && score != null;

  String get riskLevel =>
      latestScore?.riskLevel ??
      baseline.initialBurnoutLevel?.toLowerCase().replaceAll(' ', '_') ??
      'unknown';

  String get sourceLabel {
    if (hasPendingCheckIn) {
      return 'Check-in saved offline · estimate updates after sync';
    }
    if (isBaseline) return 'Baseline · complete a daily check-in to update';
    if (latestScore != null) {
      return 'Last check-in · ${LogApi.formatLogDateLabel(latestScore!.scoreDate)}';
    }
    return 'Complete your baseline or first check-in';
  }

  String get status {
    if (score == null) return 'No estimate yet';
    if (latestScore != null && latestScore!.confidenceScore < 55) {
      return 'Limited confidence · ${latestScore!.confidenceScore.round()}% confidence';
    }
    final level = riskLevel.replaceAll('_', ' ');
    if (level.isEmpty || level == 'unknown') return 'Estimate available';
    final label = '${level[0].toUpperCase()}${level.substring(1)} risk';
    return latestScore == null
        ? label
        : '$label · ${latestScore!.confidenceScore.round()}% confidence';
  }

  static Future<BurnoutDisplayData> load({bool forceRefresh = false}) async {
    final revision = BurnoutScoreApi.inputsRevision;
    final baseline = await OnboardingService.loadDefaults();
    final summary = await BurnoutScoreApi.fetchPatternSummary(
      forceRefresh: forceRefresh,
    );
    // The trend covers recent weeks. Returning users may have an older score.
    final latest =
        summary?.latestScore ??
        await BurnoutScoreApi.fetchLatestScore(forceRefresh: forceRefresh);
    final pending = await LogApi.pendingLogCount();
    if (revision != BurnoutScoreApi.inputsRevision) {
      return load(forceRefresh: forceRefresh);
    }
    return BurnoutDisplayData(
      latestScore: latest,
      patternSummary: summary,
      baseline: baseline,
      hasPendingCheckIn: pending > 0,
    );
  }
}
