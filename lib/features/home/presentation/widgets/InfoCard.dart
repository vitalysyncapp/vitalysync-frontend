import 'package:flutter/material.dart';

class InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final bool isLoading;

  const InfoCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Card background color adapts to theme
    final cardBackground = isDark ? Colors.grey[850] : Colors.white;

    // Shadow for depth
    final boxShadow = [
      BoxShadow(
        color: isDark
            ? Colors.black.withOpacity(0.5)
            : Colors.grey.withOpacity(0.2),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ];

    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white70 : Colors.grey[600];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: boxShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: subtitleColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isLoading
                ? SizedBox(
                    key: const ValueKey('loading'),
                    height: 34,
                    width: 34,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: color,
                    ),
                  )
                : Text(
                    value,
                    key: ValueKey(value),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: subtitleColor,
              fontSize: 12,
            ),
          ),
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
