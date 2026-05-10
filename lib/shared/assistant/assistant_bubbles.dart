part of 'floating_smart_nudge_assistant.dart';

class _SmartNudgeBubble extends StatelessWidget {
  final String emoji;
  final String title;
  final String message;
  final NutritionInsight? nutritionInsight;
  final VoidCallback onClose;

  const _SmartNudgeBubble({
    required this.emoji,
    required this.title,
    required this.message,
    required this.nutritionInsight,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? const Color(0xFF122033).withValues(alpha: 0.92)
        : Colors.white.withValues(alpha: 0.92);
    final borderColor = isDark
        ? const Color(0xFFE2C269).withValues(alpha: 0.34)
        : const Color(0xFFE4C56A).withValues(alpha: 0.72);

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 14),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.32 : 0.12),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: const Color(
                  0xFF36B7C6,
                ).withValues(alpha: isDark ? 0.12 : 0.18),
                blurRadius: 26,
                spreadRadius: -12,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromARGB(255, 156, 96, 234),
                          Color(0xFF59B7EF),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3BB8C7).withValues(alpha: 0.2),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: _AssistantLottieIcon(
                      emoji: emoji,
                      size: 30,
                      fallbackFontSize: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: pagePrimaryTextColor(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 34,
                    height: 34,
                    child: IconButton(
                      tooltip: 'Dismiss',
                      onPressed: onClose,
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: pageSecondaryTextColor(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: pageSecondaryTextColor(context),
                  fontSize: 13.5,
                  height: 1.42,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
              if (nutritionInsight != null) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : const Color(0xFFEAF8F1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFCDEFE0),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.restaurant_menu_rounded,
                        color: isDark
                            ? const Color(0xFF8BE0BC)
                            : const Color(0xFF178B57),
                        size: 17,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          nutritionInsight!.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: pageSecondaryTextColor(context),
                            fontSize: 12.5,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ExercisePreviewBubble extends StatelessWidget {
  final ExerciseGoalState goalState;
  final List<ExerciseRecommendationModel> recommendations;
  final VoidCallback onClose;
  final VoidCallback onOpen;

  const _ExercisePreviewBubble({
    required this.goalState,
    required this.recommendations,
    required this.onClose,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final goal = goalState.goal;
    final hasGoal = goal != null && goal.hasSelectedGoal;
    ExerciseRecommendationModel? recommendation;
    for (final item in recommendations) {
      if (!item.isNoneToday) {
        recommendation = item;
        break;
      }
    }
    final title = hasGoal ? 'Today\'s Exercise Goal' : 'Recommended Exercise';
    final name = hasGoal
        ? goal.exerciseName
        : recommendation?.exerciseName ?? 'Choose today\'s movement';
    final subtitle = hasGoal
        ? goal.targetLabel()
        : recommendation?.targetLabel ?? 'Open assistant to choose';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 14),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF122033).withValues(alpha: 0.94)
                : Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark
                  ? const Color(0xFFE2C269).withValues(alpha: 0.34)
                  : const Color(0xFFE4C56A).withValues(alpha: 0.72),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.32 : 0.12),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Color.fromARGB(255, 120, 85, 226),
                          Color(0xFF59B7EF),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.directions_run_rounded,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: pagePrimaryTextColor(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 34,
                    height: 34,
                    child: IconButton(
                      tooltip: 'Dismiss',
                      onPressed: onClose,
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: pageSecondaryTextColor(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: pagePrimaryTextColor(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: pageSecondaryTextColor(context),
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onOpen,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 134, 76, 226),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(hasGoal ? 'View Goal' : 'Choose Exercise'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
