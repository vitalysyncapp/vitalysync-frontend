import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../features/nutrition/data/nutrition_api.dart';
import '../../../../shared/theme/app_page_style.dart';

class NutritionAnalyticsCard extends StatefulWidget {
  const NutritionAnalyticsCard({super.key});

  @override
  State<NutritionAnalyticsCard> createState() => _NutritionAnalyticsCardState();
}

class _NutritionAnalyticsCardState extends State<NutritionAnalyticsCard> {
  late Future<_NutritionAnalyticsSnapshot> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadSnapshot();
  }

  Future<_NutritionAnalyticsSnapshot> _loadSnapshot() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: 6));

    try {
      final history = await NutritionApi.fetchHistory(
        start: _dateKey(start),
        end: _dateKey(today),
      );
      return _NutritionAnalyticsSnapshot.fromHistory(
        start: start,
        history: history,
      );
    } catch (_) {
      return _NutritionAnalyticsSnapshot.empty(start: start, unavailable: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_NutritionAnalyticsSnapshot>(
      future: _future,
      builder: (context, snapshot) {
        final data =
            snapshot.data ??
            _NutritionAnalyticsSnapshot.empty(
              start: DateTime.now().subtract(const Duration(days: 6)),
            );

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: pageSurfaceColor(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: pageBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.2
                      : 0.06,
                ),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
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
                        colors: [Color(0xFF1FB489), Color(0xFF2F80ED)],
                      ),
                    ),
                    child: const Icon(
                      Icons.restaurant_menu_rounded,
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
                          'Nutrition Analytics',
                          style: TextStyle(
                            color: pagePrimaryTextColor(context),
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          data.unavailable
                              ? 'Saved nutrition data unavailable'
                              : '7-day meal logging overview',
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
              const SizedBox(height: 18),
              if (snapshot.connectionState == ConnectionState.waiting)
                const SizedBox(
                  height: 210,
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                SizedBox(
                  height: 210,
                  child: BarChart(_chartData(context, data)),
                ),
              const SizedBox(height: 16),
              Divider(color: pageBorderColor(context)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _NutritionMetric(
                      value: '${data.loggedDays}/7',
                      label: 'Logged days',
                    ),
                  ),
                  Expanded(
                    child: _NutritionMetric(
                      value: data.averageMeals > 0
                          ? data.averageMeals.toStringAsFixed(1)
                          : '--',
                      label: 'Avg meals',
                    ),
                  ),
                  Expanded(
                    child: _NutritionMetric(
                      value: data.averageCalories > 0
                          ? data.averageCalories.round().toString()
                          : '--',
                      label: 'Avg cal',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  BarChartData _chartData(
    BuildContext context,
    _NutritionAnalyticsSnapshot data,
  ) {
    final textColor = pageSecondaryTextColor(context);

    return BarChartData(
      minY: 0,
      maxY: 4,
      groupsSpace: 8,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 1,
        getDrawingHorizontalLine: (value) => FlLine(
          color: pageBorderColor(context).withValues(alpha: 0.72),
          strokeWidth: 1,
          dashArray: [4, 4],
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: pageBorderColor(context)),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            reservedSize: 28,
            getTitlesWidget: (value, meta) => Text(
              value.toInt().toString(),
              style: TextStyle(color: textColor, fontSize: 12),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= data.days.length) {
                return const SizedBox();
              }

              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  data.days[index].dayLabel,
                  style: TextStyle(color: textColor, fontSize: 12),
                ),
              );
            },
          ),
        ),
      ),
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final day = data.days[group.x.toInt()];
            final mealText = day.mealCount == 1 ? 'meal' : 'meals';
            return BarTooltipItem(
              '${day.dayLabel}\n${day.mealCount} $mealText\n${day.calories.round()} cal',
              TextStyle(
                color: pagePrimaryTextColor(context),
                fontWeight: FontWeight.w700,
                fontSize: 12,
                height: 1.35,
              ),
            );
          },
        ),
      ),
      barGroups: List.generate(data.days.length, (index) {
        final day = data.days[index];
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: day.mealCount.clamp(0, 4).toDouble(),
              width: 22,
              borderRadius: BorderRadius.circular(7),
              color: day.mealCount >= 3
                  ? const Color(0xFF1FB489)
                  : day.mealCount > 0
                  ? const Color(0xFF2F80ED)
                  : const Color(0xFFCBD5E1),
            ),
          ],
        );
      }),
    );
  }

  String _dateKey(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).toIso8601String().substring(0, 10);
  }
}

class _NutritionMetric extends StatelessWidget {
  final String value;
  final String label;

  const _NutritionMetric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: pagePrimaryTextColor(context),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: pageSecondaryTextColor(context),
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _NutritionAnalyticsSnapshot {
  final List<_NutritionAnalyticsDay> days;
  final bool unavailable;

  const _NutritionAnalyticsSnapshot({
    required this.days,
    this.unavailable = false,
  });

  factory _NutritionAnalyticsSnapshot.fromHistory({
    required DateTime start,
    required List<NutritionHistoryDay> history,
  }) {
    final byDate = {for (final day in history) day.logDate: day};

    return _NutritionAnalyticsSnapshot(
      days: List.generate(7, (index) {
        final date = start.add(Duration(days: index));
        final key = DateTime(
          date.year,
          date.month,
          date.day,
        ).toIso8601String().substring(0, 10);
        final historyDay = byDate[key];

        return _NutritionAnalyticsDay(
          date: date,
          dayLabel: DateFormat('E').format(date).substring(0, 1),
          mealCount: historyDay?.mealCount ?? 0,
          calories: historyDay?.totalCalories ?? 0,
        );
      }),
    );
  }

  factory _NutritionAnalyticsSnapshot.empty({
    required DateTime start,
    bool unavailable = false,
  }) {
    return _NutritionAnalyticsSnapshot(
      unavailable: unavailable,
      days: List.generate(7, (index) {
        final date = start.add(Duration(days: index));
        return _NutritionAnalyticsDay(
          date: date,
          dayLabel: DateFormat('E').format(date).substring(0, 1),
          mealCount: 0,
          calories: 0,
        );
      }),
    );
  }

  int get loggedDays => days.where((day) => day.mealCount > 0).length;

  double get averageMeals {
    if (loggedDays == 0) {
      return 0;
    }

    final totalMeals = days.fold<int>(0, (sum, day) => sum + day.mealCount);
    return totalMeals / days.length;
  }

  double get averageCalories {
    if (loggedDays == 0) {
      return 0;
    }

    final totalCalories = days.fold<double>(
      0,
      (sum, day) => sum + day.calories,
    );
    return totalCalories / loggedDays;
  }
}

class _NutritionAnalyticsDay {
  final DateTime date;
  final String dayLabel;
  final int mealCount;
  final double calories;

  const _NutritionAnalyticsDay({
    required this.date,
    required this.dayLabel,
    required this.mealCount,
    required this.calories,
  });
}
