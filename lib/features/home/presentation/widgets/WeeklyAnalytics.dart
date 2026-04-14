import 'package:flutter/material.dart';

import '../../../../app/main_navigation.dart';

class WeeklyAnalyticsCard extends StatelessWidget {
  final String title;
  final List<WeeklyStatItem> items;
  final VoidCallback? onViewAll;

  const WeeklyAnalyticsCard({
    Key? key,
    this.title = 'This Week',
    required this.items,
    this.onViewAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = isDark ? const Color(0xFF1F1F1F) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final labelColor = isDark ? Colors.white70 : const Color(0xFF5F6368);
    final defaultValueColor = isDark ? Colors.white : Colors.black87;
    final linkColor = const Color(0xFF3366FF);
    final borderColor = isDark ? Colors.white10 : const Color(0xFFE6E6E6);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.25)
                : Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
              TextButton(
                onPressed:() {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const MainNavigation(initialIndex: 3)),
                      );
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: linkColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...List.generate(items.length, (index) {
            final item = items[index];
            return Padding(
              padding: EdgeInsets.only(bottom: index == items.length - 1 ? 0 : 18),
              child: _buildStatRow(
                label: item.label,
                value: item.value,
                labelColor: labelColor,
                valueColor: item.valueColor ?? defaultValueColor,
                valueWeight: item.valueWeight,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required String label,
    required String value,
    required Color labelColor,
    required Color valueColor,
    FontWeight valueWeight = FontWeight.w700,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: labelColor,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 15,
            fontWeight: valueWeight,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class WeeklyStatItem {
  final String label;
  final String value;
  final Color? valueColor;
  final FontWeight valueWeight;

  const WeeklyStatItem({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueWeight = FontWeight.w700,
  });
}
