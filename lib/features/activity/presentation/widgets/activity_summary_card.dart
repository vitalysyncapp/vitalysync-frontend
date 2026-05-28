import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../shared/preferences/user_session.dart';
import '../../../../shared/theme/app_page_style.dart';
import '../../data/activity_api.dart';
import '../../data/activity_log.dart';
import '../../data/activity_service.dart';

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
          content: Text(
            'Daily step goal updated to ${NumberFormat.decimalPattern().format(updatedGoal)}.',
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update your daily step goal.')),
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
                child: Center(child: CircularProgressIndicator()),
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
                            Text(
                              'Daily Steps',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: compact ? 14.5 : 15.5,
                                fontWeight: FontWeight.w800,
                                color: pagePrimaryTextColor(context),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
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
                                tooltip: 'Retry activity sync',
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
                                tooltip: 'Edit daily step goal',
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
                        child: Text(
                          'Step goal',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: pageSecondaryTextColor(context),
                          ),
                        ),
                      ),
                      Text(
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
                      Text(
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
                    Text(
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

class WeeklyStepAnalyticsCard extends StatefulWidget {
  final ActivityTrackingState state;
  final bool compact;

  const WeeklyStepAnalyticsCard({
    super.key,
    required this.state,
    this.compact = false,
  });

  @override
  State<WeeklyStepAnalyticsCard> createState() =>
      _WeeklyStepAnalyticsCardState();
}

class _WeeklyStepAnalyticsCardState extends State<WeeklyStepAnalyticsCard> {
  static const _historyRangeDays = 7;

  bool _isLoading = true;
  bool _isOffline = false;
  String? _errorMessage;
  List<ActivityLog> _historyLogs = const [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final session = await UserSessionController.instance.load();
    if (session.userId == null || session.userId! <= 0) {
      if (!mounted) {
        return;
      }
      setState(() {
        _historyLogs = const [];
        _isLoading = false;
        _isOffline = false;
        _errorMessage = null;
      });
      return;
    }

    final endDate = DateTime.now();
    final startDate = endDate.subtract(
      const Duration(days: _historyRangeDays - 1),
    );

    try {
      final logs = await ActivityApi.fetchHistory(
        userId: session.userId!,
        startDate: _dateKey(startDate),
        endDate: _dateKey(endDate),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _historyLogs = logs;
        _isLoading = false;
        _isOffline = false;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _isOffline = true;
        _errorMessage = 'Weekly step history is unavailable right now.';
      });
    }
  }

  List<ActivityLog> _weeklyLogs(ActivityLog todayLog) {
    final logsByDate = <String, ActivityLog>{};
    for (final log in _historyLogs) {
      logsByDate[log.logDate] = log;
    }
    logsByDate[todayLog.logDate] = todayLog;

    final now = DateTime.now();
    return List.generate(_historyRangeDays, (index) {
      final day = now.subtract(Duration(days: _historyRangeDays - 1 - index));
      final key = _dateKey(day);
      return logsByDate[key] ??
          ActivityLog.fromSteps(
            logDate: key,
            steps: 0,
            goalSteps: todayLog.goalSteps,
          );
    });
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    final log = widget.state.log;
    final weeklyLogs = _weeklyLogs(log);
    final numberFormat = NumberFormat.decimalPattern();
    final totalSteps = weeklyLogs.fold<int>(0, (sum, item) => sum + item.steps);
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
    final syncLabel = _isOffline ? 'Offline cache' : 'Last 7 days';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(widget.compact ? 14 : 15),
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
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _isLoading
            ? const SizedBox(
                key: ValueKey('weekly-activity-loading'),
                height: 110,
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                key: ValueKey('weekly-activity-${log.logDate}-${log.steps}'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF1EAD83,
                          ).withValues(alpha: 0.13),
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
                            Text(
                              'Weekly Step Analytics',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: widget.compact ? 14.5 : 15.5,
                                fontWeight: FontWeight.w800,
                                color: pagePrimaryTextColor(context),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
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
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ActivityMetric(
                          label: 'Total Steps',
                          value: numberFormat.format(totalSteps),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActivityMetric(
                          label: 'Daily Avg',
                          value: numberFormat.format(averageSteps),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _StatusPill(
                        label:
                            '$bestDayLabel best: ${numberFormat.format(bestDay.steps)}',
                        color: const Color(0xFF0EA5E9),
                      ),
                      const SizedBox(width: 8),
                      _StatusPill(label: statusLabel, color: statusColor),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '$goalDays of ${weeklyLogs.length} goal days reached',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: pagePrimaryTextColor(context),
                        ),
                      ),
                    ],
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _errorMessage!,
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
            title: const Text('Edit Daily Step Goal'),
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
                labelText: 'Goal steps',
                hintText: '5000',
                errorText: errorText,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
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
                child: const Text('Confirm'),
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
        Text(
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
        Text(
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
        child: Text(
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
