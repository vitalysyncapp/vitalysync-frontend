part of 'floating_smart_nudge_assistant.dart';

class _SmartNudgeDialogCard extends StatefulWidget {
  final String emoji;
  final String message;
  final List<AdaptiveNudgeRecommendation> recommendations;
  final NutritionInsight? nutritionInsight;
  final bool isLoading;
  final Future<void> Function(
    AdaptiveNudgeRecommendation recommendation,
    String status,
  )
  onStatusChanged;
  final Future<void> Function(AdaptiveNudgeRecommendation recommendation)
  onRemind;

  const _SmartNudgeDialogCard({
    required this.emoji,
    required this.message,
    required this.recommendations,
    required this.nutritionInsight,
    required this.isLoading,
    required this.onStatusChanged,
    required this.onRemind,
  });

  @override
  State<_SmartNudgeDialogCard> createState() => _SmartNudgeDialogCardState();
}

class _SmartNudgeDialogCardState extends State<_SmartNudgeDialogCard> {
  String? _localStatus;
  bool _isUpdatingStatus = false;
  bool _isNutritionExpanded = false;

  @override
  void didUpdateWidget(covariant _SmartNudgeDialogCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldPrimary = oldWidget.recommendations.isEmpty
        ? null
        : oldWidget.recommendations.first;
    final newPrimary = widget.recommendations.isEmpty
        ? null
        : widget.recommendations.first;

    if (oldPrimary?.nudgeEventId != newPrimary?.nudgeEventId ||
        oldPrimary?.nudgeType != newPrimary?.nudgeType) {
      _localStatus = null;
      _isUpdatingStatus = false;
    }
  }

  Future<void> _updateStatus(
    AdaptiveNudgeRecommendation recommendation,
    String status,
  ) async {
    setState(() {
      _localStatus = status;
      _isUpdatingStatus = true;
    });

    try {
      await widget.onStatusChanged(recommendation, status);
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.recommendations.isEmpty
        ? null
        : widget.recommendations.first;
    final title = primary?.title ?? 'Smart Nudge';
    final body = primary?.message ?? widget.message;
    final priority = primary?.priority ?? 'low';
    final priorityColor = _priorityColor(priority);
    final isDismissed = _localStatus == 'dismissed';
    final isAccepted = _localStatus == 'completed';

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
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(17),
            ),
            child: _AssistantLottieIcon(
              emoji: widget.emoji,
              size: 38,
              fallbackFontSize: 22,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
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
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (widget.nutritionInsight != null) ...[
            const SizedBox(height: 12),
            _NutritionSecondaryInsightCard(
              insight: widget.nutritionInsight!,
              isExpanded: _isNutritionExpanded,
              onTap: () {
                setState(() {
                  _isNutritionExpanded = !_isNutritionExpanded;
                });
              },
            ),
          ],
          if (widget.isLoading) ...[
            const SizedBox(height: 14),
            LinearProgressIndicator(
              minHeight: 4,
              color: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
            ),
          ],
          if (primary != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.insights_rounded,
                  size: 17,
                  color: Colors.white.withValues(alpha: 0.86),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    primary.triggerReason.isEmpty
                        ? 'Based on your recent pattern'
                        : primary.triggerReason,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.84),
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if ((primary.metadata['ai_why_this_matters'] ?? '')
                .toString()
                .isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                primary.metadata['ai_why_this_matters'].toString(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12.5,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (primary.metadata['ai_action_steps'] is List &&
                (primary.metadata['ai_action_steps'] as List).isNotEmpty) ...[
              const SizedBox(height: 10),
              ...(primary.metadata['ai_action_steps'] as List)
                  .map((item) => item.toString())
                  .where((item) => item.trim().isNotEmpty)
                  .take(2)
                  .map(
                    (step) => Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 15,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              step,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.86),
                                fontSize: 12.5,
                                height: 1.3,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
            if (widget.recommendations.length > 1) ...[
              const SizedBox(height: 12),
              ...widget.recommendations
                  .skip(1)
                  .take(2)
                  .map(
                    (recommendation) => Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.78),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              recommendation.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.82),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
            const SizedBox(height: 16),
            if (_localStatus != null) ...[
              _NudgeStatusHint(
                status: _localStatus!,
                isUpdating: _isUpdatingStatus,
              ),
              const SizedBox(height: 10),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _isUpdatingStatus || isDismissed || isAccepted
                      ? null
                      : () => _updateStatus(primary, 'dismissed'),
                  icon: Icon(
                    isDismissed
                        ? Icons.remove_circle_rounded
                        : Icons.close_rounded,
                    size: 17,
                  ),
                  label: Text(isDismissed ? 'Dismissed' : 'Dismiss'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDismissed
                        ? Colors.white.withValues(alpha: 0.72)
                        : Colors.white,
                    disabledForegroundColor: Colors.white.withValues(
                      alpha: 0.72,
                    ),
                    side: BorderSide(
                      color: Colors.white.withValues(
                        alpha: isDismissed ? 0.28 : 0.5,
                      ),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _isUpdatingStatus || isDismissed || isAccepted
                      ? null
                      : () => widget.onRemind(primary),
                  icon: const Icon(
                    Icons.notifications_active_rounded,
                    size: 17,
                  ),
                  label: const Text('Remind'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isUpdatingStatus || isDismissed || isAccepted
                      ? null
                      : () => _updateStatus(primary, 'completed'),
                  icon: Icon(
                    isAccepted
                        ? Icons.check_circle_rounded
                        : Icons.check_rounded,
                    size: 18,
                  ),
                  label: Text(isAccepted ? 'Accepted' : 'Accept'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAccepted
                        ? const Color(0xFFBBF7D0)
                        : Colors.white,
                    foregroundColor: const Color(0xFF187A66),
                    disabledBackgroundColor: isAccepted
                        ? const Color(0xFFBBF7D0)
                        : Colors.white.withValues(alpha: 0.34),
                    disabledForegroundColor: const Color(0xFF187A66),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
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

class _NutritionSecondaryInsightCard extends StatelessWidget {
  final NutritionInsight insight;
  final bool isExpanded;
  final VoidCallback onTap;

  const _NutritionSecondaryInsightCard({
    required this.insight,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Nutrition insight',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: Colors.white.withValues(alpha: 0.86),
                  size: 21,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              insight.message,
              maxLines: isExpanded ? 4 : 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
