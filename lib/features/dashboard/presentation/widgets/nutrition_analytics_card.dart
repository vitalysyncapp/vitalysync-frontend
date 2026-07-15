import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../features/nutrition/data/nutrition_api.dart';
import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/analytics_animation.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../../shared/widgets/reveal_on_build.dart';

const double _dailyCalorieGoal = 2000;
const double _proteinCaloriesPerGram = 4;
const double _carbCaloriesPerGram = 4;
const double _fatCaloriesPerGram = 9;
const Color _proteinColor = Color(0xFF2F80ED);
const Color _carbColor = Color(0xFF1FB489);
const Color _fatColor = Color(0xFFF59E0B);

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
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _WeeklyCalorieLevelsCard(data: data, isLoading: isLoading),
            const SizedBox(height: 12),
            _NutritionBalanceCard(data: data, isLoading: isLoading),
          ],
        );
      },
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

class _WeeklyCalorieLevelsCard extends StatelessWidget {
  final _NutritionAnalyticsSnapshot data;
  final bool isLoading;

  const _WeeklyCalorieLevelsCard({required this.data, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final averageLevel = data.loggedDays > 0
        ? _calorieLevelFor(data.averageCalories)
        : null;

    return _NutritionSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NutritionSectionHeader(
            icon: Icons.local_fire_department_rounded,
            title: 'Weekly calorie levels',
            subtitle: data.unavailable
                ? 'Saved nutrition data unavailable'
                : 'Daily energy intake made easier to read',
            gradientColors: const [Color(0xFF1FB489), Color(0xFFF59E0B)],
          ),
          const SizedBox(height: 12),
          AnalyticsContentSwitcher(
            isLoading: isLoading,
            loading: const SizedBox(
              height: 170,
              child: AppSkeletonRows(count: 5, showLeading: true),
            ),
            child: Column(
              children: List.generate(data.days.length, (index) {
                return RevealOnBuild(
                  delay: Duration(milliseconds: 45 * index),
                  duration: const Duration(milliseconds: 340),
                  beginOffset: const Offset(0, 0.08),
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: index == data.days.length - 1 ? 0 : 8,
                    ),
                    child: _CalorieLevelListItem(day: data.days[index]),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 10),
          Divider(color: pageBorderColor(context)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _NutritionMetric(
                  value: averageLevel?.label ?? '--',
                  label: 'Avg level',
                ),
              ),
              Expanded(
                child: _NutritionMetric(
                  value: data.averageCalories > 0
                      ? _formatCalories(data.averageCalories)
                      : '--',
                  label: 'Avg cal/day',
                ),
              ),
              Expanded(
                child: _NutritionMetric(
                  value: '${data.loggedDays}/7',
                  label: 'Logged days',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NutritionBalanceCard extends StatelessWidget {
  final _NutritionAnalyticsSnapshot data;
  final bool isLoading;

  const _NutritionBalanceCard({required this.data, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return _NutritionSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NutritionSectionHeader(
            icon: Icons.donut_small_rounded,
            title: 'Nutrition balance',
            subtitle: data.hasMacroData
                ? 'Protein, carbs, and fat from logged meals'
                : 'Log meals with macros to build this view',
            gradientColors: const [Color(0xFF2F80ED), Color(0xFF1FB489)],
          ),
          const SizedBox(height: 12),
          AnalyticsContentSwitcher(
            isLoading: isLoading,
            loading: const SizedBox(
              height: 130,
              child: AppSkeletonChart(height: 120, barCount: 3),
            ),
            child: _NutritionBalanceDiagram(data: data),
          ),
        ],
      ),
    );
  }
}

class _NutritionSurface extends StatelessWidget {
  final Widget child;

  const _NutritionSurface({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.2
                  : 0.06,
            ),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _NutritionSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;

  const _NutritionSectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: gradientColors),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: pagePrimaryTextColor(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                maxLines: 2,
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
    );
  }
}

class _CalorieLevelListItem extends StatelessWidget {
  final _NutritionAnalyticsDay day;

  const _CalorieLevelListItem({required this.day});

  @override
  Widget build(BuildContext context) {
    final level = _calorieLevelFor(day.calories);
    final hasLog = day.mealCount > 0 || day.calories > 0;
    final mealText = day.mealCount == 1 ? 'meal' : 'meals';
    final progress = (day.calories / _dailyCalorieGoal).clamp(0.0, 1.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: isDark
            ? level.color.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: level.color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: level.color.withValues(alpha: isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day.dayLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: level.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  day.dateLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: pageSecondaryTextColor(context),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
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
                        hasLog ? '${_formatCalories(day.calories)} cal' : '--',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: pagePrimaryTextColor(context),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _CalorieLevelPill(level: level),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedAnalyticsProgress(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: pageBorderColor(
                      context,
                    ).withValues(alpha: 0.55),
                    color: level.color,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  hasLog
                      ? '${day.mealCount} $mealText logged'
                      : 'No meal logged',
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
    );
  }
}

class _CalorieLevelPill extends StatelessWidget {
  final _CalorieLevel level;

  const _CalorieLevelPill({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: level.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: level.color.withValues(alpha: 0.22)),
      ),
      child: Text(
        level.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: level.color,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _NutritionBalanceDiagram extends StatelessWidget {
  final _NutritionAnalyticsSnapshot data;

  const _NutritionBalanceDiagram({required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final chart = _MacroPieChart(data: data);
        final legend = _MacroBalanceLegend(data: data);

        if (constraints.maxWidth >= 430) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              chart,
              const SizedBox(width: 12),
              Expanded(child: legend),
            ],
          );
        }

        return Column(
          children: [
            Center(child: chart),
            const SizedBox(height: 12),
            legend,
          ],
        );
      },
    );
  }
}

class _MacroPieChart extends StatelessWidget {
  final _NutritionAnalyticsSnapshot data;

  const _MacroPieChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final hasMacroData = data.hasMacroData;
    final primaryTextColor = pagePrimaryTextColor(context);
    return SizedBox(
      width: 128,
      height: 128,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnalyticsChartReveal(
            builder: (context, progress) {
              final sections = hasMacroData
                  ? [
                      _macroSection(
                        value: data.proteinCalories,
                        percent: data.proteinPercent,
                        color: _proteinColor,
                        progress: progress,
                      ),
                      _macroSection(
                        value: data.carbCalories,
                        percent: data.carbPercent,
                        color: _carbColor,
                        progress: progress,
                      ),
                      _macroSection(
                        value: data.fatCalories,
                        percent: data.fatPercent,
                        color: _fatColor,
                        progress: progress,
                      ),
                    ]
                  : [
                      PieChartSectionData(
                        value: 1,
                        title: '',
                        radius: 22 * progress,
                        color: pageBorderColor(context),
                      ),
                    ];

              return PieChart(
                PieChartData(
                  startDegreeOffset: -90,
                  sectionsSpace: 3 * progress,
                  centerSpaceRadius: 35,
                  borderData: FlBorderData(show: false),
                  sections: sections,
                ),
                duration: Duration.zero,
              );
            },
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                hasMacroData ? 'Balance' : 'No data',
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hasMacroData ? '${data.loggedDays} days' : 'yet',
                style: TextStyle(
                  color: pageSecondaryTextColor(context),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  PieChartSectionData _macroSection({
    required double value,
    required double percent,
    required Color color,
    required double progress,
  }) {
    return PieChartSectionData(
      value: value,
      title: progress > 0.72 && percent >= 12 ? '${percent.round()}%' : '',
      color: color,
      radius: 21 * progress,
      titleStyle: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _MacroBalanceLegend extends StatelessWidget {
  final _NutritionAnalyticsSnapshot data;

  const _MacroBalanceLegend({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MacroLegendRow(
          color: _proteinColor,
          label: 'Protein',
          percent: data.proteinPercent,
          gramsPerDay: data.averageProteinG,
          hasData: data.hasMacroData,
        ),
        const SizedBox(height: 7),
        _MacroLegendRow(
          color: _carbColor,
          label: 'Carbs',
          percent: data.carbPercent,
          gramsPerDay: data.averageCarbsG,
          hasData: data.hasMacroData,
        ),
        const SizedBox(height: 7),
        _MacroLegendRow(
          color: _fatColor,
          label: 'Fat',
          percent: data.fatPercent,
          gramsPerDay: data.averageFatG,
          hasData: data.hasMacroData,
        ),
        const SizedBox(height: 9),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: pageBorderColor(context).withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            data.balanceMessage,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: pagePrimaryTextColor(context),
              fontSize: 11.5,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _MacroLegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final double percent;
  final double gramsPerDay;
  final bool hasData;

  const _MacroLegendRow({
    required this.color,
    required this.label,
    required this.percent,
    required this.gramsPerDay,
    required this.hasData,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: pagePrimaryTextColor(context),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          hasData ? '${percent.round()}% - ${gramsPerDay.round()}g/day' : '--',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: pageSecondaryTextColor(context),
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: pagePrimaryTextColor(context),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: pageSecondaryTextColor(context),
            fontSize: 11.5,
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
          dayLabel: DateFormat('EEE').format(date),
          dateLabel: DateFormat('MMM d').format(date),
          mealCount: historyDay?.mealCount ?? 0,
          calories: historyDay?.totalCalories ?? 0,
          proteinG: historyDay?.totalProteinG ?? 0,
          carbsG: historyDay?.totalCarbsG ?? 0,
          fatG: historyDay?.totalFatG ?? 0,
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
          dayLabel: DateFormat('EEE').format(date),
          dateLabel: DateFormat('MMM d').format(date),
          mealCount: 0,
          calories: 0,
          proteinG: 0,
          carbsG: 0,
          fatG: 0,
        );
      }),
    );
  }

  int get loggedDays =>
      days.where((day) => day.mealCount > 0 || day.calories > 0).length;

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

  double get totalProteinG =>
      days.fold<double>(0, (sum, day) => sum + day.proteinG);

  double get totalCarbsG =>
      days.fold<double>(0, (sum, day) => sum + day.carbsG);

  double get totalFatG => days.fold<double>(0, (sum, day) => sum + day.fatG);

  double get averageProteinG =>
      loggedDays == 0 ? 0 : totalProteinG / loggedDays;

  double get averageCarbsG => loggedDays == 0 ? 0 : totalCarbsG / loggedDays;

  double get averageFatG => loggedDays == 0 ? 0 : totalFatG / loggedDays;

  double get proteinCalories => totalProteinG * _proteinCaloriesPerGram;

  double get carbCalories => totalCarbsG * _carbCaloriesPerGram;

  double get fatCalories => totalFatG * _fatCaloriesPerGram;

  double get totalMacroCalories => proteinCalories + carbCalories + fatCalories;

  bool get hasMacroData => totalMacroCalories > 0;

  double get proteinPercent => _macroPercent(proteinCalories);

  double get carbPercent => _macroPercent(carbCalories);

  double get fatPercent => _macroPercent(fatCalories);

  String get balanceMessage {
    if (!hasMacroData) {
      return 'No macro balance yet. Log meals with calories, protein, carbs, and fat to fill this diagram.';
    }
    if (proteinPercent < 15) {
      return 'Protein is light this week compared with carbs and fat.';
    }
    if (fatPercent > 40) {
      return 'Fat is taking the largest share of logged meal energy this week.';
    }
    if (carbPercent > 65) {
      return 'Carbs are carrying most of the logged meal energy this week.';
    }

    return 'Your logged meals show a fairly even weekly macro balance.';
  }

  double _macroPercent(double value) {
    if (totalMacroCalories <= 0) {
      return 0;
    }

    return value / totalMacroCalories * 100;
  }
}

class _NutritionAnalyticsDay {
  final String dayLabel;
  final String dateLabel;
  final int mealCount;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;

  const _NutritionAnalyticsDay({
    required this.dayLabel,
    required this.dateLabel,
    required this.mealCount,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });
}

class _CalorieLevel {
  final String label;
  final Color color;

  const _CalorieLevel({required this.label, required this.color});
}

String _formatCalories(double calories) {
  return NumberFormat.decimalPattern().format(calories.round());
}

_CalorieLevel _calorieLevelFor(double calories) {
  if (calories <= 0) {
    return const _CalorieLevel(label: 'No log', color: Color(0xFF94A3B8));
  }

  final ratio = calories / _dailyCalorieGoal;
  if (ratio < 0.6) {
    return const _CalorieLevel(label: 'Low', color: Color(0xFF2F80ED));
  }
  if (ratio < 0.9) {
    return const _CalorieLevel(label: 'Light', color: Color(0xFF14B8A6));
  }
  if (ratio <= 1.15) {
    return const _CalorieLevel(label: 'Balanced', color: Color(0xFF1FB489));
  }

  return const _CalorieLevel(label: 'High', color: Color(0xFFF59E0B));
}
