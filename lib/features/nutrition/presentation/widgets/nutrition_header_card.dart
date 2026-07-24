import 'package:flutter/material.dart';

class NutritionHeaderCard extends StatelessWidget {
  const NutritionHeaderCard({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 380;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 10 : 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isCompact ? 13 : 16),
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF4A3469), Color(0xFF1B264F)]
              : const [Color.fromARGB(255, 29, 150, 150), Color(0xFF5DB8F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withValues(alpha: 0.3)
                : const Color(0xFF39B7C3).withValues(alpha: 0.18),
            blurRadius: isCompact ? 10 : 12,
            offset: Offset(0, isCompact ? 4 : 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI-powered nutrition tracker',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isCompact ? 13.5 : 16,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                SizedBox(height: isCompact ? 3 : 4),
                Text(
                  'Track calories, macros, and meals with smarter daily insights.',
                  maxLines: isCompact ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isCompact ? 10.5 : 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: isCompact ? 8 : 10),
          Container(
            padding: EdgeInsets.all(isCompact ? 7 : 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(isCompact ? 11 : 13),
            ),
            child: Text(
              '🍎',
              semanticsLabel: 'Apple',
              style: TextStyle(fontSize: isCompact ? 20 : 24, height: 1),
            ),
          ),
        ],
      ),
    );
  }
}
