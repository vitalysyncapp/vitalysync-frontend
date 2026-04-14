import 'package:flutter/material.dart';

import '../../../../app/main_navigation.dart';

class QuickActionCard extends StatelessWidget {
  final String icon;
  final String title;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color iconColor;
  final Color titleColor;

  const QuickActionCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.onTap,
    required this.backgroundColor,
    required this.iconColor,
    required this.titleColor,
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 118,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                icon,
                style: TextStyle(color: iconColor, fontSize: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: titleColor ?? (isDark ? Colors.white : const Color(0xFF0F2E6E)),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE8E8E8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0D2240),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              QuickActionCard(
                icon: '🫀',
                title: 'Daily Check-in',
                backgroundColor: const Color.fromARGB(255, 216, 231, 255),
                iconColor: const Color(0xFF2F66F3),
                titleColor: const Color(0xFF163D8C),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const MainNavigation(initialIndex: 1)),
                  );
                },
              ),
              QuickActionCard(
                icon: '🍽️',
                title: 'Log Meal',
                backgroundColor: const Color.fromARGB(255, 201, 251, 214),
                iconColor: const Color(0xFFB8A8D9),
                titleColor: const Color(0xFF145A1F),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const MainNavigation(initialIndex: 2)),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
