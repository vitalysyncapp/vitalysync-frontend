import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../features/adaptive/data/adaptive_nudge_api.dart';
import '../../../../features/activity/data/activity_service.dart';
import '../../../../features/activity/presentation/widgets/activity_summary_card.dart';
import '../../data/weekly_user_metrics.dart';
import '../../data/burnout_score_api.dart';
import '../../../../shared/goals/user_goals.dart';
import '../../../../shared/learning/first_week_learning_service.dart';
import '../../../../shared/notifications/notification_feed_service.dart';
import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/app_bar.dart';
import '../../../../shared/widgets/analytics_animation.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../../shared/widgets/first_week_learning_pill.dart';
import '../../../../shared/widgets/reveal_on_build.dart';
import '../widgets/burnout_risk_trend_card.dart';
import '../widgets/dashboard_goal_tracking_card.dart';
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
  FirstWeekLearningState _firstWeekLearning =
      const FirstWeekLearningState.hidden();
  bool _isLoadingBurnoutPatterns = true;
  bool _isLoadingAiInsight = true;
  int _refreshVersion = 0;
  int _burnoutLoadToken = 0;
  int _firstWeekLoadToken = 0;

  @override
  void initState() {
    super.initState();
    BurnoutScoreApi.refreshSignal.addListener(_handleBurnoutInputsChanged);
    UserGoalsService.refreshSignal.addListener(_handleGoalsChanged);
    _loadBurnoutPatterns();
    unawaited(_loadFirstWeekLearning());
  }

  @override
  void dispose() {
    BurnoutScoreApi.refreshSignal.removeListener(_handleBurnoutInputsChanged);
    UserGoalsService.refreshSignal.removeListener(_handleGoalsChanged);
    super.dispose();
  }

  void _handleBurnoutInputsChanged() {
    _loadBurnoutPatterns();
    unawaited(_loadFirstWeekLearning());
  }

  void _handleGoalsChanged() {
    if (!mounted) {
      return;
    }

    setState(() {
      _refreshVersion++;
    });
  }

  Future<void> _loadBurnoutPatterns() async {
    final loadToken = ++_burnoutLoadToken;
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
      if (!mounted || loadToken != _burnoutLoadToken) return;

      setState(() {
        _burnoutPatternSummary = summary;
        _aiInsightNudge = aiInsight;
        _isLoadingBurnoutPatterns = false;
        _isLoadingAiInsight = false;
      });
    } catch (_) {
      if (!mounted || loadToken != _burnoutLoadToken) return;

      setState(() {
        _burnoutPatternSummary = null;
        _aiInsightNudge = null;
        _isLoadingBurnoutPatterns = false;
        _isLoadingAiInsight = false;
      });
    }
  }

  Future<void> _loadFirstWeekLearning() async {
    final loadToken = ++_firstWeekLoadToken;
    final learningState = await FirstWeekLearningService.load();
    if (!mounted || loadToken != _firstWeekLoadToken) return;

    setState(() {
      _firstWeekLearning = learningState;
    });
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      _refreshVersion++;
    });

    await Future.wait([
      ActivityService.instance.refresh(),
      _loadBurnoutPatterns(),
      _loadFirstWeekLearning(),
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
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshDashboard,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                12,
                12,
                12,
                mainPageBottomContentPadding(context),
              ),
              child: Column(
                children: [
                  RevealOnBuild(
                    child: DashboardHeaderCard(
                      learningState: _firstWeekLearning,
                    ),
                  ),
                  const SizedBox(height: 12),
                  RevealOnBuild(
                    delay: const Duration(milliseconds: 70),
                    child: Row(
                      children: [
                        DashboardStatCard(
                          title: "Burnout risk",
                          value: _burnoutRiskValue(),
                          subtitle: _burnoutRiskSubtitle(),
                          subtitleColor: _burnoutTrendColor(),
                          icon: _burnoutTrendIcon(),
                          iconColor: _burnoutTrendColor(),
                          isLoading: _isLoadingBurnoutPatterns,
                        ),
                        const SizedBox(width: 10),
                        _AvgSleepStatCard(
                          key: ValueKey('avg-sleep-$_refreshVersion'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  RevealOnBuild(
                    delay: const Duration(milliseconds: 140),
                    child: BurnoutRiskTrendCard(
                      summary: _burnoutPatternSummary,
                      isLoading: _isLoadingBurnoutPatterns,
                      onRefresh: _loadBurnoutPatterns,
                    ),
                  ),
                  const SizedBox(height: 12),
                  RevealOnBuild(
                    delay: const Duration(milliseconds: 200),
                    child: _AiBurnoutInsightCard(
                      recommendation: _aiInsightNudge,
                      isLoading: _isLoadingAiInsight,
                      learningState: _firstWeekLearning,
                    ),
                  ),
                  const SizedBox(height: 12),
                  RevealOnBuild(
                    delay: const Duration(milliseconds: 260),
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
                  const SizedBox(height: 12),
                  RevealOnBuild(
                    delay: const Duration(milliseconds: 320),
                    child: NutritionAnalyticsCard(
                      key: ValueKey('nutrition-analytics-$_refreshVersion'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  RevealOnBuild(
                    delay: const Duration(milliseconds: 380),
                    child: SleepPatternCard(
                      key: ValueKey('sleep-pattern-$_refreshVersion'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  RevealOnBuild(
                    delay: const Duration(milliseconds: 440),
                    child: WellnessIndexCard(
                      key: ValueKey('wellness-index-$_refreshVersion'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  RevealOnBuild(
                    delay: const Duration(milliseconds: 500),
                    child: MoodVolatilityCard(
                      key: ValueKey('mood-volatility-$_refreshVersion'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  RevealOnBuild(
                    delay: const Duration(milliseconds: 560),
                    child: SymptomFrequencyCard(
                      key: ValueKey('symptom-frequency-$_refreshVersion'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  RevealOnBuild(
                    delay: const Duration(milliseconds: 620),
                    child: DashboardGoalTrackingCard(
                      key: ValueKey('goal-tracking-$_refreshVersion'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  RevealOnBuild(
                    delay: const Duration(milliseconds: 680),
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
          title: "Average sleep",
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
          isLoading: snapshot.connectionState == ConnectionState.waiting,
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
  final FirstWeekLearningState? learningState;

  const _AiBurnoutInsightCard({
    required this.recommendation,
    required this.isLoading,
    required this.learningState,
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
    final firstWeekState = learningState;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: AnalyticsContentSwitcher(
        isLoading: isLoading,
        loading: const SizedBox(
          height: 76,
          child: AppSkeletonRows(count: 2, showLeading: true),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
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
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI insight',
                        style: TextStyle(
                          color: pagePrimaryTextColor(context),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        aiEnhanced
                            ? 'Personalized from your pattern data'
                            : 'Rule-based fallback insight',
                        style: TextStyle(
                          color: pageSecondaryTextColor(context),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (firstWeekState?.isVisible == true) ...[
              const SizedBox(height: 9),
              FirstWeekLearningPill(
                state: firstWeekState!,
                message: firstWeekState.aiInsightNote,
                icon: Icons.auto_awesome_motion_rounded,
                maxLines: 2,
              ),
            ],
            const SizedBox(height: 10),
            Text(
              recommendation?.title ?? 'Keep building your trend baseline',
              style: TextStyle(
                color: pagePrimaryTextColor(context),
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              recommendation?.message ??
                  'Complete a few more check-ins so VitalySync can personalize burnout insights more accurately.',
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: pageSecondaryTextColor(context),
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (why != null && why.isNotEmpty) ...[
              const SizedBox(height: 9),
              Text(
                why,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: pagePrimaryTextColor(context),
                  fontSize: 12.5,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (steps.isNotEmpty) ...[
              const SizedBox(height: 9),
              ...steps.map(
                (step) => Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 15,
                        color: Color(0xFF1FB489),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          step,
                          style: TextStyle(
                            color: pageSecondaryTextColor(context),
                            fontSize: 12,
                            height: 1.3,
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
      ),
    );
  }
}
