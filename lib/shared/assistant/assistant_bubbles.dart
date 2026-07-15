part of 'floating_smart_nudge_assistant.dart';

class _SmartNudgeBubble extends StatelessWidget {
  final String emoji;
  final String message;
  final VoidCallback onClose;

  const _SmartNudgeBubble({
    required this.emoji,
    required this.message,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return _AssistantBubbleShell(
      title: 'Smart nudge',
      onClose: onClose,
      icon: _AssistantLottieIcon(emoji: emoji, size: 30, fallbackFontSize: 18),
      child: Text(
        message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: pageSecondaryTextColor(context),
          fontSize: 13.5,
          height: 1.38,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _NutritionNudgeBubble extends StatelessWidget {
  final NutritionInsight insight;
  final VoidCallback onClose;

  const _NutritionNudgeBubble({required this.insight, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return _AssistantBubbleShell(
      title: 'Nutrition nudge',
      onClose: onClose,
      icon: const Icon(
        Icons.restaurant_menu_rounded,
        color: Colors.white,
        size: 19,
      ),
      iconColors: const [Color(0xFF1EAD83), Color(0xFF5DB8F0)],
      child: Text(
        _shortAssistantText(insight.message, maxChars: 104),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: pageSecondaryTextColor(context),
          fontSize: 13.5,
          height: 1.38,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _ExercisePreviewBubble extends StatelessWidget {
  final ExerciseGoalState goalState;
  final List<ExerciseRecommendationModel> recommendations;
  final VoidCallback onClose;
  final VoidCallback onChoose;
  final ValueChanged<ExerciseRecommendationModel> onAccept;

  const _ExercisePreviewBubble({
    required this.goalState,
    required this.recommendations,
    required this.onClose,
    required this.onChoose,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final goal = goalState.goal;
    final hasGoal = goal != null && goal.hasSelectedGoal;
    final recommendation = recommendations.isEmpty
        ? null
        : recommendations.first;

    if (hasGoal && goal.isNoneToday) {
      return _AssistantBubbleShell(
        title: 'Rest saved',
        onClose: onClose,
        icon: const Icon(
          Icons.self_improvement_rounded,
          color: Colors.white,
          size: 19,
        ),
        iconColors: const [Color(0xFF64748B), Color(0xFF8BA0BD)],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'None today',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: pagePrimaryTextColor(context),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Rest is still care. Keep it light and pick movement later if your energy changes.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: pageSecondaryTextColor(context),
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onChoose,
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const Text('Choose'),
                style: _bubbleOutlinedButtonStyle(context),
              ),
            ),
          ],
        ),
      );
    }

    if (hasGoal) {
      final isCompleted = goal.isCompleted;
      return _AssistantBubbleShell(
        title: isCompleted ? 'Exercise done' : 'Exercise saved',
        onClose: onClose,
        icon: Icon(
          isCompleted ? Icons.check_rounded : Icons.flag_rounded,
          color: Colors.white,
          size: 19,
        ),
        iconColors: const [Color(0xFF1FB489), Color(0xFF5DB8F0)],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              goal.exerciseName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: pagePrimaryTextColor(context),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isCompleted
                  ? 'Nice work. This goal is complete.'
                  : '${goal.targetLabel()} - open exercise to mark done or cancel.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: pageSecondaryTextColor(context),
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onChoose,
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('View goal'),
                style: _bubbleElevatedButtonStyle(),
              ),
            ),
          ],
        ),
      );
    }

    final title = recommendation?.exerciseName ?? 'Choose today\'s movement';
    final target = recommendation?.targetLabel ?? 'Open exercise for options';
    final reason = _shortAssistantText(
      recommendation?.reason ?? '',
      maxChars: 82,
    );
    final subtitle = reason.isEmpty ? target : '$target - $reason';

    return _AssistantBubbleShell(
      title: 'Exercise',
      onClose: onClose,
      icon: const Icon(
        Icons.directions_run_rounded,
        color: Colors.white,
        size: 19,
      ),
      iconColors: const [Color.fromARGB(255, 120, 85, 226), Color(0xFF59B7EF)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: pagePrimaryTextColor(context),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: pageSecondaryTextColor(context),
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: goalState.isSaving || recommendation == null
                      ? null
                      : () => onAccept(recommendation),
                  icon: goalState.isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Accept'),
                  style: _bubbleElevatedButtonStyle(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onChoose,
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: const Text('Choose'),
                  style: _bubbleOutlinedButtonStyle(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssistantBubbleShell extends StatelessWidget {
  final String title;
  final Widget icon;
  final Widget child;
  final VoidCallback onClose;
  final List<Color> iconColors;

  const _AssistantBubbleShell({
    required this.title,
    required this.icon,
    required this.child,
    required this.onClose,
    this.iconColors = const [
      Color.fromARGB(255, 156, 96, 234),
      Color(0xFF59B7EF),
    ],
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
                      gradient: LinearGradient(
                        colors: iconColors,
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
                    child: icon,
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
              child,
            ],
          ),
        ),
      ),
    );
  }
}

ButtonStyle _bubbleElevatedButtonStyle() {
  return ElevatedButton.styleFrom(
    backgroundColor: const Color.fromARGB(255, 134, 76, 226),
    foregroundColor: Colors.white,
    disabledBackgroundColor: const Color.fromARGB(
      255,
      134,
      76,
      226,
    ).withValues(alpha: 0.48),
    disabledForegroundColor: Colors.white.withValues(alpha: 0.72),
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );
}

ButtonStyle _bubbleOutlinedButtonStyle(BuildContext context) {
  return OutlinedButton.styleFrom(
    foregroundColor: pagePrimaryTextColor(context),
    side: BorderSide(color: pageBorderColor(context)),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );
}
