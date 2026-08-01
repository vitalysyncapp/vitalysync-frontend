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
    final components = _components(metrics);

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
          const SizedBox(height: 3),
          Text(
            'Your weekly patterns across six everyday wellness areas',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.3,
              color: pageSecondaryTextColor(context),
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
                  _chartData(context, components, progress),
                  duration: Duration.zero,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: _insights(
              components,
            ).map((insight) => _WellnessInsightPill(insight: insight)).toList(),
          ),
          const SizedBox(height: 10),
          Text(
            'Each spoke is a 0–100 habit score; Steps uses your daily goal. This is a wellness guide, not a medical assessment.',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.4,
              color: pageSecondaryTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  RadarChartData _chartData(
    BuildContext context,
    List<_WellnessComponent> components,
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
        return RadarChartTitle(text: components[index].label, angle: 0);
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
          dataEntries: components
              .map(
                (component) => RadarEntry(
                  value: component.value.toDouble() * animationProgress,
                ),
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

  List<_WellnessComponent> _components(WeeklyUserMetrics? metrics) {
    final days = metrics?.days ?? const <DailyUserMetric>[];
    final hasMood = days.any((day) => day.moodIndex != null);
    final hasEnergy = days.any((day) => day.energyLevel != null);
    final hasBreakQuality = days.any((day) => day.breakQualityLevel != null);
    final hasSteps = days.any((day) => day.activity != null);

    return [
      _WellnessComponent(
        label: 'Sleep',
        value: metrics?.sleepIndex ?? 0,
        hasData: (metrics?.averageSleep ?? 0) > 0,
      ),
      _WellnessComponent(
        label: 'Mood',
        value: metrics?.moodIndex ?? 0,
        hasData: hasMood,
      ),
      _WellnessComponent(
        label: 'Energy',
        value: metrics?.energyIndex ?? 0,
        hasData: hasEnergy,
      ),
      _WellnessComponent(
        label: 'Water',
        value: metrics?.hydrationIndex ?? 0,
        hasData: (metrics?.averageHydration ?? 0) > 0,
      ),
      _WellnessComponent(
        label: 'Steps',
        value: metrics?.stepIndex ?? 0,
        hasData: hasSteps,
      ),
      _WellnessComponent(
        label: 'Recover',
        value: metrics?.recoveryIndex ?? 0,
        hasData: (metrics?.averageSleep ?? 0) > 0 || hasBreakQuality,
      ),
    ];
  }

  List<_WellnessInsight> _insights(List<_WellnessComponent> components) {
    final available = components
        .where((component) => component.hasData)
        .toList();
    if (available.isEmpty) {
      return const [
        _WellnessInsight(
          label: 'Add logs to build your index',
          color: Color(0xFF64748B),
        ),
        _WellnessInsight(label: 'Data: 0/6 areas', color: Color(0xFF0EA5E9)),
      ];
    }

    final strongest = available.reduce(
      (current, next) => current.value >= next.value ? current : next,
    );
    final buildArea = available.reduce(
      (current, next) => current.value <= next.value ? current : next,
    );

    return [
      _WellnessInsight(
        label: 'Highest: ${strongest.label} ${strongest.value}%',
        color: const Color(0xFF16A34A),
      ),
      if (available.length > 1)
        _WellnessInsight(
          label: 'Build: ${buildArea.label} ${buildArea.value}%',
          color: const Color(0xFFF59E0B),
        )
      else
        const _WellnessInsight(
          label: 'Add logs for a fuller view',
          color: Color(0xFFF59E0B),
        ),
      _WellnessInsight(
        label: 'Data: ${available.length}/6 areas',
        color: const Color(0xFF0EA5E9),
      ),
    ];
  }
}

class _WellnessComponent {
  final String label;
  final int value;
  final bool hasData;

  const _WellnessComponent({
    required this.label,
    required this.value,
    required this.hasData,
  });
}

class _WellnessInsight {
  final String label;
  final Color color;

  const _WellnessInsight({required this.label, required this.color});
}

class _WellnessInsightPill extends StatelessWidget {
  final _WellnessInsight insight;

  const _WellnessInsightPill({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: insight.color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: insight.color.withValues(alpha: 0.22)),
      ),
      child: Text(
        insight.label,
        style: TextStyle(
          color: insight.color,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
