import 'package:shared_preferences/shared_preferences.dart';

import '../../adaptive/data/adaptive_nudge_api.dart';
import '../../adaptive/data/insight_report_api.dart';
import '../../dashboard/data/burnout_score_api.dart';
import '../../../shared/preferences/user_session.dart';

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

class RecoveryModeService {
  RecoveryModeService._();

  static final RecoveryModeService instance = RecoveryModeService._();

  static const double criticalThreshold = 75;
  static const double stableScoreThreshold = 70;
  static const double stableAverageThreshold = 70;
  static const String _activeKeyPrefix = 'recovery_mode_active_';
  static const String _scoreKeyPrefix = 'recovery_mode_last_score_';
  static const String _riskKeyPrefix = 'recovery_mode_last_risk_';
  static const String _activatedAtKeyPrefix = 'recovery_mode_activated_at_';

  Future<RecoveryModeSnapshot?> evaluate({bool generateSupport = true}) async {
    final session = await UserSessionController.instance.load();
    final userId = session.userId;
    if (!session.isLoggedIn ||
        !session.hasAuthToken ||
        userId == null ||
        userId <= 0) {
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final storedActive = prefs.getBool(_activeKey(userId)) ?? false;
    BurnoutPatternSummary? patternSummary;
    BurnoutScoreSnapshot? latestScore;

    try {
      patternSummary = await BurnoutScoreApi.fetchPatternSummary();
      latestScore = patternSummary?.latestScore;
    } catch (_) {
      patternSummary = null;
    }

    latestScore ??= await BurnoutScoreApi.fetchLatestScore();

    final latestScoreValue = latestScore?.overallScore;
    final storedScore = prefs.getDouble(_scoreKey(userId));
    final score = latestScoreValue ?? storedScore;
    final riskLevel = latestScore?.riskLevel.trim().isNotEmpty == true
        ? latestScore!.riskLevel
        : prefs.getString(_riskKey(userId)) ?? 'elevated';

    final isCritical = _isCriticalScore(score, riskLevel);
    final isStable = _hasStablePattern(patternSummary, latestScore);
    var active = storedActive;

    if (isCritical) {
      active = true;
      await _persistActiveState(
        prefs,
        userId: userId,
        score: score,
        riskLevel: riskLevel,
        wasActive: storedActive,
      );
    } else if (storedActive && isStable) {
      await _clearActiveState(prefs, userId);
      return null;
    }

    if (!active) {
      return null;
    }

    if (latestScore != null) {
      await _persistLastScore(
        prefs,
        userId: userId,
        score: latestScore.overallScore,
        riskLevel: latestScore.riskLevel,
      );
    }

    final support = await _loadSupport(generateSupport: generateSupport);
    return RecoveryModeSnapshot(
      userId: userId,
      isActive: true,
      score: score,
      riskLevel: riskLevel,
      activatedAt: _readActivatedAt(prefs, userId),
      latestScore: latestScore,
      patternSummary: patternSummary,
      nudges: support.nudges,
      insightReports: support.reports,
      supportGenerated: support.generated,
    );
  }

  bool _isCriticalScore(double? score, String riskLevel) {
    final normalizedRisk = riskLevel.trim().toLowerCase();
    return (score != null && score >= criticalThreshold) ||
        normalizedRisk == 'critical';
  }

  bool _hasStablePattern(
    BurnoutPatternSummary? summary,
    BurnoutScoreSnapshot? latestScore,
  ) {
    if (summary == null) {
      return false;
    }

    final score =
        latestScore?.overallScore ?? summary.latestScore?.overallScore;
    if (score == null || score >= criticalThreshold) {
      return false;
    }

    final sevenDay = summary.windowForDays(7);
    final points = sevenDay?.points ?? summary.timeline;
    final enoughRecentData =
        points.length >= 3 || (sevenDay?.coveragePercent ?? 0) >= 40;
    if (!enoughRecentData) {
      return false;
    }

    final trend = (sevenDay?.trendDirection ?? '').trim().toLowerCase();
    final stableTrend =
        trend == 'stable' ||
        trend == 'steady' ||
        trend == 'falling' ||
        trend == 'decreasing' ||
        trend == 'flat';
    final average = sevenDay?.averageScore;
    final hasRecentCriticalPoint = points.any(
      (point) => point.overallScore >= criticalThreshold,
    );

    return score <= stableScoreThreshold &&
        (average == null || average <= stableAverageThreshold) &&
        stableTrend &&
        !hasRecentCriticalPoint;
  }

  Future<_RecoverySupport> _loadSupport({required bool generateSupport}) async {
    var generated = false;
    var nudges = const <AdaptiveNudgeRecommendation>[];
    var reports = const <InsightReport>[];

    try {
      final response = await AdaptiveNudgeApi.fetchRecommendations(
        limit: 3,
        record: generateSupport,
        ai: true,
      );
      nudges = response.recommendations;
      generated = generateSupport && nudges.isNotEmpty;
    } catch (_) {
      nudges = const <AdaptiveNudgeRecommendation>[];
    }

    try {
      reports = generateSupport
          ? await InsightReportApi.refreshReports()
          : await InsightReportApi.listReports(limit: 3);
      if (reports.isEmpty) {
        reports = await InsightReportApi.listReports(limit: 3);
      }
      generated = generated || (generateSupport && reports.isNotEmpty);
    } catch (_) {
      try {
        reports = await InsightReportApi.listReports(limit: 3);
      } catch (_) {
        reports = const <InsightReport>[];
      }
    }

    return _RecoverySupport(
      nudges: nudges,
      reports: reports,
      generated: generated,
    );
  }

  Future<void> _persistActiveState(
    SharedPreferences prefs, {
    required int userId,
    required double? score,
    required String riskLevel,
    required bool wasActive,
  }) async {
    await prefs.setBool(_activeKey(userId), true);
    if (!wasActive || prefs.getString(_activatedAtKey(userId)) == null) {
      await prefs.setString(
        _activatedAtKey(userId),
        DateTime.now().toIso8601String(),
      );
    }
    await _persistLastScore(
      prefs,
      userId: userId,
      score: score,
      riskLevel: riskLevel,
    );
  }

  Future<void> _persistLastScore(
    SharedPreferences prefs, {
    required int userId,
    required double? score,
    required String riskLevel,
  }) async {
    if (score != null) {
      await prefs.setDouble(_scoreKey(userId), score);
    }

    final normalizedRisk = riskLevel.trim();
    if (normalizedRisk.isNotEmpty) {
      await prefs.setString(_riskKey(userId), normalizedRisk);
    }
  }

  Future<void> _clearActiveState(SharedPreferences prefs, int userId) async {
    await prefs.remove(_activeKey(userId));
    await prefs.remove(_scoreKey(userId));
    await prefs.remove(_riskKey(userId));
    await prefs.remove(_activatedAtKey(userId));
  }

  DateTime? _readActivatedAt(SharedPreferences prefs, int userId) {
    return DateTime.tryParse(prefs.getString(_activatedAtKey(userId)) ?? '');
  }

  String _activeKey(int userId) => '$_activeKeyPrefix$userId';
  String _scoreKey(int userId) => '$_scoreKeyPrefix$userId';
  String _riskKey(int userId) => '$_riskKeyPrefix$userId';
  String _activatedAtKey(int userId) => '$_activatedAtKeyPrefix$userId';
}

class _RecoverySupport {
  final List<AdaptiveNudgeRecommendation> nudges;
  final List<InsightReport> reports;
  final bool generated;

  const _RecoverySupport({
    required this.nudges,
    required this.reports,
    required this.generated,
  });
}
