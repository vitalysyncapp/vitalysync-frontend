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
import '../../../../shared/preferences/app_preferences.dart';
import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/app_bar.dart';
import '../../../../shared/widgets/analytics_animation.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../../shared/widgets/first_week_learning_pill.dart';
import '../../../../shared/widgets/reveal_on_build.dart';
import '../../../../shared/widgets/sensitive_content_guard.dart';
import '../../../assessment/presentation/widgets/assessment_overview_card.dart';
import '../widgets/dashboard_goal_tracking_card.dart';
import '../widgets/dashboard_header_card.dart';
import '../widgets/dashboard_stat_card.dart';
import '../widgets/mood_volatility_card.dart';
import '../widgets/nutrition_analytics_card.dart';
import '../widgets/sleep_pattern_card.dart';
import '../widgets/symptom_frequency_card.dart';
import '../widgets/weekly_performance_card.dart';
import 'package:vitalysync/l10n/localized_text.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  AdaptiveNudgeRecommendation? _aiInsightNudge;
  FirstWeekLearningState _firstWeekLearning =
      const FirstWeekLearningState.hidden();
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
    BurnoutScoreApi.refreshSignal.addListener(_handleBurnoutInputsChanged);
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
    BurnoutScoreApi.refreshSignal.removeListener(_handleBurnoutInputsChanged);
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
      _isLoadingAiInsight = true;
    });

    try {
      AdaptiveNudgeRecommendation? aiInsight;
      try {
        final nudgeResponse = await AdaptiveNudgeApi.fetchRecommendations(
          limit: 1,
          record: false,
          ai: true,
        );
        final insightsPaused = AppPreferencesController
            .instance
            .notifier
            .value
            .pauseWellnessInsights;
        aiInsight = nudgeResponse.recommendations.isEmpty || insightsPaused
            ? null
            : nudgeResponse.recommendations.first;
      } catch (_) {
        aiInsight = null;
      }
      if (!mounted || loadToken != _burnoutLoadToken) return;

      setState(() {
        _aiInsightNudge = aiInsight;
        _isLoadingAiInsight = false;
      });
    } catch (_) {
      if (!mounted || loadToken != _burnoutLoadToken) return;

      setState(() {
        _aiInsightNudge = null;
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
                          child: AssessmentOverviewCard(
                            refreshVersion: _refreshVersion,
                            showObservations: true,
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
    final enough =
        (currentWeek?.sleepRecordedDays ?? 0) >= 3 &&
        (previousWeek?.sleepRecordedDays ?? 0) >= 3;
    final delta = enough ? currentAverage - previousAverage : 0.0;

    return DashboardStatCard(
      title: "Average sleep",
      value: (currentWeek?.sleepRecordedDays ?? 0) > 0
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
    if ((currentWeek?.sleepRecordedDays ?? 0) == 0) {
      return 'No sleep logs yet';
    }
    if ((currentWeek?.sleepRecordedDays ?? 0) < 3 ||
        (previousWeek?.sleepRecordedDays ?? 0) < 3) {
      return '${currentWeek?.sleepRecordedDays ?? 0} recorded days; comparison needs 3 per week';
    }

    final prefix = delta > 0 ? '+' : '';
    return '$prefix${delta.toStringAsFixed(1)}h; ${currentWeek?.sleepRecordedDays}/${previousWeek?.sleepRecordedDays} recorded days';
  }

  Color _subtitleColor({
    required bool isLoading,
    required double currentAverage,
    required double delta,
  }) {
    if (isLoading || currentAverage <= 0) {
      return const Color(0xFF64748B);
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
    final why = recommendation?.triggerReason;
    final steps = recommendation?.metadata['ai_action_steps'] is List
        ? (recommendation!.metadata['ai_action_steps'] as List)
              .map((item) => item.toString())
              .where((item) => item.trim().isNotEmpty)
              .take(1)
              .toList()
        : const <String>[];
    final aiEnhanced = recommendation?.metadata['ai_enhanced'] == true;
    final firstWeekState = learningState;
    final severity = recommendation?.userFacingSeverity;

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
        overlapOutgoing: false,
        loading: const AppSkeletonRows(count: 2, showLeading: true),
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
                      LocalizedText(
                        'Personal insight',
                        style: TextStyle(
                          color: pagePrimaryTextColor(context),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 1),
                      LocalizedText(
                        aiEnhanced
                            ? 'Based on your daily and weekly patterns'
                            : 'Evidence-informed wellness suggestion',
                        style: TextStyle(
                          color: pageSecondaryTextColor(context),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (severity != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _severityColor(
                        severity,
                        isDark,
                      ).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: LocalizedText(
                      _severityLabel(severity),
                      style: TextStyle(
                        color: _severityColor(severity, isDark),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
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
            LocalizedText(
              recommendation?.title ?? 'Wellness observations',
              style: TextStyle(
                color: pagePrimaryTextColor(context),
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            LocalizedText(
              recommendation?.message ??
                  'No personalized suggestion is available. You can choose a wellness goal or record your day.',
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
              LocalizedText(
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
                        child: LocalizedText(
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

  Color _severityColor(String severity, bool isDark) {
    switch (severity) {
      case 'needs support':
        return isDark ? const Color(0xFFFF8A80) : const Color(0xFFD83B3B);
      case 'high':
        return isDark ? const Color(0xFFFFB454) : const Color(0xFFF57C00);
      case 'watch':
        return isDark ? const Color(0xFFFFD54F) : const Color(0xFFB77900);
      default:
        return isDark ? const Color(0xFF81D4FA) : const Color(0xFF0277BD);
    }
  }

  String _severityLabel(String severity) {
    return severity
        .split(' ')
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }
}
