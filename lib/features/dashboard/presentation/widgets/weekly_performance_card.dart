import 'package:flutter/material.dart';

import '../../data/weekly_user_metrics.dart';

class WeeklyPerformanceCard extends StatefulWidget {
  const WeeklyPerformanceCard({super.key});

  @override
  State<WeeklyPerformanceCard> createState() => _WeeklyPerformanceCardState();
}

class _WeeklyPerformanceCardState extends State<WeeklyPerformanceCard> {
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
        final consistency = metrics?.consistencyScore ?? 0;
        final goalsMet = metrics?.exerciseDays ?? 0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF4A86F7), Color.fromARGB(255, 122, 86, 189)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: snapshot.connectionState == ConnectionState.waiting
              ? const SizedBox(
                  height: 120,
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Weekly Performance',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricBlock(
                            value: '$consistency%',
                            label: 'Consistency',
                          ),
                        ),
                        Expanded(
                          child: _MetricBlock(
                            value: '$goalsMet/7',
                            label: 'Movement Days',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 16),
                    Text(
                      metrics?.weeklyNote ??
                          'Add logs to see your weekly performance.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _MetricBlock extends StatelessWidget {
  final String value;
  final String label;

  const _MetricBlock({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 42,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 15),
        ),
      ],
    );
  }
}
