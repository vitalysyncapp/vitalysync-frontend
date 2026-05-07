import 'package:flutter/material.dart';

import '../../../../app/main_navigation.dart';
import '../../../../features/dashboard/data/weekly_user_metrics.dart';
import '../../../../shared/theme/app_page_style.dart';

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

    final cardColor = pageSurfaceColor(context);
    final titleColor = pagePrimaryTextColor(context);
    final labelColor = pageSecondaryTextColor(context);
    final defaultValueColor = pagePrimaryTextColor(context);
    final linkColor = isDark
        ? const Color(0xFF82DFFF)
        : const Color(0xFF2088D8);
    final borderColor = pageBorderColor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.25)
                : Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
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
                onPressed: () {
                  final controller = MainNavigationController.maybeOf(context);
                  if (controller != null) {
                    controller.onTabSelected(3);
                    return;
                  }

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MainNavigation(initialIndex: 3),
                    ),
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
              padding: EdgeInsets.only(
                bottom: index == items.length - 1 ? 0 : 18,
              ),
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

class HomeWeeklyAnalyticsCard extends StatefulWidget {
  const HomeWeeklyAnalyticsCard({super.key});

  @override
  State<HomeWeeklyAnalyticsCard> createState() =>
      _HomeWeeklyAnalyticsCardState();
}

class _HomeWeeklyAnalyticsCardState extends State<HomeWeeklyAnalyticsCard> {
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
        final items = metrics == null
            ? const [
                WeeklyStatItem(label: 'Average Sleep', value: 'Loading'),
                WeeklyStatItem(label: 'Mood Trend', value: 'Loading'),
                WeeklyStatItem(label: 'Exercise Days', value: 'Loading'),
              ]
            : [
                WeeklyStatItem(
                  label: 'Average Sleep',
                  value: metrics.averageSleep > 0
                      ? '${metrics.averageSleep.toStringAsFixed(1)} hours'
                      : 'No logs',
                ),
                WeeklyStatItem(
                  label: 'Mood Trend',
                  value: metrics.moodTrendLabel,
                  valueColor: metrics.moodTrendLabel == 'Improving'
                      ? const Color(0xFF12A150)
                      : null,
                ),
                WeeklyStatItem(
                  label: 'Exercise Days',
                  value: '${metrics.exerciseDays} of 7',
                ),
              ];

        return WeeklyAnalyticsCard(items: items);
      },
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
