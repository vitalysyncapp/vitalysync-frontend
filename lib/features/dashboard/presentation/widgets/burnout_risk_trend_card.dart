import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../data/burnout_score_api.dart';
import '../../../../shared/theme/app_page_style.dart';

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
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Burnout Risk Trend",
                  style: TextStyle(
                    fontSize: 18,
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
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          if (isLoading)
            const SizedBox(
              height: 250,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (points.isEmpty)
            SizedBox(
              height: 250,
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
              height: 250,
              child: LineChart(_chartData(context, points, sevenDayWindow)),
            ),
          const SizedBox(height: 14),
          _buildPatternFooter(context, sevenDayWindow, pattern),
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
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
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
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            pattern.message,
            style: TextStyle(
              color: pageSecondaryTextColor(context),
              fontSize: 13.2,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12.5,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BoxDecoration(
      color: pageSurfaceColor(context),
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.06),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      border: Border.all(color: pageBorderColor(context)),
    );
  }
}
