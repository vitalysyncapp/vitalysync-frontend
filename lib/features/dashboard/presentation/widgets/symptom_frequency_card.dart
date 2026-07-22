import 'package:flutter/material.dart';

import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/analytics_animation.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../../shared/widgets/reveal_on_build.dart';
import '../../data/weekly_user_metrics.dart';

class SymptomFrequencyCard extends StatelessWidget {
  final WeeklyUserMetrics? metrics;
  final bool isLoading;

  const SymptomFrequencyCard({
    super.key,
    required this.metrics,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final counts = metrics?.symptomCounts ?? const <String, int>{};
    final rows = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final visibleRows = rows.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Symptom frequency',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.bold,
              color: pagePrimaryTextColor(context),
            ),
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: AppSkeletonRows(count: 4),
            )
          else if (visibleRows.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No symptoms logged this week.',
                style: TextStyle(
                  color: pageSecondaryTextColor(context),
                  fontSize: 12.5,
                ),
              ),
            )
          else
            ...List.generate(visibleRows.length, (index) {
              final entry = visibleRows[index];
              return RevealOnBuild(
                delay: Duration(milliseconds: 65 * index),
                duration: const Duration(milliseconds: 360),
                beginOffset: const Offset(0, 0.08),
                child: _symptomRow(
                  context: context,
                  label: entry.key,
                  days: '${entry.value} ${entry.value == 1 ? 'day' : 'days'}',
                  progress: (entry.value / 7).clamp(0.0, 1.0),
                  color: _colorFor(entry.value),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _symptomRow({
    required BuildContext context,
    required String label,
    required String days,
    required double progress,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: pagePrimaryTextColor(context),
                  ),
                ),
              ),
              Text(
                days,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: pagePrimaryTextColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AnimatedAnalyticsProgress(
              value: progress,
              minHeight: 8,
              backgroundColor: pageBorderColor(context),
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFor(int days) {
    if (days >= 5) return const Color(0xFFFF3B4A);
    if (days >= 3) return const Color(0xFFFF6B00);
    return const Color(0xFFE6A800);
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
