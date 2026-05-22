part of 'floating_smart_nudge_assistant.dart';

class _SmartNudgeDialogCard extends StatefulWidget {
  final String emoji;
  final String message;
  final List<AdaptiveNudgeRecommendation> recommendations;
  final NutritionInsight? nutritionInsight;
  final bool isLoading;
  final bool isNutritionLoading;
  final Future<void> Function(
    AdaptiveNudgeRecommendation recommendation,
    String status,
  )
  onStatusChanged;
  final Future<void> Function(NutritionInsight insight, String status)
  onNutritionStatusChanged;

  const _SmartNudgeDialogCard({
    required this.emoji,
    required this.message,
    required this.recommendations,
    required this.nutritionInsight,
    required this.isLoading,
    required this.isNutritionLoading,
    required this.onStatusChanged,
    required this.onNutritionStatusChanged,
  });

  @override
  State<_SmartNudgeDialogCard> createState() => _SmartNudgeDialogCardState();
}

class _SmartNudgeDialogCardState extends State<_SmartNudgeDialogCard> {
  String? _nudgeStatus;
  bool _isUpdatingNudgeStatus = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadFeedbackStatus());
  }

  @override
  void didUpdateWidget(covariant _SmartNudgeDialogCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldPrimary = _primaryRecommendation(oldWidget.recommendations);
    final newPrimary = _primaryRecommendation(widget.recommendations);

    if (oldPrimary?.nudgeEventId != newPrimary?.nudgeEventId ||
        oldPrimary?.nudgeType != newPrimary?.nudgeType ||
        oldPrimary?.message != newPrimary?.message) {
      unawaited(_loadFeedbackStatus());
    }
  }

  Future<void> _loadFeedbackStatus() async {
    final primary = _primaryRecommendation(widget.recommendations);
    final nudgeStatus = primary == null
        ? null
        : await AdaptiveNudgeApi.readNudgeFeedbackStatus(primary);

    if (!mounted) {
      return;
    }

    setState(() {
      _nudgeStatus = nudgeStatus;
      _isUpdatingNudgeStatus = false;
    });
  }

  Future<void> _updateNudgeStatus(
    AdaptiveNudgeRecommendation recommendation,
    String status,
  ) async {
    final previousStatus = _nudgeStatus;
    setState(() {
      _nudgeStatus = status;
      _isUpdatingNudgeStatus = true;
    });

    try {
      await widget.onStatusChanged(recommendation, status);
    } catch (error) {
      if (mounted) {
        setState(() {
          _nudgeStatus = previousStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to save feedback: ${error.toString().replaceFirst('Exception: ', '')}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingNudgeStatus = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = _primaryRecommendation(widget.recommendations);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SmartNudgeInsightCard(
          emoji: widget.emoji,
          fallbackMessage: widget.message,
          primary: primary,
          isLoading: widget.isLoading,
          feedbackStatus: _nudgeStatus,
          isUpdatingFeedback: _isUpdatingNudgeStatus,
          onLiked: primary == null
              ? null
              : () => _updateNudgeStatus(primary, 'accepted'),
          onDisliked: primary == null
              ? null
              : () => _updateNudgeStatus(primary, 'dismissed'),
        ),
        if (widget.nutritionInsight != null || widget.isNutritionLoading) ...[
          const SizedBox(height: 12),
          _NutritionNudgeDialogCard(
            insight: widget.nutritionInsight,
            isLoading: widget.isNutritionLoading,
            onNutritionStatusChanged: widget.onNutritionStatusChanged,
          ),
        ],
      ],
    );
  }

  AdaptiveNudgeRecommendation? _primaryRecommendation(
    List<AdaptiveNudgeRecommendation> recommendations,
  ) {
    if (recommendations.isEmpty) {
      return null;
    }

    return recommendations.first;
  }
}

class _NutritionNudgeDialogCard extends StatefulWidget {
  final NutritionInsight? insight;
  final bool isLoading;
  final Future<void> Function(NutritionInsight insight, String status)
  onNutritionStatusChanged;

  const _NutritionNudgeDialogCard({
    required this.insight,
    required this.isLoading,
    required this.onNutritionStatusChanged,
  });

  @override
  State<_NutritionNudgeDialogCard> createState() =>
      _NutritionNudgeDialogCardState();
}

class _NutritionNudgeDialogCardState extends State<_NutritionNudgeDialogCard> {
  String? _nutritionStatus;
  bool _isUpdatingNutritionStatus = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadFeedbackStatus());
  }

  @override
  void didUpdateWidget(covariant _NutritionNudgeDialogCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.insight?.id != widget.insight?.id) {
      unawaited(_loadFeedbackStatus());
    }
  }

  Future<void> _loadFeedbackStatus() async {
    final insight = widget.insight;
    final nutritionStatus = insight == null
        ? null
        : await NutritionInsightStore.instance.readFeedbackStatus(insight.id);

    if (!mounted) {
      return;
    }

    setState(() {
      _nutritionStatus = nutritionStatus;
      _isUpdatingNutritionStatus = false;
    });
  }

  Future<void> _updateNutritionStatus(
    NutritionInsight insight,
    String status,
  ) async {
    final previousStatus = _nutritionStatus;
    setState(() {
      _nutritionStatus = status;
      _isUpdatingNutritionStatus = true;
    });

    try {
      await widget.onNutritionStatusChanged(insight, status);
    } catch (error) {
      if (mounted) {
        setState(() {
          _nutritionStatus = previousStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to save nutrition feedback: ${error.toString().replaceFirst('Exception: ', '')}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingNutritionStatus = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final insight = widget.insight;
    if (insight == null) {
      return _NutritionInsightEmptyCard(isLoading: widget.isLoading);
    }

    return _NutritionInsightDialogCard(
      insight: insight,
      feedbackStatus: _nutritionStatus,
      isUpdatingFeedback: _isUpdatingNutritionStatus,
      onLiked: () => _updateNutritionStatus(insight, 'accepted'),
      onDisliked: () => _updateNutritionStatus(insight, 'dismissed'),
    );
  }
}

class _SmartNudgeInsightCard extends StatelessWidget {
  final String emoji;
  final String fallbackMessage;
  final AdaptiveNudgeRecommendation? primary;
  final bool isLoading;
  final String? feedbackStatus;
  final bool isUpdatingFeedback;
  final VoidCallback? onLiked;
  final VoidCallback? onDisliked;

  const _SmartNudgeInsightCard({
    required this.emoji,
    required this.fallbackMessage,
    required this.primary,
    required this.isLoading,
    required this.feedbackStatus,
    required this.isUpdatingFeedback,
    required this.onLiked,
    required this.onDisliked,
  });

  @override
  Widget build(BuildContext context) {
    final recommendation = primary;
    final nudgeTitle = recommendation?.title.trim() ?? '';
    final body = _shortAssistantText(
      recommendation?.message ?? fallbackMessage,
      maxChars: 150,
    );
    final priority = recommendation?.priority ?? 'low';
    final priorityColor = _priorityColor(priority);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 105, 93, 240),
            Color.fromARGB(255, 4, 177, 128),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: _AssistantLottieIcon(
                  emoji: emoji,
                  size: 38,
                  fallbackFontSize: 22,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.38),
                  ),
                ),
                child: Text(
                  priority.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Smart nudge',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (nudgeTitle.isNotEmpty &&
              nudgeTitle.toLowerCase() != 'smart nudge')
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _shortAssistantText(nudgeTitle, maxChars: 52),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.84),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            body,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (isLoading) ...[
            const SizedBox(height: 14),
            LinearProgressIndicator(
              minHeight: 4,
              color: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
            ),
          ],
          const SizedBox(height: 16),
          _InsightFeedbackButtons(
            status: feedbackStatus,
            isUpdating: isUpdatingFeedback,
            onLiked: onLiked,
            onDisliked: onDisliked,
            foregroundColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return const Color(0xFFFF6B6B);
      case 'high':
        return const Color(0xFFFFB454);
      case 'medium':
        return const Color(0xFFB9F6CA);
      default:
        return const Color(0xFFE0F2FE);
    }
  }
}

class _NutritionInsightDialogCard extends StatelessWidget {
  final NutritionInsight insight;
  final String? feedbackStatus;
  final bool isUpdatingFeedback;
  final VoidCallback onLiked;
  final VoidCallback onDisliked;

  const _NutritionInsightDialogCard({
    required this.insight,
    required this.feedbackStatus,
    required this.isUpdatingFeedback,
    required this.onLiked,
    required this.onDisliked,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFF8BE0BC) : const Color(0xFF178B57);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFEAF8F1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: pageBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.restaurant_menu_rounded,
                  color: accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nutrition nudge',
                      style: TextStyle(
                        color: pagePrimaryTextColor(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      insight.confidence.label.toUpperCase(),
                      style: TextStyle(
                        color: accent,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _shortAssistantText(insight.message, maxChars: 150),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: pageSecondaryTextColor(context),
              fontSize: 13.5,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          _InsightFeedbackButtons(
            status: feedbackStatus,
            isUpdating: isUpdatingFeedback,
            onLiked: onLiked,
            onDisliked: onDisliked,
            foregroundColor: accent,
          ),
        ],
      ),
    );
  }
}

class _NutritionInsightEmptyCard extends StatelessWidget {
  final bool isLoading;

  const _NutritionInsightEmptyCard({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFF8BE0BC) : const Color(0xFF178B57);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFEAF8F1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: pageBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.restaurant_menu_rounded,
                  color: accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Nutrition nudge',
                  style: TextStyle(
                    color: pagePrimaryTextColor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isLoading
                ? 'Checking today\'s nutrition pattern...'
                : 'No nutrition nudge right now. Keep meals simple and steady today.',
            style: TextStyle(
              color: pageSecondaryTextColor(context),
              fontSize: 13.5,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (isLoading) ...[
            const SizedBox(height: 14),
            LinearProgressIndicator(
              minHeight: 4,
              color: accent,
              backgroundColor: accent.withValues(alpha: 0.16),
            ),
          ],
        ],
      ),
    );
  }
}

class _InsightFeedbackButtons extends StatelessWidget {
  final String? status;
  final bool isUpdating;
  final VoidCallback? onLiked;
  final VoidCallback? onDisliked;
  final Color foregroundColor;

  const _InsightFeedbackButtons({
    required this.status,
    required this.isUpdating,
    required this.onLiked,
    required this.onDisliked,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final liked = status == 'accepted';
    final disliked = status == 'dismissed';
    final disabled = isUpdating || onLiked == null || onDisliked == null;

    return Row(
      children: [
        _InsightFeedbackIconButton(
          tooltip: liked ? 'Liked' : 'Like insight',
          icon: liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          selected: liked,
          isBusy: isUpdating && liked,
          foregroundColor: foregroundColor,
          onPressed: disabled || liked ? null : onLiked,
        ),
        const SizedBox(width: 8),
        _InsightFeedbackIconButton(
          tooltip: disliked ? 'Disliked' : 'Dislike insight',
          icon: disliked
              ? Icons.thumb_down_alt_rounded
              : Icons.thumb_down_alt_outlined,
          selected: disliked,
          isBusy: isUpdating && disliked,
          foregroundColor: foregroundColor,
          onPressed: disabled || disliked ? null : onDisliked,
        ),
      ],
    );
  }
}

class _InsightFeedbackIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final bool selected;
  final bool isBusy;
  final Color foregroundColor;
  final VoidCallback? onPressed;

  const _InsightFeedbackIconButton({
    required this.tooltip,
    required this.icon,
    required this.selected,
    required this.isBusy,
    required this.foregroundColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final selectedColor = selected
        ? foregroundColor
        : foregroundColor.withValues(alpha: 0.82);

    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 44,
        height: 40,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: selectedColor,
            disabledForegroundColor: selectedColor.withValues(alpha: 0.62),
            backgroundColor: selected
                ? foregroundColor.withValues(alpha: 0.18)
                : Colors.transparent,
            side: BorderSide(
              color: foregroundColor.withValues(alpha: selected ? 0.64 : 0.38),
            ),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: isBusy
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: selectedColor,
                  ),
                )
              : Icon(icon, size: 19),
        ),
      ),
    );
  }
}
