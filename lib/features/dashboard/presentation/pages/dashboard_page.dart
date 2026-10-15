import 'package:vitalysync/features/log/presentation/widgets/weekly_assessment_card.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../features/adaptive/data/adaptive_nudge_api.dart';
import '../../../../features/adaptive/data/wellness_content_api.dart';
import '../widgets/personal_insight_card.dart';
import '../../../../features/activity/data/activity_service.dart';
import '../../../../features/activity/presentation/widgets/activity_summary_card.dart';
import '../../data/weekly_user_metrics.dart';
import '../../data/burnout_score_api.dart';
import '../../../../shared/goals/user_goals.dart';
import '../../../../shared/learning/first_week_learning_service.dart';
import '../../../../shared/notifications/notification_feed_service.dart';
import '../../../../shared/preferences/app_preferences.dart';
import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/app_bar.dart';
import '../../../../shared/widgets/reveal_on_build.dart';
import '../../../../shared/widgets/sensitive_content_guard.dart';
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
  bool _isLoadingWeeklyMetrics = true;
  bool _isRefreshingWeeklyMetrics = false;
  WeeklyUserMetrics? _currentWeekMetrics;
  WeeklyUserMetrics? _previousWeekMetrics;
  int _refreshVersion = 0;
  int _burnoutLoadToken = 0;
  int _firstWeekLoadToken = 0;
  int _weeklyMetricsLoadToken = 0;
  Timer? _weeklyMetricsRefreshDebounce;

  @override
  void initState() {
    super.initState();
    WellnessContentApi.changes.addListener(_handleBurnoutInputsChanged);
    UserGoalsService.refreshSignal.addListener(_handleGoalsChanged);
    WeeklyUserMetricsService.refreshSignal.addListener(
      _handleWeeklyMetricsChanged,
    );
    _loadBurnoutPatterns();
    unawaited(_loadWeeklyMetrics());
    unawaited(_loadFirstWeekLearning());
  }

  @override
  void dispose() {
    WellnessContentApi.changes.removeListener(_handleBurnoutInputsChanged);
    UserGoalsService.refreshSignal.removeListener(_handleGoalsChanged);
    WeeklyUserMetricsService.refreshSignal.removeListener(
      _handleWeeklyMetricsChanged,
    );
    _weeklyMetricsRefreshDebounce?.cancel();
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

  void _handleWeeklyMetricsChanged() {
    _weeklyMetricsRefreshDebounce?.cancel();
    _weeklyMetricsRefreshDebounce = Timer(
      const Duration(milliseconds: 100),
      () => unawaited(_loadWeeklyMetrics()),
    );
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
        final insightsPaused = AppPreferencesController
            .instance
            .notifier
            .value
            .pauseWellnessInsights;
        aiInsight = insightsPaused
            ? null
            : await AdaptiveNudgeApi.fetchPersonalInsight();
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

  Future<void> _loadWeeklyMetrics({bool forceRefresh = false}) async {
    final loadToken = ++_weeklyMetricsLoadToken;
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoadingWeeklyMetrics = _currentWeekMetrics == null;
      _isRefreshingWeeklyMetrics = _currentWeekMetrics != null;
    });

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final currentStart = today.subtract(const Duration(days: 6));
    final previousEnd = currentStart.subtract(const Duration(days: 1));
    final previousStart = previousEnd.subtract(const Duration(days: 6));

    try {
      final results = await Future.wait([
        _loadWeeklyRange(
          start: currentStart,
          end: today,
          forceRefresh: forceRefresh,
          fallback: _currentWeekMetrics,
        ),
        _loadWeeklyRange(
          start: previousStart,
          end: previousEnd,
          forceRefresh: forceRefresh,
          fallback: _previousWeekMetrics,
        ),
      ]);

      if (!mounted || loadToken != _weeklyMetricsLoadToken) {
        return;
      }

      setState(() {
        _currentWeekMetrics = results[0];
        _previousWeekMetrics = results[1];
        _isLoadingWeeklyMetrics = false;
        _isRefreshingWeeklyMetrics = false;
      });
    } catch (_) {
      if (!mounted || loadToken != _weeklyMetricsLoadToken) {
        return;
      }

      setState(() {
        _currentWeekMetrics ??= WeeklyUserMetricsService.empty(
          start: currentStart,
        );
        _previousWeekMetrics ??= WeeklyUserMetricsService.empty(
          start: previousStart,
        );
        _isLoadingWeeklyMetrics = false;
        _isRefreshingWeeklyMetrics = false;
      });
    }
  }

  Future<WeeklyUserMetrics> _loadWeeklyRange({
    required DateTime start,
    required DateTime end,
    required bool forceRefresh,
    required WeeklyUserMetrics? fallback,
  }) async {
    try {
      return await WeeklyUserMetricsService.loadRange(
        start: start,
        end: end,
        forceRefresh: forceRefresh,
      );
    } catch (_) {
      return fallback ?? WeeklyUserMetricsService.empty(start: start);
    }
  }

  Future<void> _refreshWeeklyMetrics() async {
    try {
      await ActivityService.instance.refresh();
    } catch (_) {
      // Weekly history can still refresh when today's live activity cannot.
    }
    await _loadWeeklyMetrics(forceRefresh: true);
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      _refreshVersion++;
    });

    await Future.wait([
      _refreshWeeklyMetrics(),
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
    if (summary.latestScore!.confidenceScore < 55) {
      return summary.adaptiveState.label;
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
                  SensitiveContentGuard(
                    child: Column(
                      children: [
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
                                currentWeek: _currentWeekMetrics,
                                previousWeek: _previousWeekMetrics,
                                isLoading: _isLoadingWeeklyMetrics,
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
                          child: PersonalInsightCard(
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
                                currentWeek: _currentWeekMetrics,
                                previousWeek: _previousWeekMetrics,
                                isLoading: _isLoadingWeeklyMetrics,
                                isRefreshing: _isRefreshingWeeklyMetrics,
                                onRefresh: _refreshWeeklyMetrics,
                                compact: true,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        RevealOnBuild(
                          delay: const Duration(milliseconds: 320),
                          child: NutritionAnalyticsCard(
                            refreshVersion: _refreshVersion,
                          ),
                        ),
                        const SizedBox(height: 12),
                        RevealOnBuild(
                          delay: const Duration(milliseconds: 380),
                          child: SleepPatternCard(
                            metrics: _currentWeekMetrics,
                            isLoading: _isLoadingWeeklyMetrics,
                          ),
                        ),
                        const SizedBox(height: 12),
                        RevealOnBuild(
                          delay: const Duration(milliseconds: 440),
                          child: ValueListenableBuilder<ActivityTrackingState>(
                            valueListenable: ActivityService.instance.notifier,
                            builder: (context, activityState, _) {
                              return WellnessIndexCard(
                                metrics: _currentWeekMetrics
                                    ?.withLatestActivity(activityState.log),
                                isLoading: _isLoadingWeeklyMetrics,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        RevealOnBuild(
                          delay: const Duration(milliseconds: 500),
                          child: MoodVolatilityCard(
                            metrics: _currentWeekMetrics,
                            isLoading: _isLoadingWeeklyMetrics,
                          ),
                        ),
                        const SizedBox(height: 12),
                        RevealOnBuild(
                          delay: const Duration(milliseconds: 560),
                          child: SymptomFrequencyCard(
                            metrics: _currentWeekMetrics,
                            isLoading: _isLoadingWeeklyMetrics,
                          ),
                        ),
                        const SizedBox(height: 12),
                        RevealOnBuild(
                          delay: const Duration(milliseconds: 620),
                          child: DashboardGoalTrackingCard(
                            weeklyMetrics: _currentWeekMetrics,
                            isLoadingWeeklyMetrics: _isLoadingWeeklyMetrics,
                            refreshVersion: _refreshVersion,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const WeeklyAssessmentCard(showHistory: true),
                        const SizedBox(height: 12),
                        RevealOnBuild(
                          delay: const Duration(milliseconds: 680),
                          child: WeeklyPerformanceCard(
                            metrics: _currentWeekMetrics,
                            isLoading: _isLoadingWeeklyMetrics,
                          ),
                        ),
                      ],
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

class _AvgSleepStatCard extends StatelessWidget {
  final WeeklyUserMetrics? currentWeek;
  final WeeklyUserMetrics? previousWeek;
  final bool isLoading;

  const _AvgSleepStatCard({
    required this.currentWeek,
    required this.previousWeek,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final currentAverage = currentWeek?.averageSleep ?? 0;
    final previousAverage = previousWeek?.averageSleep ?? 0;
    final delta = currentAverage - previousAverage;

    return DashboardStatCard(
      title: "Average sleep",
      value: currentAverage > 0
          ? "${currentAverage.toStringAsFixed(1)}h"
          : "--",
      subtitle: _subtitle(
        isLoading: isLoading,
        currentAverage: currentAverage,
        previousAverage: previousAverage,
        delta: delta,
      ),
      subtitleColor: _subtitleColor(
        isLoading: isLoading,
        currentAverage: currentAverage,
        delta: delta,
      ),
      icon: _trendIcon(
        isLoading: isLoading,
        currentAverage: currentAverage,
        delta: delta,
      ),
      iconColor: _subtitleColor(
        isLoading: isLoading,
        currentAverage: currentAverage,
        delta: delta,
      ),
      isLoading: isLoading,
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
