import 'package:flutter/material.dart';

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

    // Card background color adapts to theme
    final cardBackground = isDark ? Colors.grey[850] : Colors.white;

    // Shadow for depth
    final boxShadow = [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.5)
            : Colors.grey.withValues(alpha: 0.2),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ];

    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white70 : Colors.grey[600];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: boxShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              color: subtitleColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isLoading
                ? SizedBox(
                    key: const ValueKey('loading'),
                    height: 28,
                    width: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: color,
                    ),
                  )
                : Text(
                    value,
                    key: ValueKey(value),
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: subtitleColor, fontSize: 11),
          ),
          if (statusHint != null && statusHint!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: (statusColor ?? color).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: (statusColor ?? color).withValues(alpha: 0.22),
                ),
              ),
              child: Text(
                statusHint!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
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
        subtitle: 'Last Night',
        color: Colors.blueAccent,
      ),
    ],
  );
}
