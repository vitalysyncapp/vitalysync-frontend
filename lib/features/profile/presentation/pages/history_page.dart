import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../features/activity/data/activity_api.dart';
import '../../../../features/activity/data/activity_log.dart';
import '../../../../features/dashboard/data/burnout_score_api.dart';
import '../../../../features/log/data/log_api.dart';
import '../../../../features/nutrition/data/nutrition_api.dart';
import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/app_skeleton.dart';

enum _HistoryCategory { dailyLogs, burnout, nutrition, activity }

enum _HistoryRange { week, month }

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  _HistoryCategory _selectedCategory = _HistoryCategory.dailyLogs;
  _HistoryRange _selectedRange = _HistoryRange.week;
  DateTime? _selectedDate;
  late Future<_HistorySnapshot> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadSnapshot();
  }

  Future<_HistorySnapshot> _loadSnapshot() async {
    final window = _rangeWindow(_selectedRange);
    final startKey = _dateKey(window.start);
    final endKey = _dateKey(window.end);
    final limit = window.dayCount;
    final errors = <_HistoryCategory, String>{};
    var dailyLogs = <Map<String, dynamic>>[];
    var burnoutScores = <BurnoutScoreSnapshot>[];
    var nutritionDays = <NutritionHistoryDay>[];
    var activityLogs = <ActivityLog>[];

    await Future.wait<void>([
      () async {
        try {
          dailyLogs = await LogApi.fetchHistory(
            startDate: startKey,
            endDate: endKey,
            limit: limit,
          );
        } catch (error) {
          errors[_HistoryCategory.dailyLogs] = _cleanError(error);
        }
      }(),
      () async {
        try {
          burnoutScores = await BurnoutScoreApi.fetchHistory(
            startDate: startKey,
            endDate: endKey,
            limit: limit,
          );
        } catch (error) {
          errors[_HistoryCategory.burnout] = _cleanError(error);
        }
      }(),
      () async {
        try {
          nutritionDays = await NutritionApi.fetchHistory(
            start: startKey,
            end: endKey,
          );
        } catch (error) {
          errors[_HistoryCategory.nutrition] = _cleanError(error);
        }
      }(),
      () async {
        try {
          final userId = await LogApi.getStoredUserId();
          if (userId == null) {
            activityLogs = const [];
            return;
          }

          activityLogs = await ActivityApi.fetchHistory(
            userId: userId,
            startDate: startKey,
            endDate: endKey,
          );
        } catch (error) {
          errors[_HistoryCategory.activity] = _cleanError(error);
        }
      }(),
    ]);

    dailyLogs.sort(
      (a, b) => _compareDateKeys(
        LogApi.normalizeDateString(b['log_date']),
        LogApi.normalizeDateString(a['log_date']),
      ),
    );
    burnoutScores.sort((a, b) => _compareDateKeys(b.scoreDate, a.scoreDate));
    nutritionDays.sort((a, b) => _compareDateKeys(b.logDate, a.logDate));
    activityLogs.sort((a, b) => _compareDateKeys(b.logDate, a.logDate));

    return _HistorySnapshot(
      start: window.start,
      end: window.end,
      dailyLogs: dailyLogs,
      burnoutScores: burnoutScores,
      nutritionDays: nutritionDays,
      activityLogs: activityLogs,
      errors: errors,
    );
  }

  Future<void> _refresh() async {
    final nextFuture = _loadSnapshot();
    setState(() => _future = nextFuture);
    await nextFuture;
  }

  void _setRange(_HistoryRange range) {
    if (_selectedRange == range) return;
    setState(() {
      _selectedRange = range;
      _selectedDate = null;
      _future = _loadSnapshot();
    });
  }

  Future<void> _openDateFilter(_HistorySnapshot snapshot) async {
    final initialDate = _dateInWindow(_selectedDate, snapshot)
        ? _selectedDate!
        : snapshot.end;
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: snapshot.start,
      lastDate: snapshot.end,
      helpText: 'Filter history by date',
      confirmText: 'Show',
    );

    if (selected == null || !mounted) return;

    setState(() {
      _selectedDate = DateTime(selected.year, selected.month, selected.day);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: buildPageDecoration(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          centerTitle: false,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: pagePrimaryTextColor(context),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'History',
            style: TextStyle(
              color: pagePrimaryTextColor(context),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SafeArea(
          child: FutureBuilder<_HistorySnapshot>(
            future: _future,
            builder: (context, snapshot) {
              final isLoading =
                  snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData;
              final data =
                  snapshot.data ?? _HistorySnapshot.empty(_selectedRange);

              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    pageBottomContentPadding(context),
                  ),
                  children: [
                    _HistoryHeroCard(
                      rangeLabel: _rangeLabel(data.start, data.end),
                      totalCount: data.totalCount,
                    ),
                    const SizedBox(height: 14),
                    _buildCategoryFilters(context, data),
                    const SizedBox(height: 10),
                    _buildFilters(context, data),
                    const SizedBox(height: 14),
                    if (isLoading)
                      const _HistoryLoadingCard()
                    else
                      _buildContent(context, data),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters(
    BuildContext context,
    _HistorySnapshot snapshot,
  ) {
    final dateKey = _selectedDate == null ? null : _dateKey(_selectedDate!);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _HistoryCategory.values.map((category) {
          final selected = _selectedCategory == category;
          final count = dateKey == null
              ? snapshot.countFor(category)
              : snapshot.countForDate(category, dateKey);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: selected,
              label: Text('${_categoryLabel(category)} $count'),
              avatar: Icon(
                _categoryIcon(category),
                size: 17,
                color: selected ? Colors.white : _categoryColor(category),
              ),
              onSelected: (_) => setState(() => _selectedCategory = category),
              selectedColor: _categoryColor(category),
              backgroundColor: pageSurfaceColor(context),
              side: BorderSide(
                color: selected
                    ? _categoryColor(category)
                    : pageBorderColor(context),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              labelStyle: TextStyle(
                color: selected ? Colors.white : pagePrimaryTextColor(context),
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilters(BuildContext context, _HistorySnapshot snapshot) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _FilterButton(
          label: 'Week',
          icon: Icons.view_week_outlined,
          selected: _selectedRange == _HistoryRange.week,
          onTap: () => _setRange(_HistoryRange.week),
        ),
        _FilterButton(
          label: 'Month',
          icon: Icons.calendar_month_outlined,
          selected: _selectedRange == _HistoryRange.month,
          onTap: () => _setRange(_HistoryRange.month),
        ),
        _FilterButton(
          label: _selectedDate == null
              ? 'Date'
              : DateFormat('MMM d').format(_selectedDate!),
          icon: Icons.event_outlined,
          selected: _selectedDate != null,
          onTap: () => _openDateFilter(snapshot),
        ),
        if (_selectedDate != null)
          _FilterButton(
            label: 'Clear Date',
            icon: Icons.close_rounded,
            selected: false,
            onTap: () => setState(() => _selectedDate = null),
          ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, _HistorySnapshot snapshot) {
    final dateKey = _selectedDate == null ? null : _dateKey(_selectedDate!);
    final error = snapshot.errors[_selectedCategory];
    final count = dateKey == null
        ? snapshot.countFor(_selectedCategory)
        : snapshot.countForDate(_selectedCategory, dateKey);

    if (error != null && count == 0) {
      return _HistoryStateCard(
        icon: Icons.cloud_off_outlined,
        title: '${_categoryLabel(_selectedCategory)} unavailable',
        message: error,
      );
    }

    if (count == 0) {
      return _HistoryStateCard(
        icon: Icons.event_busy_outlined,
        title: dateKey == null
            ? 'No ${_categoryLabel(_selectedCategory).toLowerCase()} yet'
            : 'No history for ${_displayDate(dateKey)}',
        message: dateKey == null
            ? 'Saved entries for this range will appear here.'
            : 'Try another date or clear the date filter.',
      );
    }

    return _HistoryListView(
      snapshot: snapshot,
      category: _selectedCategory,
      dateKey: dateKey,
    );
  }
}

class _HistoryListView extends StatelessWidget {
  final _HistorySnapshot snapshot;
  final _HistoryCategory category;
  final String? dateKey;

  const _HistoryListView({
    required this.snapshot,
    required this.category,
    this.dateKey,
  });

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[];

    switch (category) {
      case _HistoryCategory.dailyLogs:
        for (final log in snapshot.dailyLogs) {
          if (!_matchesDate(LogApi.normalizeDateString(log['log_date']))) {
            continue;
          }
          cards.add(_DailyLogHistoryCard(log: log));
        }
        break;
      case _HistoryCategory.burnout:
        for (final score in snapshot.burnoutScores) {
          if (!_matchesDate(score.scoreDate)) continue;
          cards.add(_BurnoutHistoryCard(score: score));
        }
        break;
      case _HistoryCategory.nutrition:
        for (final day in snapshot.nutritionDays) {
          if (!_matchesDate(day.logDate)) continue;
          cards.add(_NutritionHistoryCard(day: day));
        }
        break;
      case _HistoryCategory.activity:
        for (final log in snapshot.activityLogs) {
          if (!_matchesDate(log.logDate)) continue;
          cards.add(_ActivityHistoryCard(log: log));
        }
        break;
    }

    return Column(
      children: List.generate(cards.length, (index) {
        return Padding(
          padding: EdgeInsets.only(bottom: index == cards.length - 1 ? 0 : 10),
          child: cards[index],
        );
      }),
    );
  }

  bool _matchesDate(String? value) {
    return dateKey == null || _normalizeDateKey(value) == dateKey;
  }
}

class _HistoryHeroCard extends StatelessWidget {
  final String rangeLabel;
  final int totalCount;

  const _HistoryHeroCard({required this.rangeLabel, required this.totalCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2F6BFF), Color(0xFF1FB489)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F6BFF).withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: Colors.white,
              size: 29,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Wellness History',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$rangeLabel - $totalCount saved entries',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyLogHistoryCard extends StatelessWidget {
  final Map<String, dynamic> log;

  const _DailyLogHistoryCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final dateKey = LogApi.normalizeDateString(log['log_date']);
    final sleep = LogApi.formatSleepHours(log['sleep_hours']);
    final hydration = LogApi.formatHydrationLiters(log['hydration_liters']);
    final mood = LogApi.parseInt(log['mood_index'], fallback: 0);
    final energy = LogApi.parseEnergyLevel(log['energy_level']);
    final stress = LogApi.parseLikert(log['perceived_stress_level']);

    return _HistoryEntryCard(
      icon: Icons.check_circle_outline_rounded,
      iconColor: _categoryColor(_HistoryCategory.dailyLogs),
      title: _displayDate(dateKey),
      subtitle: 'Daily log history',
      children: [
        _HistoryMetric(label: 'Sleep', value: sleep),
        _HistoryMetric(label: 'Mood', value: mood > 0 ? '$mood/5' : '--'),
        _HistoryMetric(
          label: 'Energy',
          value: energy == null ? '--' : '$energy/5',
        ),
        _HistoryMetric(
          label: 'Stress',
          value: stress == null ? '--' : '$stress/5',
        ),
        _HistoryMetric(label: 'Hydration', value: hydration),
      ],
    );
  }
}

class _BurnoutHistoryCard extends StatelessWidget {
  final BurnoutScoreSnapshot score;

  const _BurnoutHistoryCard({required this.score});

  @override
  Widget build(BuildContext context) {
    return _HistoryEntryCard(
      icon: Icons.monitor_heart_outlined,
      iconColor: _categoryColor(_HistoryCategory.burnout),
      title: _displayDate(score.scoreDate),
      subtitle: '${_titleCase(score.riskLevel)} risk',
      children: [
        _HistoryMetric(label: 'Score', value: '${score.overallScore.round()}%'),
        _HistoryMetric(
          label: 'Confidence',
          value: '${score.confidenceScore.round()}%',
        ),
        _HistoryMetric(
          label: 'Completeness',
          value: '${score.completenessScore.round()}%',
        ),
      ],
    );
  }
}

class _NutritionHistoryCard extends StatelessWidget {
  final NutritionHistoryDay day;

  const _NutritionHistoryCard({required this.day});

  @override
  Widget build(BuildContext context) {
    return _HistoryEntryCard(
      icon: Icons.restaurant_menu_rounded,
      iconColor: _categoryColor(_HistoryCategory.nutrition),
      title: _displayDate(day.logDate),
      subtitle: '${day.mealCount} meals logged',
      children: [
        _HistoryMetric(
          label: 'Calories',
          value: _formatCalories(day.totalCalories),
        ),
        _HistoryMetric(
          label: 'Protein',
          value: '${_formatAmount(day.totalProteinG)}g',
        ),
        _HistoryMetric(
          label: 'Carbs',
          value: '${_formatAmount(day.totalCarbsG)}g',
        ),
        _HistoryMetric(label: 'Fat', value: '${_formatAmount(day.totalFatG)}g'),
      ],
    );
  }
}

class _ActivityHistoryCard extends StatelessWidget {
  final ActivityLog log;

  const _ActivityHistoryCard({required this.log});

  @override
  Widget build(BuildContext context) {
    return _HistoryEntryCard(
      icon: Icons.directions_walk_rounded,
      iconColor: _categoryColor(_HistoryCategory.activity),
      title: _displayDate(log.logDate),
      subtitle: log.statusLabel,
      children: [
        _HistoryMetric(label: 'Steps', value: _formatNumber(log.steps)),
        _HistoryMetric(label: 'Active', value: '${log.activeMinutes} min'),
        _HistoryMetric(
          label: 'Distance',
          value: '${log.distanceKm.toStringAsFixed(1)} km',
        ),
        _HistoryMetric(
          label: 'Goal',
          value: log.goalCompleted ? 'Met' : 'Open',
        ),
      ],
    );
  }
}

class _HistoryEntryCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final List<_HistoryMetric> children;

  const _HistoryEntryCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: pagePrimaryTextColor(context),
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: children),
        ],
      ),
    );
  }
}

class _HistoryMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HistoryMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 88),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: pageBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: pagePrimaryTextColor(context),
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
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
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? primary : pageSurfaceColor(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? primary : pageBorderColor(context),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: selected ? Colors.white : primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : pagePrimaryTextColor(context),
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryLoadingCard extends StatelessWidget {
  const _HistoryLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const AppSkeletonCard(height: 180, lineCount: 3);
  }
}

class _HistoryStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _HistoryStateCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: pageBorderColor(context)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 34),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: pagePrimaryTextColor(context),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: pageSecondaryTextColor(context),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistorySnapshot {
  final DateTime start;
  final DateTime end;
  final List<Map<String, dynamic>> dailyLogs;
  final List<BurnoutScoreSnapshot> burnoutScores;
  final List<NutritionHistoryDay> nutritionDays;
  final List<ActivityLog> activityLogs;
  final Map<_HistoryCategory, String> errors;

  const _HistorySnapshot({
    required this.start,
    required this.end,
    required this.dailyLogs,
    required this.burnoutScores,
    required this.nutritionDays,
    required this.activityLogs,
    required this.errors,
  });

  factory _HistorySnapshot.empty(_HistoryRange range) {
    final window = _rangeWindow(range);
    return _HistorySnapshot(
      start: window.start,
      end: window.end,
      dailyLogs: const [],
      burnoutScores: const [],
      nutritionDays: const [],
      activityLogs: const [],
      errors: const {},
    );
  }

  int get totalCount {
    return dailyLogs.length +
        burnoutScores.length +
        nutritionDays.length +
        activityLogs.length;
  }

  int countFor(_HistoryCategory category) {
    switch (category) {
      case _HistoryCategory.dailyLogs:
        return dailyLogs.length;
      case _HistoryCategory.burnout:
        return burnoutScores.length;
      case _HistoryCategory.nutrition:
        return nutritionDays.length;
      case _HistoryCategory.activity:
        return activityLogs.length;
    }
  }

  int countForDate(_HistoryCategory category, String dateKey) {
    bool matches(String? value) => _normalizeDateKey(value) == dateKey;

    switch (category) {
      case _HistoryCategory.dailyLogs:
        return dailyLogs
            .where(
              (log) => matches(LogApi.normalizeDateString(log['log_date'])),
            )
            .length;
      case _HistoryCategory.burnout:
        return burnoutScores.where((score) => matches(score.scoreDate)).length;
      case _HistoryCategory.nutrition:
        return nutritionDays.where((day) => matches(day.logDate)).length;
      case _HistoryCategory.activity:
        return activityLogs.where((log) => matches(log.logDate)).length;
    }
  }
}

class _DateWindow {
  final DateTime start;
  final DateTime end;

  const _DateWindow({required this.start, required this.end});

  int get dayCount => end.difference(start).inDays + 1;
}

_DateWindow _rangeWindow(_HistoryRange range) {
  final now = DateTime.now();
  final end = DateTime(now.year, now.month, now.day);
  final days = range == _HistoryRange.week ? 7 : 30;
  return _DateWindow(
    start: end.subtract(Duration(days: days - 1)),
    end: end,
  );
}

String _dateKey(DateTime date) {
  return DateFormat('yyyy-MM-dd').format(date);
}

bool _dateInWindow(DateTime? date, _HistorySnapshot snapshot) {
  if (date == null) return false;
  final normalized = DateTime(date.year, date.month, date.day);
  return !normalized.isBefore(snapshot.start) &&
      !normalized.isAfter(snapshot.end);
}

String _normalizeDateKey(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return '';
  return text.length >= 10 ? text.substring(0, 10) : text;
}

int _compareDateKeys(String? first, String? second) {
  return _normalizeDateKey(first).compareTo(_normalizeDateKey(second));
}

String _displayDate(String? dateKey) {
  final normalized = _normalizeDateKey(dateKey);
  final date = DateTime.tryParse(normalized);
  if (date == null) return 'Unknown date';
  return DateFormat('EEE, MMM d').format(date);
}

String _rangeLabel(DateTime start, DateTime end) {
  final sameYear = start.year == end.year;
  final startPattern = sameYear ? 'MMM d' : 'MMM d, yyyy';
  return '${DateFormat(startPattern).format(start)} - ${DateFormat('MMM d, yyyy').format(end)}';
}

String _categoryLabel(_HistoryCategory category) {
  switch (category) {
    case _HistoryCategory.dailyLogs:
      return 'Daily Logs';
    case _HistoryCategory.burnout:
      return 'Burnout';
    case _HistoryCategory.nutrition:
      return 'Nutrition';
    case _HistoryCategory.activity:
      return 'Activity';
  }
}

IconData _categoryIcon(_HistoryCategory category) {
  switch (category) {
    case _HistoryCategory.dailyLogs:
      return Icons.fact_check_outlined;
    case _HistoryCategory.burnout:
      return Icons.monitor_heart_outlined;
    case _HistoryCategory.nutrition:
      return Icons.restaurant_menu_rounded;
    case _HistoryCategory.activity:
      return Icons.directions_walk_rounded;
  }
}

Color _categoryColor(_HistoryCategory category) {
  switch (category) {
    case _HistoryCategory.dailyLogs:
      return const Color(0xFF2F6BFF);
    case _HistoryCategory.burnout:
      return const Color(0xFFDC2626);
    case _HistoryCategory.nutrition:
      return const Color(0xFF1FB489);
    case _HistoryCategory.activity:
      return const Color(0xFFF59E0B);
  }
}

String _formatNumber(num value) {
  return NumberFormat.decimalPattern().format(value.round());
}

String _formatCalories(double value) {
  if (value <= 0) return '--';
  return '${_formatNumber(value)} cal';
}

String _formatAmount(double value) {
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }

  return value.toStringAsFixed(1);
}

String _titleCase(String value) {
  final words = value
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .map((word) {
        if (word.length == 1) {
          return word.toUpperCase();
        }

        return '${word.substring(0, 1).toUpperCase()}${word.substring(1).toLowerCase()}';
      });

  return words.isEmpty ? 'Not set' : words.join(' ');
}

String _cleanError(Object error) {
  final message = error.toString().replaceFirst('Exception: ', '').trim();
  return message.isEmpty ? 'History is unavailable right now.' : message;
}
