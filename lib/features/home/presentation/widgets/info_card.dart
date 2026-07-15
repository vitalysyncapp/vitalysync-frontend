import 'package:flutter/material.dart';

import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/app_skeleton.dart';

class InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final bool isLoading;
  final String? statusHint;
  final Color? statusColor;

  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    this.isLoading = false,
    this.statusHint,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = pagePrimaryTextColor(context);
    final subtitleColor = pageSecondaryTextColor(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: pageCardShadow(context),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: subtitleColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isLoading
                ? const SizedBox(
                    key: ValueKey('loading'),
                    height: 24,
                    width: 62,
                    child: AppSkeletonLine(height: 20),
                  )
                : Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    key: ValueKey(value),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: subtitleColor, fontSize: 10.5),
          ),
          if (statusHint != null && statusHint!.isNotEmpty) ...[
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (statusColor ?? color).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: (statusColor ?? color).withValues(
                    alpha: isDark ? 0.34 : 0.22,
                  ),
                ),
              ),
              child: Text(
                statusHint!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: statusColor ?? color,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Sample usage
Widget sampleInfoCards() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: const [
      InfoCard(
        icon: Icons.local_fire_department,
        title: 'Calories',
        value: '1,240',
        subtitle: 'Today',
        color: Colors.redAccent,
      ),
      InfoCard(
        icon: Icons.directions_walk,
        title: 'Steps',
        value: '7,812',
        subtitle: 'Today',
        color: Colors.green,
      ),
      InfoCard(
        icon: Icons.bedtime,
        title: 'Sleep',
        value: '7h 45m',
        subtitle: 'Last night',
        color: Colors.blueAccent,
      ),
    ],
  );
}
