part of 'floating_smart_nudge_assistant.dart';

class _SmartNudgeBubble extends StatelessWidget {
  final String emoji;
  final String message;
  final VoidCallback onClose;
  final bool tailOnRight;

  const _SmartNudgeBubble({
    required this.emoji,
    required this.message,
    required this.onClose,
    this.tailOnRight = true,
  });

  @override
  Widget build(BuildContext context) {
    return _AssistantBubbleShell(
      title: 'Smart nudge',
      onClose: onClose,
      tailOnRight: tailOnRight,
      icon: _AssistantLottieIcon(emoji: emoji, size: 30, fallbackFontSize: 18),
      child: Text(
        message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: pageSecondaryTextColor(context),
          fontSize: 14.5,
          height: 1.4,
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
  final bool tailOnRight;

  const _NutritionNudgeBubble({
    required this.insight,
    required this.onClose,
    this.tailOnRight = true,
  });

  @override
  Widget build(BuildContext context) {
    return _AssistantBubbleShell(
      title: 'Nutrition nudge',
      onClose: onClose,
      tailOnRight: tailOnRight,
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
          fontSize: 14.5,
          height: 1.4,
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
  final bool tailOnRight;

  const _ExercisePreviewBubble({
    required this.goalState,
    required this.recommendations,
    required this.onClose,
    required this.onChoose,
    required this.onAccept,
    this.tailOnRight = true,
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
        tailOnRight: tailOnRight,
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
        tailOnRight: tailOnRight,
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
      tailOnRight: tailOnRight,
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
              fontSize: 17,
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
              fontSize: 14,
              height: 1.4,
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

/// Chat-style speech bubble shell with a triangular tail on the left or
/// right side that visually connects to the floating assistant icon,
/// matching the tutorial overlay bubble design.
class _AssistantBubbleShell extends StatelessWidget {
  final String title;
  final Widget icon;
  final Widget child;
  final VoidCallback onClose;
  final List<Color> iconColors;

  /// When true the tail points right (toward a button docked on the right).
  /// When false the tail points left (toward a button docked on the left).
  final bool tailOnRight;

  const _AssistantBubbleShell({
    required this.title,
    required this.icon,
    required this.child,
    required this.onClose,
    this.iconColors = const [
      Color.fromARGB(255, 156, 96, 234),
      Color(0xFF59B7EF),
    ],
    this.tailOnRight = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? const Color(0xFF132438).withValues(alpha: 0.98)
        : Colors.white.withValues(alpha: 0.98);
        
    final goldAccent = isDark ? const Color(0xFFF3C04F) : const Color(0xFFE2A829);
    final borderColor = goldAccent.withValues(alpha: 0.4);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main bubble body — painted first.
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      const Color(0xFF132438).withValues(alpha: 0.98),
                      const Color(0xFF0C1828).withValues(alpha: 0.98),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.98),
                      const Color(0xFFF1FBF7).withValues(alpha: 0.98),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.36 : 0.2),
                blurRadius: 34,
                offset: const Offset(0, 18),
              ),
              BoxShadow(
                color: goldAccent.withValues(alpha: 0.16),
                blurRadius: 28,
                spreadRadius: -8,
                offset: const Offset(0, 12),
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
                    width: 38,
                    height: 38,
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: pagePrimaryTextColor(context),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 38,
                    height: 38,
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
        // Tail (arrow) — on the left or right side of the bubble,
        // pointing horizontally toward the assistant icon.
        // Painted on top so it is not hidden by the body's shadow.
        Positioned(
          right: tailOnRight ? -6 : null,
          left: tailOnRight ? null : -6,
          top: 22,
          child: Transform.rotate(
            angle: 3.14159265 / 4,
            child: Stack(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    border: Border.all(color: borderColor),
                  ),
                ),
                // Inner fill to hide the border seam against the card edge.
                Positioned(
                  top: 1,
                  bottom: 1,
                  left: tailOnRight ? 1 : 4,
                  right: tailOnRight ? 4 : 1,
                  child: Container(color: surfaceColor),
                ),
              ],
            ),
          ),
        ),
      ],
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
