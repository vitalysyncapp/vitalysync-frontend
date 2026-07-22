import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/analytics_animation.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../data/weekly_user_metrics.dart';

class WellnessIndexCard extends StatelessWidget {
  final WeeklyUserMetrics? metrics;
  final bool isLoading;

  const WellnessIndexCard({
    super.key,
    required this.metrics,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final entries = [
      metrics?.sleepIndex ?? 0,
      metrics?.moodIndex ?? 0,
      metrics?.energyIndex ?? 0,
      metrics?.hydrationIndex ?? 0,
      metrics?.exerciseIndex ?? 0,
      metrics?.recoveryIndex ?? 0,
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wellness index',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.bold,
              color: pagePrimaryTextColor(context),
            ),
          ),
          const SizedBox(height: 12),
          AnalyticsContentSwitcher(
            isLoading: isLoading,
            loading: const SizedBox(
              height: 230,
              child: AppSkeletonChart(height: 220, barCount: 6),
            ),
            child: SizedBox(
              height: 230,
              child: AnalyticsChartReveal(
                builder: (context, progress) => RadarChart(
                  _chartData(context, entries, progress),
                  duration: Duration.zero,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  RadarChartData _chartData(
    BuildContext context,
    List<int> entries,
    double animationProgress,
  ) {
    return RadarChartData(
      radarShape: RadarShape.polygon,
      radarBorderData: const BorderSide(color: Colors.transparent),
      gridBorderData: BorderSide(color: pageBorderColor(context)),
      tickBorderData: BorderSide(
        color: pageBorderColor(context).withValues(alpha: 0.7),
      ),
      ticksTextStyle: TextStyle(
        color: pageSecondaryTextColor(context),
        fontSize: 10,
      ),
      getTitle: (index, angle) {
        const titles = ['Sleep', 'Mood', 'Energy', 'Water', 'Move', 'Recover'];
        return RadarChartTitle(text: titles[index], angle: 0);
      },
      titleTextStyle: TextStyle(
        color: pageSecondaryTextColor(context),
        fontSize: 11.5,
      ),
      titlePositionPercentageOffset: 0.16,
      dataSets: [
        RadarDataSet(
          fillColor: const Color(0xFF39C8A5).withValues(alpha: 0.42),
          borderColor: const Color(0xFF1AB98F),
          entryRadius: 2,
          borderWidth: 2,
          dataEntries: entries
              .map(
                (value) =>
                    RadarEntry(value: value.toDouble() * animationProgress),
              )
              .toList(),
        ),
      ],
      tickCount: 4,
      radarTouchData: RadarTouchData(enabled: false),
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
