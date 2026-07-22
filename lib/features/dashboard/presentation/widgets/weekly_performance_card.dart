import 'package:flutter/material.dart';

import '../../../profile/presentation/pages/history_page.dart';
import '../../../../shared/widgets/analytics_animation.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../data/weekly_user_metrics.dart';

class WeeklyPerformanceCard extends StatelessWidget {
  final WeeklyUserMetrics? metrics;
  final bool isLoading;

  const WeeklyPerformanceCard({
    super.key,
    required this.metrics,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final consistency = metrics?.consistencyScore ?? 0;
    final goalsMet = metrics?.exerciseDays ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF4A86F7), Color.fromARGB(255, 122, 86, 189)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: AnalyticsContentSwitcher(
        isLoading: isLoading,
        loading: const SizedBox(height: 92, child: AppSkeletonRows(count: 2)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly performance',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
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
                    label: 'Movement days',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white24),
            const SizedBox(height: 10),
            Text(
              metrics?.weeklyNote ?? 'Add logs to see your weekly performance.',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryPage()),
                  );
                },
                icon: const Icon(Icons.history_rounded, size: 18),
                label: const Text(
                  'View history',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.36)),
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12.5),
        ),
      ],
    );
  }
}
