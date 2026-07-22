import 'package:flutter/material.dart';

import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/analytics_animation.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../data/goal_tracking_metrics.dart';
import '../../data/weekly_user_metrics.dart';

class DashboardGoalTrackingCard extends StatefulWidget {
  final WeeklyUserMetrics? weeklyMetrics;
  final bool isLoadingWeeklyMetrics;
  final int refreshVersion;

  const DashboardGoalTrackingCard({
    super.key,
    required this.weeklyMetrics,
    required this.isLoadingWeeklyMetrics,
    required this.refreshVersion,
  });

  @override
  State<DashboardGoalTrackingCard> createState() =>
      _DashboardGoalTrackingCardState();
}

class _DashboardGoalTrackingCardState extends State<DashboardGoalTrackingCard> {
  Future<DashboardGoalTrackingSnapshot>? _future;

  @override
  void initState() {
    super.initState();
    _future = _loadIfReady();
  }

  @override
  void didUpdateWidget(covariant DashboardGoalTrackingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weeklyMetrics != widget.weeklyMetrics ||
        oldWidget.isLoadingWeeklyMetrics != widget.isLoadingWeeklyMetrics ||
        oldWidget.refreshVersion != widget.refreshVersion) {
      _future = _loadIfReady();
    }
  }

  @override
  Widget build(BuildContext context) {
    final future = _future;
    if (widget.isLoadingWeeklyMetrics || future == null) {
      return _GoalTrackingSurface(
        child: const SizedBox(
          height: 190,
          child: AppSkeletonRows(count: 4, showLeading: true),
        ),
      );
    }

    return FutureBuilder<DashboardGoalTrackingSnapshot>(
      future: future,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final data = snapshot.data;

        return _GoalTrackingSurface(
          child: AnalyticsContentSwitcher(
            isLoading: isLoading,
            loading: const SizedBox(
              height: 190,
              child: AppSkeletonRows(count: 4, showLeading: true),
            ),
            child: isLoading
                ? const SizedBox.shrink()
                : data == null
                ? _GoalTrackingUnavailable(onRetry: _reload)
                : _GoalTrackingContent(data: data),
          ),
        );
      },
    );
  }

  void _reload() {
    setState(() {
      _future = _loadIfReady(forceRefresh: true);
    });
  }

  Future<DashboardGoalTrackingSnapshot>? _loadIfReady({
    bool forceRefresh = false,
  }) {
    final weeklyMetrics = widget.weeklyMetrics;
    if (widget.isLoadingWeeklyMetrics || weeklyMetrics == null) {
      return null;
    }

    return GoalTrackingMetricsService.loadCurrentWeek(
      weeklyMetrics: weeklyMetrics,
      forceRefresh: forceRefresh,
    );
  }
}

class _GoalTrackingSurface extends StatelessWidget {
  final Widget child;

  const _GoalTrackingSurface({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: pageCardShadow(context),
      ),
      child: child,
    );
  }
}

class _GoalTrackingContent extends StatelessWidget {
  final DashboardGoalTrackingSnapshot data;

  const _GoalTrackingContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final goals = data.wellnessGoalHeaders;
    final hasGoals = goals.isNotEmpty;

    return Column(
      key: const ValueKey('goal-tracking-content'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF1FB489), Color(0xFF4A86F7)],
                ),
              ),
              child: const Icon(
                Icons.track_changes_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Goal tracking',
                    style: TextStyle(
                      color: pagePrimaryTextColor(context),
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.isNutritionUnavailable
                        ? 'Using available weekly data'
                        : 'This week against your saved goals',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
        const SizedBox(height: 13),
        Text(
          'Wellness goals',
          style: TextStyle(
            color: pagePrimaryTextColor(context),
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: hasGoals
              ? goals.map((goal) => _WellnessGoalChip(label: goal)).toList()
              : const [
                  _WellnessGoalChip(
                    label: 'Wellness goals not set',
                    isNeutral: true,
                  ),
                ],
        ),
        const SizedBox(height: 14),
        Divider(color: pageBorderColor(context), height: 1),
        const SizedBox(height: 4),
        ...List.generate(data.metrics.length, (index) {
          final metric = data.metrics[index];
          return Column(
            children: [
              _GoalMetricRow(metric: metric),
              if (index != data.metrics.length - 1)
                Divider(color: pageBorderColor(context), height: 1),
            ],
          );
        }),
        const SizedBox(height: 13),
        _FocusRecommendationSection(recommendations: data.recommendations),
      ],
    );
  }
}

class _GoalMetricRow extends StatelessWidget {
  final GoalTrackingMetric metric;

  const _GoalMetricRow({required this.metric});

  @override
  Widget build(BuildContext context) {
    final accentColor = _metricColor(metric.id);
    final statusColor = _statusColor(metric);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_metricIcon(metric.id), color: accentColor, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        metric.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: pagePrimaryTextColor(context),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusPill(label: metric.statusLabel, color: statusColor),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  '${metric.valueLabel} - ${metric.targetLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: pagePrimaryTextColor(context),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: AnimatedAnalyticsProgress(
                    value: metric.progress,
                    minHeight: 6,
                    backgroundColor: pageBorderColor(
                      context,
                    ).withValues(alpha: 0.58),
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  metric.detailLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: pageSecondaryTextColor(context),
                    fontSize: 11.5,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (metric.balanceLabel != null) ...[
                  const SizedBox(height: 7),
                  _BalanceKcalPill(label: metric.balanceLabel!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceKcalPill extends StatelessWidget {
  final String label;

  const _BalanceKcalPill({required this.label});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF1EAD83);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        key: const ValueKey('dashboard-balanced-kcal-indicator'),
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.24)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.balance_rounded, color: color, size: 14),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: color,
                  fontSize: 10.8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusRecommendationSection extends StatelessWidget {
  final List<GoalFocusRecommendation> recommendations;

  const _FocusRecommendationSection({required this.recommendations});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.tips_and_updates_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 18,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                'Focus recommendations',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: pagePrimaryTextColor(context),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        ...recommendations.map(
          (recommendation) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 23,
                  height: 23,
                  decoration: BoxDecoration(
                    color: _metricColor(
                      recommendation.metricId,
                    ).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _metricIcon(recommendation.metricId),
                    color: _metricColor(recommendation.metricId),
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recommendation.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: pagePrimaryTextColor(context),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        recommendation.message,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: pageSecondaryTextColor(context),
                          fontSize: 11.5,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WellnessGoalChip extends StatelessWidget {
  final String label;
  final bool isNeutral;

  const _WellnessGoalChip({required this.label, this.isNeutral = false});

  @override
  Widget build(BuildContext context) {
    final color = isNeutral
        ? const Color(0xFF64748B)
        : _wellnessGoalColor(label);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isNeutral ? Icons.flag_outlined : _wellnessGoalIcon(label),
            color: color,
            size: 14,
          ),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 190),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _GoalTrackingUnavailable extends StatelessWidget {
  final VoidCallback onRetry;

  const _GoalTrackingUnavailable({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('goal-tracking-unavailable'),
      height: 140,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            color: pageSecondaryTextColor(context),
            size: 30,
          ),
          const SizedBox(height: 9),
          Text(
            'Goal tracking is unavailable right now.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: pagePrimaryTextColor(context),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

IconData _metricIcon(String id) {
  return switch (id) {
    'sleep' => Icons.bedtime_rounded,
    'hydration' => Icons.water_drop_rounded,
    'activity' => Icons.fitness_center_rounded,
    'steps' => Icons.directions_walk_rounded,
    'nutrition' => Icons.restaurant_menu_rounded,
    _ => Icons.track_changes_rounded,
  };
}

Color _metricColor(String id) {
  return switch (id) {
    'sleep' => const Color(0xFF4A86F7),
    'hydration' => const Color(0xFF0EA5E9),
    'activity' => const Color(0xFF1FB489),
    'steps' => const Color(0xFFF59E0B),
    'nutrition' => const Color(0xFFEF7A30),
    _ => const Color(0xFF64748B),
  };
}

Color _statusColor(GoalTrackingMetric metric) {
  return switch (metric.status) {
    GoalTrackingMetricStatus.onTrack => const Color(0xFF16A34A),
    GoalTrackingMetricStatus.needsLogs => const Color(0xFF64748B),
    GoalTrackingMetricStatus.belowTarget => const Color(0xFFF59E0B),
    GoalTrackingMetricStatus.aboveTarget => const Color(0xFFEF7A30),
  };
}

IconData _wellnessGoalIcon(String goal) {
  return switch (goal) {
    'Reduce stress' => Icons.spa_outlined,
    'Improve sleep' => Icons.bedtime_outlined,
    'Be more active' => Icons.directions_bike_rounded,
    'Improve focus' => Icons.center_focus_strong_rounded,
    'Build healthier habits' => Icons.eco_outlined,
    'Manage burnout' => Icons.local_fire_department_outlined,
    _ => Icons.flag_outlined,
  };
}

Color _wellnessGoalColor(String goal) {
  return switch (goal) {
    'Reduce stress' => const Color(0xFF1FB489),
    'Improve sleep' => const Color(0xFF4A86F7),
    'Be more active' => const Color(0xFFF59E0B),
    'Improve focus' => const Color(0xFF7C3AED),
    'Build healthier habits' => const Color(0xFF16A34A),
    'Manage burnout' => const Color(0xFFEF4444),
    _ => const Color(0xFF64748B),
  };
}
