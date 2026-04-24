import 'package:flutter/material.dart';

class TodayNutritionCard extends StatelessWidget {
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;

  const TodayNutritionCard({
    Key? key,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const double goal = 2000;
    final double progress = (calories / goal).clamp(0, 1).toDouble();
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 380;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 14 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFF08B85B),
        borderRadius: BorderRadius.circular(isCompact ? 18 : 24),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.18),
            blurRadius: isCompact ? 10 : 14,
            offset: Offset(0, isCompact ? 4 : 6),
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
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: isCompact ? 12 : 16),
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
                        fontSize: isCompact ? 30 : 38,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    SizedBox(height: isCompact ? 4 : 6),
                    Text(
                      'Calories',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isCompact ? 14 : 16,
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
                        fontSize: isCompact ? 14 : 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: isCompact ? 10 : 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: isCompact ? 8 : 10,
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
          SizedBox(height: isCompact ? 14 : 18),
          Container(
            height: 1,
            color: Colors.white24,
          ),
          SizedBox(height: isCompact ? 12 : 16),
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
            fontSize: isCompact ? 20 : 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: isCompact ? 1 : 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: isCompact ? 13 : 15,
          ),
        ),
      ],
    );
  }
}
