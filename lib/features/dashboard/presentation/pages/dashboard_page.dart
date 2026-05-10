import 'package:flutter/material.dart';

import '../../../../features/adaptive/data/adaptive_nudge_api.dart';
import '../../../../features/activity/data/activity_service.dart';
import '../../../../features/activity/presentation/widgets/activity_summary_card.dart';
import '../../data/weekly_user_metrics.dart';
import '../../data/burnout_score_api.dart';
import '../../../../shared/notifications/notification_feed_service.dart';
import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/app_bar.dart';
import '../../../../shared/widgets/reveal_on_build.dart';
import '../widgets/burnout_risk_trend_card.dart';
import '../widgets/dashboard_header_card.dart';
import '../widgets/dashboard_stat_card.dart';
import '../widgets/mood_volatility_card.dart';
import '../widgets/nutrition_analytics_card.dart';
import '../widgets/sleep_pattern_card.dart';
import '../widgets/symptom_frequency_card.dart';
import '../widgets/weekly_performance_card.dart';
import '../widgets/wellness_index_card.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  BurnoutPatternSummary? _burnoutPatternSummary;
  AdaptiveNudgeRecommendation? _aiInsightNudge;
  bool _isLoadingBurnoutPatterns = true;
  bool _isLoadingAiInsight = true;
  int _refreshVersion = 0;

  @override
  void initState() {
    super.initState();
    _loadBurnoutPatterns();
  }

  Future<void> _loadBurnoutPatterns() async {
    setState(() {
      _isLoadingBurnoutPatterns = true;
      _isLoadingAiInsight = true;
    });

    try {
      final summary = await BurnoutScoreApi.fetchPatternSummary();
      AdaptiveNudgeRecommendation? aiInsight;
      try {
        final nudgeResponse = await AdaptiveNudgeApi.fetchRecommendations(
          limit: 1,
          record: false,
          ai: true,
        );
        aiInsight = nudgeResponse.recommendations.isEmpty
            ? null
            : nudgeResponse.recommendations.first;
      } catch (_) {
        aiInsight = null;
      }
      if (!mounted) return;

      setState(() {
        _burnoutPatternSummary = summary;
        _aiInsightNudge = aiInsight;
        _isLoadingBurnoutPatterns = false;
        _isLoadingAiInsight = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _burnoutPatternSummary = null;
        _aiInsightNudge = null;
        _isLoadingBurnoutPatterns = false;
        _isLoadingAiInsight = false;
      });
    }
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      _refreshVersion++;
    });

    await Future.wait([
      ActivityService.instance.refresh(),
      _loadBurnoutPatterns(),
      refreshAppBarStreak(),
      refreshNotificationFeed(),
    ]);
  }

  String _burnoutRiskValue() {
    final score = _burnoutPatternSummary?.latestScore;
    if (_isLoadingBurnoutPatterns) {
      return '--';
    }

    return score == null ? '--' : score.overallScore.round().toString();
  }

  String _burnoutRiskSubtitle() {
    final summary = _burnoutPatternSummary;
    if (_isLoadingBurnoutPatterns) {
      return 'Loading trend';
    }
    if (summary == null || summary.latestScore == null) {
      return 'No score history yet';
    }

    final sevenDay = summary.windowForDays(7);
    final delta = sevenDay?.deltaFromStart;
    if (delta == null) {
      return summary.adaptiveState.label;
    }

    final prefix = delta > 0 ? '+' : '';
    return '$prefix${delta.toStringAsFixed(1)} over 7 days';
  }

  Color _burnoutTrendColor() {
    final trend = _burnoutPatternSummary?.windowForDays(7)?.trendDirection;
    if (trend == 'falling') {
      return Colors.green;
    }
    if (trend == 'rising') {
      return Colors.red;
    }

    return const Color(0xFF64748B);
  }

  IconData _burnoutTrendIcon() {
    final trend = _burnoutPatternSummary?.windowForDays(7)?.trendDirection;
    if (trend == 'falling') {
      return Icons.trending_down;
    }
    if (trend == 'rising') {
      return Icons.trending_up;
    }

    return Icons.trending_flat;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: buildPageDecoration(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: buildAppBar(context),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshDashboard,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                children: [
                  const RevealOnBuild(child: DashboardHeaderCard()),
                  const SizedBox(height: 16),
                  RevealOnBuild(
                    delay: const Duration(milliseconds: 70),
                    child: Row(
                      children: [
                        DashboardStatCard(
                          title: "Burnout Risk",
                          value: _burnoutRiskValue(),
                          subtitle: _burnoutRiskSubtitle(),
                          subtitleColor: _burnoutTrendColor(),
                          icon: _burnoutTrendIcon(),
                          iconColor: _burnoutTrendColor(),
                        ),
                        const SizedBox(width: 12),
                        _AvgSleepStatCard(
                          key: ValueKey('avg-sleep-$_refreshVersion'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  RevealOnBuild(
                    delay: Duration(milliseconds: 130),
                    child: ValueListenableBuilder<ActivityTrackingState>(
                      valueListenable: ActivityService.instance.notifier,
                      builder: (context, activityState, _) {
                        return WeeklyStepAnalyticsCard(
                          state: activityState,
                          compact: true,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  RevealOnBuild(
                    delay: const Duration(milliseconds: 190),
                    child: NutritionAnalyticsCard(
                      key: ValueKey('nutrition-analytics-$_refreshVersion'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  RevealOnBuild(
                    delay: const Duration(milliseconds: 220),
                    child: BurnoutRiskTrendCard(
                      summary: _burnoutPatternSummary,
                      isLoading: _isLoadingBurnoutPatterns,
                      onRefresh: _loadBurnoutPatterns,
                    ),
                  ),
                  const SizedBox(height: 16),
                  RevealOnBuild(
                    delay: const Duration(milliseconds: 250),
                    child: _AiBurnoutInsightCard(
                      recommendation: _aiInsightNudge,
                      isLoading: _isLoadingAiInsight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  RevealOnBuild(
                    delay: const Duration(milliseconds: 310),
                    child: SleepPatternCard(
                      key: ValueKey('sleep-pattern-$_refreshVersion'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  RevealOnBuild(
                    delay: const Duration(milliseconds: 370),
                    child: WellnessIndexCard(
                      key: ValueKey('wellness-index-$_refreshVersion'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  RevealOnBuild(
                    delay: const Duration(milliseconds: 430),
                    child: MoodVolatilityCard(
                      key: ValueKey('mood-volatility-$_refreshVersion'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  RevealOnBuild(
                    delay: const Duration(milliseconds: 490),
                    child: SymptomFrequencyCard(
                      key: ValueKey('symptom-frequency-$_refreshVersion'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  RevealOnBuild(
                    delay: const Duration(milliseconds: 550),
                    child: WeeklyPerformanceCard(
                      key: ValueKey('weekly-performance-$_refreshVersion'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AvgSleepStatCard extends StatefulWidget {
  const _AvgSleepStatCard({super.key});

  @override
  State<_AvgSleepStatCard> createState() => _AvgSleepStatCardState();
}

class _AvgSleepStatCardState extends State<_AvgSleepStatCard> {
  late Future<_SleepStatSnapshot> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadSleepSnapshot();
  }

  Future<_SleepStatSnapshot> _loadSleepSnapshot() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentStart = today.subtract(const Duration(days: 6));
    final previousEnd = currentStart.subtract(const Duration(days: 1));
    final previousStart = previousEnd.subtract(const Duration(days: 6));

    final results = await Future.wait([
      WeeklyUserMetricsService.loadCurrentWeek(),
      WeeklyUserMetricsService.loadRange(
        start: previousStart,
        end: previousEnd,
      ),
    ]);

    return _SleepStatSnapshot(
      currentWeek: results[0],
      previousWeek: results[1],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_SleepStatSnapshot>(
      future: _future,
      builder: (context, snapshot) {
        final sleepSnapshot = snapshot.data;
        final currentAverage = sleepSnapshot?.currentWeek.averageSleep ?? 0;
        final previousAverage = sleepSnapshot?.previousWeek.averageSleep ?? 0;
        final delta = currentAverage - previousAverage;

        return DashboardStatCard(
          title: "Avg Sleep",
          value: currentAverage > 0
              ? "${currentAverage.toStringAsFixed(1)}h"
              : "--",
          subtitle: _subtitle(
            isLoading: snapshot.connectionState == ConnectionState.waiting,
            currentAverage: currentAverage,
            previousAverage: previousAverage,
            delta: delta,
          ),
          subtitleColor: _subtitleColor(
            isLoading: snapshot.connectionState == ConnectionState.waiting,
            currentAverage: currentAverage,
            delta: delta,
          ),
          icon: _trendIcon(
            isLoading: snapshot.connectionState == ConnectionState.waiting,
            currentAverage: currentAverage,
            delta: delta,
          ),
          iconColor: _subtitleColor(
            isLoading: snapshot.connectionState == ConnectionState.waiting,
            currentAverage: currentAverage,
            delta: delta,
          ),
        );
      },
    );
  }

  String _subtitle({
    required bool isLoading,
    required double currentAverage,
    required double previousAverage,
    required double delta,
  }) {
    if (isLoading) {
      return 'Loading trend';
    }
    if (currentAverage <= 0) {
      return 'No sleep logs yet';
    }
    if (previousAverage <= 0) {
      return 'Based on this week\'s chart';
    }

    final prefix = delta > 0 ? '+' : '';
    return '$prefix${delta.toStringAsFixed(1)}h from last week';
  }

  Color _subtitleColor({
    required bool isLoading,
    required double currentAverage,
    required double delta,
  }) {
    if (isLoading || currentAverage <= 0) {
      return const Color(0xFF64748B);
    }
    if (delta > 0.05) {
      return Colors.green;
    }
    if (delta < -0.05) {
      return Colors.red;
    }

    return const Color(0xFF64748B);
  }

  IconData _trendIcon({
    required bool isLoading,
    required double currentAverage,
    required double delta,
  }) {
    if (isLoading || currentAverage <= 0) {
      return Icons.trending_flat;
    }
    if (delta > 0.05) {
      return Icons.trending_up;
    }
    if (delta < -0.05) {
      return Icons.trending_down;
    }

    return Icons.trending_flat;
  }
}

class _SleepStatSnapshot {
  final WeeklyUserMetrics currentWeek;
  final WeeklyUserMetrics previousWeek;

  const _SleepStatSnapshot({
    required this.currentWeek,
    required this.previousWeek,
  });
}

class _AiBurnoutInsightCard extends StatelessWidget {
  final AdaptiveNudgeRecommendation? recommendation;
  final bool isLoading;

  const _AiBurnoutInsightCard({
    required this.recommendation,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final why = recommendation?.metadata['ai_why_this_matters']?.toString();
    final steps = recommendation?.metadata['ai_action_steps'] is List
        ? (recommendation!.metadata['ai_action_steps'] as List)
              .map((item) => item.toString())
              .where((item) => item.trim().isNotEmpty)
              .take(2)
              .toList()
        : const <String>[];
    final aiEnhanced = recommendation?.metadata['ai_enhanced'] == true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: isLoading
          ? const SizedBox(
              height: 72,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: aiEnhanced
                              ? const [
                                  Color.fromARGB(255, 105, 28, 183),
                                  Color(0xFF59B7EF),
                                ]
                              : const [Color(0xFF64748B), Color(0xFF94A3B8)],
                        ),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Insight',
                            style: TextStyle(
                              color: pagePrimaryTextColor(context),
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            aiEnhanced
                                ? 'Personalized from your pattern data'
                                : 'Rule-based fallback insight',
                            style: TextStyle(
                              color: pageSecondaryTextColor(context),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  recommendation?.title ?? 'Keep building your trend baseline',
                  style: TextStyle(
                    color: pagePrimaryTextColor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  recommendation?.message ??
                      'Complete a few more check-ins so VitalySync can personalize burnout insights more accurately.',
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: pageSecondaryTextColor(context),
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (why != null && why.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    why,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: pagePrimaryTextColor(context),
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (steps.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...steps.map(
                    (step) => Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 17,
                            color: Color(0xFF1FB489),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              step,
                              style: TextStyle(
                                color: pageSecondaryTextColor(context),
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
