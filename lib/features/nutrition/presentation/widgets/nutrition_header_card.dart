import 'package:flutter/material.dart';

class NutritionHeaderCard extends StatelessWidget {
  const NutritionHeaderCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 380;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 12 : 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isCompact ? 14 : 18),
        gradient: const LinearGradient(
          colors: [Color.fromARGB(255, 29, 150, 150), Color(0xFF5DB8F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF39B7C3).withOpacity(0.18),
            blurRadius: isCompact ? 14 : 18,
            offset: Offset(0, isCompact ? 6 : 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isCompact ? 8 : 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
            ),
            child: Icon(
              Icons.restaurant_menu_rounded,
              color: Colors.white,
              size: isCompact ? 22 : 28,
            ),
          ),
          SizedBox(width: isCompact ? 10 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Powered Nutrition Tracker',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isCompact ? 15 : 18,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                SizedBox(height: isCompact ? 4 : 6),
                Text(
                  'Track calories, macros, and meals with smarter daily insights.',
                  maxLines: isCompact ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isCompact ? 11 : 12,
                    height: 1.35,
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
