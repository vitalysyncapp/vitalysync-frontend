import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../shared/theme/app_page_style.dart';
import '../../data/weekly_user_metrics.dart';

class SleepPatternCard extends StatefulWidget {
  const SleepPatternCard({super.key});

  @override
  State<SleepPatternCard> createState() => _SleepPatternCardState();
}

class _SleepPatternCardState extends State<SleepPatternCard> {
  late Future<WeeklyUserMetrics> _future;

  @override
  void initState() {
    super.initState();
    _future = WeeklyUserMetricsService.loadCurrentWeek();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WeeklyUserMetrics>(
      future: _future,
      builder: (context, snapshot) {
        final metrics = snapshot.data;
        final days = metrics?.days ?? const <DailyUserMetric>[];
        final average = metrics?.averageSleep ?? 0;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sleep Pattern',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  color: pagePrimaryTextColor(context),
                ),
              ),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting)
                const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                SizedBox(
                  height: 200,
                  child: BarChart(_chartData(context, days)),
                ),
              const SizedBox(height: 12),
              Divider(color: pageBorderColor(context)),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Recommended: 7-9 hours',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: pageSecondaryTextColor(context),
                      ),
                    ),
                  ),
                  Text(
                    average > 0
                        ? 'Average: ${average.toStringAsFixed(1)}h'
                        : 'No logs yet',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2F66F3),
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

  BarChartData _chartData(BuildContext context, List<DailyUserMetric> days) {
    final chartDays = days.isEmpty
        ? List<DailyUserMetric>.generate(
            7,
            (index) => DailyUserMetric(
              date: DateTime.now(),
              dateKey: '',
              dayLabel: '',
              log: null,
              activity: null,
            ),
          )
        : days;

    return BarChartData(
      maxY: 10,
      minY: 0,
      groupsSpace: 6,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 2,
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
            interval: 2,
            reservedSize: 28,
            getTitlesWidget: (value, meta) => Text(
              value.toInt().toString(),
              style: TextStyle(
                color: pageSecondaryTextColor(context),
                fontSize: 10.5,
              ),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= chartDays.length) {
                return const SizedBox();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  chartDays[index].dayLabel,
                  style: TextStyle(
                    color: pageSecondaryTextColor(context),
                    fontSize: 11,
                  ),
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
            final day = chartDays[group.x.toInt()];
            return BarTooltipItem(
              '${day.dayLabel}\n${rod.toY.toStringAsFixed(1)} hours',
              TextStyle(
                color: pagePrimaryTextColor(context),
                fontWeight: FontWeight.w600,
                fontSize: 11.5,
                height: 1.4,
              ),
            );
          },
        ),
      ),
      barGroups: List.generate(
        chartDays.length,
        (index) => BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: chartDays[index].sleepHours,
              width: 18,
              borderRadius: BorderRadius.circular(8),
              color: chartDays[index].sleepHours >= 7
                  ? const Color(0xFF1FB489)
                  : const Color(0xFF4A86F7),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    return BoxDecoration(
      color: pageSurfaceColor(context),
      borderRadius: BorderRadius.circular(18),
      boxShadow: pageCardShadow(context),
      border: Border.all(color: pageBorderColor(context)),
    );
  }
}
