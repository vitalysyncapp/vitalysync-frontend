import 'package:flutter/material.dart';

import '../../../../shared/theme/app_page_style.dart';

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
    final goal = calorieGoal <= 0 ? 2000.0 : calorieGoal.toDouble();
    final progress = (calories / goal).clamp(0.0, 1.0);
    final remaining = (goal - calories).clamp(0.0, double.infinity);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 380;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final cornerRadius = isCompact ? 20.0 : 24.0;

    return Semantics(
      container: true,
      label:
          "Today's nutrition. ${calories.round()} calories eaten of ${goal.round()}. ${remaining.round()} calories left.",
      child: Container(
        key: const ValueKey('today-nutrition-summary'),
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          isCompact ? 15 : 18,
          isCompact ? 16 : 19,
          isCompact ? 15 : 18,
          isCompact ? 14 : 17,
        ),
        decoration: BoxDecoration(
          color: pageSurfaceColor(context),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(cornerRadius),
            topRight: Radius.circular(isCompact ? 50 : 62),
            bottomLeft: Radius.circular(cornerRadius),
            bottomRight: Radius.circular(cornerRadius),
          ),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.13)
                : const Color(0xFFCDE3DD),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.075),
              blurRadius: isCompact ? 16 : 20,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 5,
                            height: isCompact ? 38 : 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2CB69A),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                          SizedBox(width: isCompact ? 9 : 11),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Eaten today',
                                style: TextStyle(
                                  color: pageSecondaryTextColor(context),
                                  fontSize: isCompact ? 11.5 : 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                '${_formatInt(calories.round())} kcal',
                                key: const ValueKey('calories-eaten'),
                                style: TextStyle(
                                  color: pagePrimaryTextColor(context),
                                  fontSize: isCompact ? 17 : 19,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: isCompact ? 12 : 15),
                      Text(
                        'Daily goal',
                        style: TextStyle(
                          color: pageSecondaryTextColor(context),
                          fontSize: isCompact ? 10.5 : 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatInt(goal.round())} kcal',
                        style: TextStyle(
                          color: pagePrimaryTextColor(context),
                          fontSize: isCompact ? 13 : 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: isCompact ? 8 : 12),
                _CalorieProgress(
                  progress: progress,
                  remainingCalories: remaining.round(),
                  isCompact: isCompact,
                  reduceMotion: reduceMotion,
                ),
              ],
            ),
            SizedBox(height: isCompact ? 14 : 17),
            Divider(height: 1, color: pageBorderColor(context)),
            SizedBox(height: isCompact ? 12 : 15),
            Row(
              children: [
                Expanded(
                  child: _MacroColumn(
                    label: 'Carbs',
                    value: '${carbsG.round()}g',
                    color: const Color(0xFF4F72E8),
                    isCompact: isCompact,
                  ),
                ),
                SizedBox(width: isCompact ? 12 : 16),
                Expanded(
                  child: _MacroColumn(
                    label: 'Protein',
                    value: '${proteinG.round()}g',
                    color: const Color(0xFFE85882),
                    isCompact: isCompact,
                  ),
                ),
                SizedBox(width: isCompact ? 12 : 16),
                Expanded(
                  child: _MacroColumn(
                    label: 'Fat',
                    value: '${fatG.round()}g',
                    color: const Color(0xFFE0B32D),
                    isCompact: isCompact,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CalorieProgress extends StatelessWidget {
  final double progress;
  final int remainingCalories;
  final bool isCompact;
  final bool reduceMotion;

  const _CalorieProgress({
    required this.progress,
    required this.remainingCalories,
    required this.isCompact,
    required this.reduceMotion,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = isCompact ? 102.0 : 116.0;

    return Semantics(
      label: '$remainingCalories calories left',
      child: TweenAnimationBuilder<double>(
        key: const ValueKey('calorie-progress-animation'),
        tween: Tween(begin: 0, end: progress),
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        builder: (context, animatedProgress, _) {
          return SizedBox.square(
            dimension: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.square(
                  dimension: size,
                  child: CircularProgressIndicator(
                    value: animatedProgress,
                    strokeWidth: isCompact ? 9 : 10,
                    strokeCap: StrokeCap.round,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.09)
                        : const Color(0xFFE7EFED),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF3F51C6),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _formatInt(remainingCalories),
                          key: const ValueKey('calories-remaining'),
                          style: TextStyle(
                            color: pagePrimaryTextColor(context),
                            fontSize: isCompact ? 20 : 23,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'kcal left',
                        style: TextStyle(
                          color: pageSecondaryTextColor(context),
                          fontSize: isCompact ? 9.5 : 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MacroColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isCompact;

  const _MacroColumn({
    required this.label,
    required this.value,
    required this.color,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: pagePrimaryTextColor(context),
            fontSize: isCompact ? 11.5 : 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: isCompact ? 5 : 6),
        Container(
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        SizedBox(height: isCompact ? 5 : 6),
        Text(
          value,
          style: TextStyle(
            color: pageSecondaryTextColor(context),
            fontSize: isCompact ? 10.5 : 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
