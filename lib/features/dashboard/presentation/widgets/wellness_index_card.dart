import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../data/weekly_user_metrics.dart';

class WellnessIndexCard extends StatefulWidget {
  const WellnessIndexCard({super.key});

  @override
  State<WellnessIndexCard> createState() => _WellnessIndexCardState();
}

class _WellnessIndexCardState extends State<WellnessIndexCard> {
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
        final entries = [
          metrics?.sleepIndex ?? 0,
          metrics?.moodIndex ?? 0,
          metrics?.energyIndex ?? 0,
          metrics?.hydrationIndex ?? 0,
          metrics?.exerciseIndex ?? 0,
          metrics?.recoveryIndex ?? 0,
        ];

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Wellness Index',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B1F44),
                ),
              ),
              const SizedBox(height: 18),
              if (snapshot.connectionState == ConnectionState.waiting)
                const SizedBox(
                  height: 300,
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                SizedBox(height: 300, child: RadarChart(_chartData(entries))),
            ],
          ),
        );
      },
    );
  }

  RadarChartData _chartData(List<int> entries) {
    return RadarChartData(
      radarShape: RadarShape.polygon,
      radarBorderData: const BorderSide(color: Colors.transparent),
      gridBorderData: BorderSide(color: Colors.grey.withValues(alpha: 0.20)),
      tickBorderData: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
      ticksTextStyle: const TextStyle(color: Color(0xFF9AA5B1), fontSize: 11),
      getTitle: (index, angle) {
        const titles = ['Sleep', 'Mood', 'Energy', 'Water', 'Move', 'Recover'];
        return RadarChartTitle(text: titles[index], angle: 0);
      },
      titleTextStyle: const TextStyle(color: Color(0xFF4F5D75), fontSize: 13),
      titlePositionPercentageOffset: 0.18,
      dataSets: [
        RadarDataSet(
          fillColor: const Color(0xFF39C8A5).withValues(alpha: 0.42),
          borderColor: const Color(0xFF1AB98F),
          entryRadius: 2,
          borderWidth: 2,
          dataEntries: entries
              .map((value) => RadarEntry(value: value.toDouble()))
              .toList(),
        ),
      ],
      tickCount: 4,
      radarTouchData: RadarTouchData(enabled: false),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      border: Border.all(color: Colors.grey.withValues(alpha: 0.10)),
    );
  }
}
