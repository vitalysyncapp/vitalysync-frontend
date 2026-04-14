import 'package:flutter/material.dart';

class TodayNutritionCard extends StatelessWidget {
  const TodayNutritionCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const double calories = 1000;
    const double goal = 2000;
    final double progress = calories / goal;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
      color: const Color(0xFF08B85B),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
        color: Colors.green.withOpacity(0.18),
        blurRadius: 14,
        offset: const Offset(0, 6),
        ),
      ],
      ),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
        "Today's Nutrition",
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        ),
        const SizedBox(height: 16),
        Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
              '1,000',
              style: TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w800,
              height: 1,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Calories',
              style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              ),
            ),
            ],
          ),
          ),
          Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
            const Text(
              'Goal: 2,000',
              style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Colors.white,
              ),
              ),
            ),
            ],
          ),
          ),
        ],
        ),
        const SizedBox(height: 18),
        Container(
        height: 1,
        color: Colors.white24,
        ),
        const SizedBox(height: 16),
        const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _MacroMiniStat(value: '54g', label: 'Protein'),
          _MacroMiniStat(value: '126g', label: 'Carbs'),
          _MacroMiniStat(value: '31g', label: 'Fats'),
        ],
        ),
      ],
      ),
    );
  }
}

class _MacroMiniStat extends StatelessWidget {
  final String value;
  final String label;

  const _MacroMiniStat({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}