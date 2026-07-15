import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../data/burnout_score_api.dart';
import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/app_skeleton.dart';

class BurnoutRiskTrendCard extends StatelessWidget {
  final BurnoutPatternSummary? summary;
  final bool isLoading;
  final Future<void> Function()? onRefresh;

  const BurnoutRiskTrendCard({
    super.key,
    required this.summary,
    required this.isLoading,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final sevenDayWindow = summary?.windowForDays(7);
    final points = sevenDayWindow?.points ?? const <BurnoutPatternPoint>[];
    final pattern = summary?.patterns.isNotEmpty == true
        ? summary!.patterns.first
        : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Burnout risk trend",
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: pagePrimaryTextColor(context),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: isLoading ? null : onRefresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          Text(
            _subtitle(sevenDayWindow),
            style: TextStyle(
              color: pageSecondaryTextColor(context),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const SizedBox(height: 200, child: AppSkeletonChart(height: 190))
          else if (points.isEmpty)
            SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'No score history yet',
                  style: TextStyle(
                    color: pageSecondaryTextColor(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: LineChart(_chartData(context, points, sevenDayWindow)),
            ),
          _buildDimensionScoreRow(context),
          const SizedBox(height: 10),
          _buildPatternFooter(context, sevenDayWindow, pattern),
        ],
      ),
    );
  }

  Widget _buildDimensionScoreRow(BuildContext context) {
    final latestScore = summary?.latestScore;
    final dimensions = [
      _DimensionMetric(
        label: 'Exhaustion',
        score: latestScore?.emotionalExhaustionScore,
        color: const Color(0xFFFF8A1F),
      ),
      _DimensionMetric(
        label: 'Detachment',
        score: latestScore?.detachmentScore,
        color: const Color(0xFF14B8A6),
      ),
      _DimensionMetric(
        label: 'Accomplishment',
        score: latestScore?.reducedAccomplishmentScore,
        color: const Color(0xFF2563EB),
      ),
    ].where((dimension) => dimension.score != null).toList();

    if (dimensions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: dimensions.map((dimension) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: dimension == dimensions.last ? 0 : 7,
              ),
              child: _dimensionChip(context, dimension),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _dimensionChip(BuildContext context, _DimensionMetric dimension) {
    final score = dimension.score!.clamp(0, 100).toDouble();

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: dimension.color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dimension.color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dimension.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: pagePrimaryTextColor(context),
              fontSize: 10.8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 5,
              backgroundColor: dimension.color.withValues(alpha: 0.14),
              valueColor: AlwaysStoppedAnimation<Color>(dimension.color),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            score.round().toString(),
            style: TextStyle(
              color: dimension.color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  String _subtitle(BurnoutWindowSummary? window) {
    if (window == null) {
      return 'Last 7 days';
    }

    final delta = window.deltaFromStart;
    final trend = _trendLabel(window.trendDirection);
    if (delta == null) {
      return 'Last 7 days - $trend';
    }

    final prefix = delta > 0 ? '+' : '';
    return 'Last 7 days - $trend ($prefix${delta.toStringAsFixed(1)})';
  }

  String _trendLabel(String trend) {
    switch (trend) {
      case 'rising':
        return 'rising';
      case 'falling':
        return 'improving';
      case 'stable':
        return 'stable';
      default:
        return 'collecting data';
    }
  }

  LineChartData _chartData(
    BuildContext context,
    List<BurnoutPatternPoint> points,
    BurnoutWindowSummary? window,
  ) {
    final spots = List.generate(
      points.length,
      (index) => FlSpot(index.toDouble(), points[index].overallScore),
    );
    final lineColor = _trendColor(window?.trendDirection);
    final maxX = math.max(1, points.length - 1).toDouble();

    return LineChartData(
      minX: 0,
      maxX: maxX,
      minY: 0,
      maxY: 100,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 25,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) => FlLine(
          color: pageBorderColor(context).withValues(alpha: 0.70),
          strokeWidth: 1,
          dashArray: [4, 4],
        ),
        getDrawingVerticalLine: (value) => FlLine(
          color: pageBorderColor(context).withValues(alpha: 0.50),
          strokeWidth: 1,
          dashArray: [4, 4],
        ),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              final index = value.round();
              if (index < 0 ||
                  index >= points.length ||
                  (value - index).abs() > 0.1) {
                return const SizedBox();
              }

              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _weekdayLabel(points[index].scoreDate),
                  style: TextStyle(
                    color: pageSecondaryTextColor(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 25,
            reservedSize: 34,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: TextStyle(
                  color: pageSecondaryTextColor(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: pageBorderColor(context)),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: spots.length > 2,
          color: lineColor,
          barWidth: 3,
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
            color: lineColor.withValues(alpha: 0.10),
          ),
        ),
      ],
    );
  }

  Widget _buildPatternFooter(
    BuildContext context,
    BurnoutWindowSummary? window,
    BurnoutPatternInsight? pattern,
  ) {
    final confidence = window?.averageConfidenceScore;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _metricChip(
              context,
              Icons.insights_rounded,
              summary?.adaptiveState.label ?? 'No pattern',
              _priorityColor(summary?.adaptiveState.priority),
            ),
            if (confidence != null)
              _metricChip(
                context,
                Icons.verified_outlined,
                '${confidence.round()}% confidence',
                const Color(0xFF2563EB),
              ),
            if (window?.dominantDimensionLabel != null)
              _metricChip(
                context,
                Icons.center_focus_strong_rounded,
                window!.dominantDimensionLabel!,
                const Color(0xFF7C3AED),
              ),
          ],
        ),
        if (pattern != null) ...[
          const SizedBox(height: 12),
          Text(
            pattern.title,
            style: TextStyle(
              color: pagePrimaryTextColor(context),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            pattern.message,
            style: TextStyle(
              color: pageSecondaryTextColor(context),
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _metricChip(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Color _trendColor(String? trend) {
    switch (trend) {
      case 'rising':
        return const Color(0xFFDC2626);
      case 'falling':
        return const Color(0xFF16A34A);
      case 'stable':
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _priorityColor(String? priority) {
    switch (priority) {
      case 'urgent':
      case 'high':
        return const Color(0xFFDC2626);
      case 'medium':
        return const Color(0xFFF97316);
      default:
        return const Color(0xFF16A34A);
    }
  }

  String _weekdayLabel(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return '';
    }

    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[parsed.weekday - 1];
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

class _DimensionMetric {
  final String label;
  final double? score;
  final Color color;

  const _DimensionMetric({
    required this.label,
    required this.score,
    required this.color,
  });
}
