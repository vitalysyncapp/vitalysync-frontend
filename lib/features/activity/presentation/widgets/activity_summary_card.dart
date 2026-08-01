import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/analytics_animation.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../dashboard/data/weekly_user_metrics.dart';
import '../../data/activity_log.dart';
import '../../data/activity_service.dart';
import 'package:vitalysync/l10n/localized_text.dart';

class ActivitySummaryCard extends StatelessWidget {
  final ActivityTrackingState state;
  final VoidCallback? onRefresh;
  final Future<void> Function(int goalSteps)? onEditGoal;
  final bool compact;

  const ActivitySummaryCard({
    super.key,
    required this.state,
    this.onRefresh,
    this.onEditGoal,
    this.compact = false,
  });

  Future<void> _handleEditGoal(BuildContext context) async {
    if (onEditGoal == null) {
      return;
    }

    final updatedGoal = await _showStepGoalDialog(
      context,
      initialGoalSteps: state.log.goalSteps,
    );
    if (updatedGoal == null) {
      return;
    }

    try {
      await onEditGoal!(updatedGoal);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: LocalizedText(
            'Daily step goal updated to ${NumberFormat.decimalPattern().format(updatedGoal)}.',
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: LocalizedText('Unable to update your daily step goal.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final log = state.log;
    final progressPercent = (log.progress * 100).round();
    final numberFormat = NumberFormat.decimalPattern();
    final distanceText = log.distanceKm < 10
        ? '${log.distanceKm.toStringAsFixed(2)} km'
        : '${log.distanceKm.toStringAsFixed(1)} km';
    final statusColor = log.goalCompleted
        ? const Color(0xFF16A34A)
        : const Color(0xFF1EAD83);
    final syncLabel = state.pendingSyncCount > 0
        ? 'Sync pending'
        : state.isOffline
        ? 'Offline cache'
        : state.isTracking
        ? 'Live sensor'
        : 'Cached';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 11 : 15),
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(compact ? 15 : 18),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.22
                  : 0.05,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: state.isLoading
            ? SizedBox(
                key: const ValueKey('activity-loading'),
                height: compact ? 84 : 110,
                child: const AppSkeletonRows(count: 2, showLeading: true),
              )
            : Column(
                key: ValueKey('activity-${log.logDate}-${log.steps}'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: compact ? 32 : 38,
                        height: compact ? 32 : 38,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF1EAD83,
                          ).withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(
                            compact ? 11 : 13,
                          ),
                        ),
                        child: Icon(
                          Icons.directions_walk_rounded,
                          color: const Color(0xFF1EAD83),
                          size: compact ? 19 : 24,
                        ),
                      ),
                      SizedBox(width: compact ? 9 : 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LocalizedText(
                              'Daily steps',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: compact ? 14.5 : 15.5,
                                fontWeight: FontWeight.w800,
                                color: pagePrimaryTextColor(context),
                              ),
                            ),
                            const SizedBox(height: 2),
                            LocalizedText(
                              syncLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: pageSecondaryTextColor(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (onRefresh != null || onEditGoal != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (onRefresh != null)
                              IconButton(
                                tooltip: 'Retry activity sync'.localizedCopy(context),
                                onPressed: onRefresh,
                                constraints: BoxConstraints.tightFor(
                                  width: compact ? 36 : 44,
                                  height: compact ? 36 : 44,
                                ),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.refresh_rounded),
                              ),
                            if (onEditGoal != null)
                              IconButton(
                                tooltip: 'Edit daily step goal'.localizedCopy(context),
                                onPressed: () => _handleEditGoal(context),
                                constraints: BoxConstraints.tightFor(
                                  width: compact ? 36 : 44,
                                  height: compact ? 36 : 44,
                                ),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.edit_rounded),
                              ),
                          ],
                        ),
                    ],
                  ),
                  SizedBox(height: compact ? 9 : 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ActivityMetric(
                          label: 'Steps',
                          value: numberFormat.format(log.steps),
                          compact: compact,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActivityMetric(
                          label: 'Distance',
                          value: distanceText,
                          compact: compact,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 9 : 12),
                  Row(
                    children: [
                      Expanded(
                        child: LocalizedText(
                          'Step goal',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: pageSecondaryTextColor(context),
                          ),
                        ),
                      ),
                      LocalizedText(
                        '${numberFormat.format(log.goalSteps)} steps',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: pagePrimaryTextColor(context),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 5 : 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: compact ? 6 : 8,
                      value: log.progress,
                      backgroundColor: pageBorderColor(context),
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),
                  SizedBox(height: compact ? 6 : 8),
                  Row(
                    children: [
                      _StatusPill(label: log.statusLabel, color: statusColor),
                      const Spacer(),
                      LocalizedText(
                        '$progressPercent%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: pagePrimaryTextColor(context),
                        ),
                      ),
                    ],
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 10),
                    LocalizedText(
                      state.errorMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFDC2626),
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class WeeklyStepAnalyticsCard extends StatelessWidget {
  final ActivityTrackingState state;
  final WeeklyUserMetrics? currentWeek;
  final WeeklyUserMetrics? previousWeek;
  final bool isLoading;
  final bool isRefreshing;
  final Future<void> Function()? onRefresh;
  final bool compact;

  const WeeklyStepAnalyticsCard({
    super.key,
    required this.state,
    required this.currentWeek,
    required this.previousWeek,
    required this.isLoading,
    this.isRefreshing = false,
    this.onRefresh,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final log = state.log;
    final resolvedCurrentWeek = currentWeek?.withLatestActivity(log);
    final weeklyLogs = _weeklyLogs(resolvedCurrentWeek, log.goalSteps);
    final numberFormat = NumberFormat.decimalPattern();
    final totalSteps = weeklyLogs.fold<int>(0, (sum, item) => sum + item.steps);
    final previousTotalSteps = previousWeek?.totalSteps ?? 0;
    final comparison = _StepWeekComparison.fromTotals(
      current: totalSteps,
      previous: previousTotalSteps,
    );
    final averageSteps = weeklyLogs.isEmpty
        ? 0
        : (totalSteps / weeklyLogs.length).round();
    final goalDays = weeklyLogs
        .where(
          (item) =>
              item.goalCompleted ||
              (item.goalSteps > 0 && item.steps >= item.goalSteps),
        )
        .length;
    final bestDay = weeklyLogs.reduce(
      (current, next) => current.steps >= next.steps ? current : next,
    );
    final bestDayLabel = DateFormat(
      'EEE',
    ).format(DateTime.parse(bestDay.logDate));
    final statusColor = goalDays >= 5
        ? const Color(0xFF16A34A)
        : goalDays >= 3
        ? const Color(0xFF1EAD83)
        : const Color(0xFFF59E0B);
    final statusLabel = goalDays >= 5
        ? 'Strong week'
        : goalDays >= 3
        ? 'Building momentum'
        : totalSteps > 0
        ? 'Keep moving'
        : 'Start your streak';
    final syncLabel = state.isOffline
        ? 'Saved data • Last 7 days'
        : 'Last 7 days';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 15),
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.22
                  : 0.05,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AnalyticsContentSwitcher(
        isLoading: isLoading && currentWeek == null,
        contentKey:
            '${log.logDate}-$totalSteps-$previousTotalSteps-$isRefreshing',
        loading: const SizedBox(
          height: 110,
          child: AppSkeletonRows(count: 2, showLeading: true),
        ),
        child: Column(
          key: ValueKey('weekly-activity-${log.logDate}-${log.steps}'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1EAD83).withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.insights_rounded,
                    color: Color(0xFF1EAD83),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LocalizedText(
                        'Weekly step analytics',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: compact ? 14.5 : 15.5,
                          fontWeight: FontWeight.w800,
                          color: pagePrimaryTextColor(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      LocalizedText(
                        syncLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: pageSecondaryTextColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isRefreshing)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (onRefresh != null)
                  IconButton(
                    key: const ValueKey('weekly-steps-refresh'),
                    tooltip: 'Refresh weekly steps'.localizedCopy(context),
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActivityMetric(
                    label: 'Total steps',
                    value: numberFormat.format(totalSteps),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActivityMetric(
                    label: 'Daily average',
                    value: numberFormat.format(averageSteps),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatusPill(label: comparison.label, color: comparison.color),
                const SizedBox(width: 8),
                _StatusPill(
                  label:
                      '$bestDayLabel best: ${numberFormat.format(bestDay.steps)}',
                  color: const Color(0xFF0EA5E9),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _StatusPill(label: statusLabel, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: LocalizedText(
                    '$goalDays of ${weeklyLogs.length} goal days reached',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: pagePrimaryTextColor(context),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<ActivityLog> _weeklyLogs(
    WeeklyUserMetrics? metrics,
    int fallbackGoalSteps,
  ) {
    final days = metrics?.days ?? const <DailyUserMetric>[];
    if (days.isNotEmpty) {
      return days
          .map(
            (day) =>
                day.activity ??
                ActivityLog.fromSteps(
                  logDate: day.dateKey,
                  steps: 0,
                  goalSteps: fallbackGoalSteps,
                ),
          )
          .toList();
    }

    final today = DateTime.now();
    return List.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      return ActivityLog.fromSteps(
        logDate: _dateKey(date),
        steps: 0,
        goalSteps: fallbackGoalSteps,
      );
    });
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _StepWeekComparison {
  final String label;
  final Color color;

  const _StepWeekComparison({required this.label, required this.color});

  factory _StepWeekComparison.fromTotals({
    required int current,
    required int previous,
  }) {
    if (previous <= 0) {
      return _StepWeekComparison(
        label: current > 0 ? 'New vs last week' : 'No comparison yet',
        color: const Color(0xFF64748B),
      );
    }

    final percent = ((current - previous) / previous * 100).round();
    if (percent == 0) {
      return const _StepWeekComparison(
        label: 'Same as last week',
        color: Color(0xFF64748B),
      );
    }

    return _StepWeekComparison(
      label: '${percent > 0 ? '+' : ''}$percent% vs last week',
      color: percent > 0 ? const Color(0xFF16A34A) : const Color(0xFF0EA5E9),
    );
  }
}

Future<int?> _showStepGoalDialog(
  BuildContext context, {
  required int initialGoalSteps,
}) async {
  var goalInput = initialGoalSteps.toString();
  String? errorText;

  return showDialog<int>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const LocalizedText('Edit daily step goal'),
            content: TextFormField(
              initialValue: goalInput,
              autofocus: true,
              keyboardType: TextInputType.number,
              onChanged: (value) {
                goalInput = value;
                if (errorText != null) {
                  setDialogState(() {
                    errorText = null;
                  });
                }
              },
              decoration: InputDecoration(
                labelText: 'Goal steps'.localizedCopy(context),
                hintText: '5000'.localizedCopy(context),
                errorText: errorText,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const LocalizedText('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final parsedGoal = int.tryParse(goalInput.trim());
                  if (parsedGoal == null || parsedGoal < 1000) {
                    setDialogState(() {
                      errorText = 'Enter at least 1000 steps.';
                    });
                    return;
                  }

                  if (parsedGoal > 50000) {
                    setDialogState(() {
                      errorText = 'Enter a goal below 50000 steps.';
                    });
                    return;
                  }

                  Navigator.of(dialogContext).pop(parsedGoal);
                },
                child: const LocalizedText('Confirm'),
              ),
            ],
          );
        },
      );
    },
  );
}

class _ActivityMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool compact;

  const _ActivityMetric({
    required this.label,
    required this.value,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LocalizedText(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: compact ? 18 : 22,
            fontWeight: FontWeight.w800,
            color: pagePrimaryTextColor(context),
          ),
        ),
        SizedBox(height: compact ? 2 : 3),
        LocalizedText(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: compact ? 10.5 : 11.5,
            fontWeight: FontWeight.w600,
            color: pageSecondaryTextColor(context),
          ),
        ),
      ],
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.24)),
        ),
        child: LocalizedText(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ),
    );
  }
}
