import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/analytics_animation.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../data/weekly_user_metrics.dart';
import 'package:vitalysync/l10n/localized_text.dart';

const Color _moodAccent = Color(0xFF1FB489);

class MoodVolatilityCard extends StatelessWidget {
  final WeeklyUserMetrics? metrics;
  final bool isLoading;

  const MoodVolatilityCard({
    super.key,
    required this.metrics,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final days = metrics?.days ?? const <DailyUserMetric>[];
    final loggedMoodDays = days.where((day) => day.moodIndex != null).length;
    final averageMood = metrics?.averageMood ?? 0;
    final averageMoodScore = averageMood + 1;
    final trendLabel = metrics?.moodTrendLabel ?? 'Needs more logs';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _MoodCardHeader(),
          const SizedBox(height: 16),
          AnalyticsContentSwitcher(
            isLoading: isLoading,
            loading: const SizedBox(
              height: 246,
              child: AppSkeletonChart(height: 232, barCount: 7),
            ),
            contentKey: Object.hashAll([
              loggedMoodDays,
              ...days.map((day) => day.moodIndex),
            ]),
            child: loggedMoodDays == 0
                ? const _MoodEmptyState()
                : Column(
                    children: [
                      _MoodSummary(
                        averageMoodScore: averageMoodScore,
                        trendLabel: trendLabel,
                        loggedDays: loggedMoodDays,
                      ),
                      const SizedBox(height: 14),
                      Semantics(
                        container: true,
                        image: true,
                        label:
                            'Mood trend: $loggedMoodDays of 7 days logged. '
                            'Average ${averageMoodScore.toStringAsFixed(1)} out of 5, '
                            '${_moodLabel(averageMood.round())}. '
                            'Pattern $trendLabel.',
                        child: ExcludeSemantics(
                          child: Container(
                            key: const ValueKey('mood-trend-chart'),
                            height: 176,
                            padding: const EdgeInsets.fromLTRB(6, 10, 10, 2),
                            decoration: BoxDecoration(
                              color: pageSubtleSurfaceColor(context),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: pageBorderColor(context),
                              ),
                            ),
                            child: AnalyticsChartReveal(
                              builder: (context, progress) => LineChart(
                                _chartData(
                                  context,
                                  days,
                                  averageMoodScore,
                                  trendLabel,
                                  progress,
                                ),
                                duration: Duration.zero,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  LineChartData _chartData(
    BuildContext context,
    List<DailyUserMetric> days,
    double averageMoodScore,
    String trendLabel,
    double animationProgress,
  ) {
    final chartDays = days.length == 7 ? days : _placeholderDays(days);
    final lineColor = _trendColor(trendLabel);
    final spots = List<FlSpot>.generate(chartDays.length, (index) {
      final mood = chartDays[index].moodIndex;
      if (mood == null) return FlSpot.nullSpot;
      return FlSpot(index.toDouble(), 1 + mood * animationProgress);
    });

    return LineChartData(
      minX: -0.18,
      maxX: 6.18,
      minY: 1,
      maxY: 5,
      clipData: const FlClipData.all(),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 1,
        getDrawingHorizontalLine: (_) => FlLine(
          color: pageBorderColor(context).withValues(alpha: 0.62),
          strokeWidth: 1,
          dashArray: [4, 4],
        ),
      ),
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          HorizontalLine(
            y: 1 + (averageMoodScore - 1) * animationProgress,
            color: lineColor.withValues(alpha: 0.45),
            strokeWidth: 1,
            dashArray: [5, 4],
          ),
        ],
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            reservedSize: 29,
            getTitlesWidget: (value, meta) {
              if (value != 1 && value != 3 && value != 5) {
                return const SizedBox.shrink();
              }
              return LocalizedText(
                _moodEmoji(value.round() - 1),
                translate: false,
                style: const TextStyle(fontSize: 14),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              final index = value.round();
              if (index < 0 ||
                  index >= chartDays.length ||
                  (value - index).abs() > 0.1) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 7),
                child: LocalizedText(
                  _shortDayLabel(chartDays[index].dayLabel),
                  style: TextStyle(
                    color: pageSecondaryTextColor(context),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          tooltipBorderRadius: BorderRadius.circular(10),
          tooltipPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 7,
          ),
          getTooltipColor: (_) =>
              Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF26354A)
              : const Color(0xFF10334A),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final index = spot.x.round();
              final dayLabel = index >= 0 && index < chartDays.length
                  ? chartDays[index].dayLabel
                  : '';
              return LineTooltipItem(
                '$dayLabel\n${spot.y.round()}/5 - ${_moodLabel(spot.y.round() - 1)}',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              );
            }).toList();
          },
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.24,
          preventCurveOverShooting: true,
          color: lineColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4.5,
                color: lineColor,
                strokeWidth: 2,
                strokeColor: pageSurfaceColor(context),
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                lineColor.withValues(alpha: 0.20),
                lineColor.withValues(alpha: 0.02),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<DailyUserMetric> _placeholderDays(List<DailyUserMetric> days) {
    return List.generate(7, (index) {
      if (index < days.length) return days[index];
      return DailyUserMetric(
        date: DateTime(2000, 1, index + 1),
        dateKey: '',
        dayLabel: const [
          'Mon',
          'Tue',
          'Wed',
          'Thu',
          'Fri',
          'Sat',
          'Sun',
        ][index],
        log: null,
        activity: null,
      );
    });
  }

  Color _trendColor(String trendLabel) {
    switch (trendLabel) {
      case 'Improving':
        return const Color(0xFF1B9E77);
      case 'Lower':
        return const Color(0xFFD28A16);
      case 'Stable':
        return const Color(0xFF4A7DF3);
      default:
        return _moodAccent;
    }
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

class _MoodCardHeader extends StatelessWidget {
  const _MoodCardHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _moodAccent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.show_chart_rounded,
            color: _moodAccent,
            size: 22,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LocalizedText(
                'Mood trend',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  color: pagePrimaryTextColor(context),
                ),
              ),
              const SizedBox(height: 2),
              LocalizedText(
                'Daily check-ins over the last 7 days',
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

class _MoodSummary extends StatelessWidget {
  final double averageMoodScore;
  final String trendLabel;
  final int loggedDays;

  const _MoodSummary({
    required this.averageMoodScore,
    required this.trendLabel,
    required this.loggedDays,
  });

  @override
  Widget build(BuildContext context) {
    final trendColor = _summaryTrendColor(trendLabel);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _moodAccent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _moodAccent.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          LocalizedText(
            _moodEmoji((averageMoodScore - 1).round()),
            translate: false,
            style: const TextStyle(fontSize: 29),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LocalizedText(
                  _moodLabel((averageMoodScore - 1).round()),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: pagePrimaryTextColor(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                LocalizedText(
                  '${averageMoodScore.toStringAsFixed(1)}/5 average - $loggedDays/7 logged',
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
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: trendColor.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: trendColor.withValues(alpha: 0.20)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_trendIcon(trendLabel), color: trendColor, size: 14),
                const SizedBox(width: 4),
                LocalizedText(
                  trendLabel,
                  style: TextStyle(
                    color: trendColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _summaryTrendColor(String label) {
    switch (label) {
      case 'Improving':
        return const Color(0xFF168265);
      case 'Lower':
        return const Color(0xFFB66A05);
      case 'Stable':
        return const Color(0xFF315FC4);
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _trendIcon(String label) {
    switch (label) {
      case 'Improving':
        return Icons.trending_up_rounded;
      case 'Lower':
        return Icons.trending_down_rounded;
      default:
        return Icons.trending_flat_rounded;
    }
  }
}

class _MoodEmptyState extends StatelessWidget {
  const _MoodEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('mood-trend-empty-state'),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 190),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: pageSubtleSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: pageBorderColor(context)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _moodAccent.withValues(alpha: 0.11),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sentiment_satisfied_alt_rounded,
              color: _moodAccent,
              size: 27,
            ),
          ),
          const SizedBox(height: 11),
          LocalizedText(
            'Your mood trend will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: pagePrimaryTextColor(context),
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          LocalizedText(
            'Log mood on at least two days to reveal a weekly pattern.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: pageSecondaryTextColor(context),
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

String _moodEmoji(int value) {
  switch (value.clamp(0, 4)) {
    case 4:
      return '\u{1F60A}';
    case 3:
      return '\u{1F642}';
    case 2:
      return '\u{1F610}';
    case 1:
      return '\u{1F641}';
    default:
      return '\u{1F61E}';
  }
}

String _moodLabel(int value) {
  switch (value.clamp(0, 4)) {
    case 4:
      return 'Great';
    case 3:
      return 'Good';
    case 2:
      return 'Okay';
    case 1:
      return 'Low';
    default:
      return 'Very low';
  }
}

String _shortDayLabel(String dayLabel) {
  final trimmed = dayLabel.trim();
  if (trimmed.isEmpty) return '--';
  return trimmed.length <= 2 ? trimmed : trimmed.substring(0, 2);
}
