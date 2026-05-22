import 'package:flutter/material.dart';

class TodayNutritionCard extends StatelessWidget {
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;

  const TodayNutritionCard({
    super.key,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  @override
  Widget build(BuildContext context) {
    const double goal = 2000;
    final double progress = (calories / goal).clamp(0, 1).toDouble();
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 380;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 9 : 11),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 8, 137, 184),
        borderRadius: BorderRadius.circular(isCompact ? 14 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.18),
            blurRadius: isCompact ? 6 : 8,
            offset: Offset(0, isCompact ? 2 : 3),
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
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: isCompact ? 6 : 7),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      calories.round().toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isCompact ? 22 : 26,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    SizedBox(height: isCompact ? 2 : 3),
                    Text(
                      'Calories',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isCompact ? 11 : 12,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Goal: 2,000',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isCompact ? 11 : 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: isCompact ? 5 : 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: isCompact ? 5 : 6,
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
          SizedBox(height: isCompact ? 7 : 8),
          Container(height: 1, color: Colors.white24),
          SizedBox(height: isCompact ? 6 : 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MacroMiniStat(
                value: '${proteinG.round()}g',
                label: 'Protein',
                isCompact: isCompact,
              ),
              _MacroMiniStat(
                value: '${carbsG.round()}g',
                label: 'Carbs',
                isCompact: isCompact,
              ),
              _MacroMiniStat(
                value: '${fatG.round()}g',
                label: 'Fats',
                isCompact: isCompact,
              ),
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
  final bool isCompact;

  const _MacroMiniStat({
    required this.value,
    required this.label,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: isCompact ? 14.5 : 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: isCompact ? 10.5 : 11.5,
          ),
        ),
      ],
    );
  }
}
