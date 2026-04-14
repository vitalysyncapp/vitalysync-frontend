import 'package:flutter/material.dart';

class NutritionHeaderCard extends StatelessWidget {
  const NutritionHeaderCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      gradient: const LinearGradient(
        colors: [
        Color(0xFF1E88E5),
        Color.fromARGB(255, 85, 170, 240),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
        color: Colors.blue.withOpacity(0.18),
        blurRadius: 18,
        offset: const Offset(0, 8),
        ),
      ],
      ),
      child: Row(
      children: [
        Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.restaurant_menu_rounded,
          color: Colors.white,
          size: 28,
        ),
        ),
        const SizedBox(width: 14),
        const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(
            'AI Powered Nutrition Tracker',
            style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Track calories, macros, and meals with smarter daily insights.',
            style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
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