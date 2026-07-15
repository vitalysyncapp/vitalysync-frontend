import 'package:flutter/material.dart';

class TodayNutritionCard extends StatelessWidget {
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final int calorieGoal;

  const TodayNutritionCard({
    super.key,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.calorieGoal,
  });

  @override
  Widget build(BuildContext context) {
    final double goal = calorieGoal <= 0 ? 2000 : calorieGoal.toDouble();
    final double progress = (calories / goal).clamp(0, 1).toDouble();
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 380;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 9 : 11),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF075985), Color(0xFF115E59)]
              : const [Color.fromARGB(255, 8, 137, 184), Color(0xFF1FB489)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isCompact ? 14 : 16),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.green).withValues(
              alpha: isDark ? 0.26 : 0.18,
            ),
            blurRadius: isCompact ? 6 : 8,
            offset: Offset(0, isCompact ? 2 : 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's nutrition",
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
                      'Goal: ${_formatInt(goal.round())}',
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

String _formatInt(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(text[i]);
  }
  return buffer.toString();
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
