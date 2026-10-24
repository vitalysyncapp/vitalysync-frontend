import 'package:flutter/material.dart';
import '../../../../shared/theme/app_page_style.dart';

class InsightHighlightTile extends StatelessWidget {
  final Map<String, dynamic> highlight;
  const InsightHighlightTile({super.key, required this.highlight});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (highlight['topic']) {
      'sleep' => (Icons.bedtime_outlined, const Color(0xFF8B5CF6)),
      'mood_energy' => (
        Icons.sentiment_satisfied_alt_rounded,
        const Color(0xFFD19324),
      ),
      'activity' => (Icons.directions_walk_rounded, const Color(0xFF218A9A)),
      'hydration' => (Icons.water_drop_outlined, const Color(0xFF3487D0)),
      'nutrition' => (Icons.restaurant_rounded, const Color(0xFF279A73)),
      _ => (Icons.insights_rounded, Theme.of(context).colorScheme.primary),
    };
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  highlight['label']?.toString() ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: pagePrimaryTextColor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  highlight['observation']?.toString() ?? '',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: pageSecondaryTextColor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
