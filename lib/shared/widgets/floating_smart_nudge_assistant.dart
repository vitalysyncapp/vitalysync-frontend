import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../features/adaptive/data/adaptive_nudge_api.dart';
import '../../features/activity/data/activity_service.dart';
import '../../features/exercise/data/exercise_goal_service.dart';
import '../../features/exercise/data/exercise_recommendation_model.dart';
import '../../features/exercise/data/exercise_recommendation_service.dart';
import '../../features/exercise/presentation/widgets/assistant_exercise_card.dart';
import '../../features/exercise/presentation/widgets/selected_exercise_goal_card.dart';
import '../../features/log/data/log_api.dart';
import '../notifications/local_notification_service.dart';
import '../theme/app_page_style.dart';

const _assistantAnimationPath = 'assets/animations/Assistant.json';

class FloatingSmartNudgeAssistant extends StatefulWidget {
  final String message;
  final String emoji;
  final double buttonSize;
  final Duration autoHideDuration;

  const FloatingSmartNudgeAssistant({
    super.key,
    required this.message,
    this.emoji = '\u{1F499}',
    this.buttonSize = 54,
    this.autoHideDuration = const Duration(seconds: 10),
  });

  @override
  State<FloatingSmartNudgeAssistant> createState() =>
      _FloatingSmartNudgeAssistantState();
}

class _FloatingSmartNudgeAssistantState
    extends State<FloatingSmartNudgeAssistant> {
  static const _moveAnimationDuration = Duration(milliseconds: 220);

  bool _isBubbleVisible = false;
  bool _isExercisePreviewVisible = false;
  bool _isDragging = false;
  bool _hasCustomPosition = false;
  Offset _buttonOffset = Offset.zero;
  Timer? _bubbleSwitchTimer;
  List<ExerciseRecommendationModel> _recommendations = const [];
  List<AdaptiveNudgeRecommendation> _adaptiveNudges = const [];
  int _lastCompletionEventId = 0;
  bool? _hasPendingWeeklyPulse;

  final ExerciseRecommendationService _recommendationService =
      const ExerciseRecommendationService();

  @override
  void initState() {
    super.initState();
    ExerciseGoalService.instance.start();
    ExerciseGoalService.instance.notifier.addListener(_handleGoalEvent);
    _loadRecommendations();
    _loadAdaptiveNudges();
    _loadWeeklyPulseIndicator();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showBubble();
    });
  }

  @override
  void dispose() {
    _bubbleSwitchTimer?.cancel();
    ExerciseGoalService.instance.notifier.removeListener(_handleGoalEvent);
    super.dispose();
  }

  Future<void> _loadRecommendations() async {
    final recommendations = await _recommendationService.loadRecommendations();
    if (!mounted) return;

    setState(() {
      _recommendations = recommendations;
    });
  }

  Future<List<AdaptiveNudgeRecommendation>> _loadAdaptiveNudges() async {
    try {
      final response = await AdaptiveNudgeApi.fetchRecommendations(limit: 3);
      if (!mounted) {
        return response.recommendations;
      }

      setState(() {
        _adaptiveNudges = response.recommendations;
      });

      return response.recommendations;
    } catch (_) {
      if (!mounted) {
        return _adaptiveNudges;
      }

      setState(() {
        _adaptiveNudges = const [];
      });
      return const [];
    }
  }

  Future<void> _loadWeeklyPulseIndicator() async {
    try {
      final data = await LogApi.fetchWeeklyPulseStatus();
      if (!mounted) return;

      setState(() {
        _hasPendingWeeklyPulse = data['has_response'] != true;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _hasPendingWeeklyPulse = false;
      });
    }
  }

  void _handleGoalEvent() {
    final state = ExerciseGoalService.instance.notifier.value;
    if (state.completionEventId == _lastCompletionEventId ||
        state.completionMessage == null) {
      return;
    }

    _lastCompletionEventId = state.completionEventId;
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(state.completionMessage!)));
  }

  void _showBubble() {
    _bubbleSwitchTimer?.cancel();

    setState(() {
      _isBubbleVisible = true;
      _isExercisePreviewVisible = false;
    });

    _bubbleSwitchTimer = Timer(widget.autoHideDuration, _showExercisePreview);
  }

  void _hideBubble() {
    _bubbleSwitchTimer?.cancel();

    if (!mounted || !_isBubbleVisible) return;

    setState(() {
      _isBubbleVisible = false;
      _isExercisePreviewVisible = false;
    });
  }

  void _showExercisePreview() {
    if (!mounted || !_isBubbleVisible) return;

    setState(() {
      _isExercisePreviewVisible = true;
    });

    _bubbleSwitchTimer?.cancel();
    _bubbleSwitchTimer = Timer(widget.autoHideDuration, _hideBubble);
  }

  Future<void> _openAssistantDialog() async {
    _bubbleSwitchTimer?.cancel();
    setState(() {
      _isBubbleVisible = false;
      _isExercisePreviewVisible = false;
    });

    await _loadRecommendations();
    await _loadAdaptiveNudges();
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _AssistantExerciseDialog(
          message: widget.message,
          emoji: widget.emoji,
          recommendations: _recommendations,
          adaptiveNudges: _adaptiveNudges,
          onRefreshRecommendations: _loadRecommendations,
          onRefreshAdaptiveNudges: _loadAdaptiveNudges,
        );
      },
    );

    await _loadWeeklyPulseIndicator();
  }

  void _handleAssistantTap() {
    if (_isBubbleVisible) {
      _hideBubble();
      return;
    }

    _openAssistantDialog();
  }

  EdgeInsets _dragPadding(BuildContext context, Size bounds) {
    final safePadding = MediaQuery.paddingOf(context);
    final isCompact = bounds.width < 390;

    return EdgeInsets.only(
      left: safePadding.left + (isCompact ? 12 : 18),
      top: safePadding.top + 12,
      right: safePadding.right + (isCompact ? 12 : 18),
      bottom: safePadding.bottom + (isCompact ? 104 : 112),
    );
  }

  Offset _defaultButtonOffset(Size bounds, EdgeInsets padding) {
    return Offset(
      max(padding.left, bounds.width - padding.right - widget.buttonSize),
      max(padding.top, bounds.height - padding.bottom - widget.buttonSize),
    );
  }

  Offset _clampButtonOffset(Offset offset, Size bounds, EdgeInsets padding) {
    final maxX = max(
      padding.left,
      bounds.width - padding.right - widget.buttonSize,
    );
    final maxY = max(
      padding.top,
      bounds.height - padding.bottom - widget.buttonSize,
    );

    return Offset(
      offset.dx.clamp(padding.left, maxX).toDouble(),
      offset.dy.clamp(padding.top, maxY).toDouble(),
    );
  }

  Offset _effectiveButtonOffset(Size bounds, EdgeInsets padding) {
    if (!_hasCustomPosition) {
      return _defaultButtonOffset(bounds, padding);
    }

    return _clampButtonOffset(_buttonOffset, bounds, padding);
  }

  double _bubbleLeft(
    Offset buttonOffset,
    double bubbleWidth,
    Size bounds,
    EdgeInsets padding,
  ) {
    final minLeft = padding.left;
    final maxLeft = max(minLeft, bounds.width - padding.right - bubbleWidth);
    final preferredLeft = buttonOffset.dx + widget.buttonSize - bubbleWidth;

    return preferredLeft.clamp(minLeft, maxLeft).toDouble();
  }

  bool _shouldShowBubbleBelow(Offset buttonOffset, EdgeInsets padding) {
    return buttonOffset.dy < padding.top + 172;
  }

  void _handlePanStart(Size bounds, EdgeInsets padding) {
    _bubbleSwitchTimer?.cancel();

    setState(() {
      _isDragging = true;
      _hasCustomPosition = true;
      _buttonOffset = _effectiveButtonOffset(bounds, padding);
    });
  }

  void _handlePanUpdate(
    DragUpdateDetails details,
    Size bounds,
    EdgeInsets padding,
  ) {
    setState(() {
      _buttonOffset = _clampButtonOffset(
        _buttonOffset + details.delta,
        bounds,
        padding,
      );
    });
  }

  void _handlePanEnd(Size bounds, EdgeInsets padding) {
    setState(() {
      _isDragging = false;
      _buttonOffset = _clampButtonOffset(_buttonOffset, bounds, padding);
    });

    if (_isBubbleVisible) {
      _bubbleSwitchTimer?.cancel();
      _bubbleSwitchTimer = Timer(
        widget.autoHideDuration,
        _isExercisePreviewVisible ? _hideBubble : _showExercisePreview,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fallbackSize = MediaQuery.sizeOf(context);
        final bounds = Size(
          constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : fallbackSize.width,
          constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : fallbackSize.height,
        );

        if (bounds.width <= 0 || bounds.height <= 0) {
          return const SizedBox.shrink();
        }

        final padding = _dragPadding(context, bounds);
        final buttonOffset = _effectiveButtonOffset(bounds, padding);
        final maxBubbleWidth = min(
          max(bounds.width - padding.horizontal, widget.buttonSize),
          326.0,
        );
        final bubbleLeft = _bubbleLeft(
          buttonOffset,
          maxBubbleWidth,
          bounds,
          padding,
        );
        final showBubbleBelow = _shouldShowBubbleBelow(buttonOffset, padding);
        final bubbleSlideOffset = showBubbleBelow
            ? const Offset(0, -0.08)
            : const Offset(0, 0.08);
        final moveDuration = _isDragging
            ? Duration.zero
            : _moveAnimationDuration;

        return SizedBox.expand(
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: moveDuration,
                curve: Curves.easeOutCubic,
                left: bubbleLeft,
                top: showBubbleBelow
                    ? buttonOffset.dy + widget.buttonSize + 10
                    : null,
                bottom: showBubbleBelow
                    ? null
                    : bounds.height - buttonOffset.dy + 10,
                width: maxBubbleWidth,
                child: IgnorePointer(
                  ignoring: !_isBubbleVisible,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    offset: _isBubbleVisible ? Offset.zero : bubbleSlideOffset,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      opacity: _isBubbleVisible ? 1 : 0,
                      child: ValueListenableBuilder<ExerciseGoalState>(
                        valueListenable: ExerciseGoalService.instance.notifier,
                        builder: (context, goalState, _) {
                          if (_isExercisePreviewVisible) {
                            return _ExercisePreviewBubble(
                              goalState: goalState,
                              recommendations: _recommendations,
                              onClose: _hideBubble,
                              onOpen: _openAssistantDialog,
                            );
                          }

                          return _SmartNudgeBubble(
                            emoji: widget.emoji,
                            message: _adaptiveNudges.isEmpty
                                ? widget.message
                                : _adaptiveNudges.first.message,
                            onClose: _hideBubble,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: moveDuration,
                curve: Curves.easeOutCubic,
                left: buttonOffset.dx,
                top: buttonOffset.dy,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (_) => _handlePanStart(bounds, padding),
                  onPanUpdate: (details) =>
                      _handlePanUpdate(details, bounds, padding),
                  onPanEnd: (_) => _handlePanEnd(bounds, padding),
                  onPanCancel: () => _handlePanEnd(bounds, padding),
                  child: _FloatingHeartButton(
                    emoji: widget.emoji,
                    size: widget.buttonSize,
                    isActive: _isBubbleVisible,
                    isDragging: _isDragging,
                    hasPendingWeeklyPulse: _hasPendingWeeklyPulse == true,
                    onTap: _handleAssistantTap,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

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
                        colors: [Color(0xFF1FB489), Color(0xFF59B7EF)],
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
                      'Smart Nudge',
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
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: pageSecondaryTextColor(context),
                  fontSize: 13.5,
                  height: 1.42,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
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
                        colors: [Color(0xFF1FB489), Color(0xFF59B7EF)],
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
                    backgroundColor: const Color(0xFF1FB489),
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

class _AssistantExerciseDialog extends StatefulWidget {
  final String message;
  final String emoji;
  final List<ExerciseRecommendationModel> recommendations;
  final List<AdaptiveNudgeRecommendation> adaptiveNudges;
  final Future<void> Function() onRefreshRecommendations;
  final Future<List<AdaptiveNudgeRecommendation>> Function()
  onRefreshAdaptiveNudges;

  const _AssistantExerciseDialog({
    required this.message,
    required this.emoji,
    required this.recommendations,
    required this.adaptiveNudges,
    required this.onRefreshRecommendations,
    required this.onRefreshAdaptiveNudges,
  });

  @override
  State<_AssistantExerciseDialog> createState() =>
      _AssistantExerciseDialogState();
}

class _AssistantExerciseDialogState extends State<_AssistantExerciseDialog> {
  final PageController _pageController = PageController();
  final ExerciseRecommendationService _recommendationService =
      const ExerciseRecommendationService();

  late List<ExerciseRecommendationModel> _recommendations;
  late List<AdaptiveNudgeRecommendation> _adaptiveNudges;
  int _pageIndex = 0;
  bool _isLoadingRecommendations = false;
  bool _isLoadingAdaptiveNudges = false;
  bool _isLoadingWeeklyPulse = true;
  bool _isSavingWeeklyPulse = false;
  bool _hasWeeklyPulseResponse = false;
  bool _isEditingWeeklyPulse = false;
  int? _productivityFocusLevel;
  int? _recoveryRestLevel;
  int? _detachmentLevel;
  int? _accomplishmentLevel;

  @override
  void initState() {
    super.initState();
    _recommendations = widget.recommendations;
    _adaptiveNudges = widget.adaptiveNudges;
    if (_recommendations.isEmpty) {
      _loadRecommendations();
    }
    if (_adaptiveNudges.isEmpty) {
      _loadAdaptiveNudges();
    }
    _loadWeeklyPulseStatus();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoadingRecommendations = true;
    });

    await widget.onRefreshRecommendations();
    final recommendations = await _recommendationService.loadRecommendations();
    if (!mounted) return;

    setState(() {
      _recommendations = recommendations;
      _isLoadingRecommendations = false;
    });
  }

  Future<void> _loadAdaptiveNudges() async {
    setState(() {
      _isLoadingAdaptiveNudges = true;
    });

    final recommendations = await widget.onRefreshAdaptiveNudges();
    if (!mounted) return;

    setState(() {
      _adaptiveNudges = recommendations;
      _isLoadingAdaptiveNudges = false;
    });
  }

  Future<void> _handleNudgeStatus(
    AdaptiveNudgeRecommendation recommendation,
    String status,
  ) async {
    final eventId = recommendation.nudgeEventId;
    if (eventId != null) {
      await AdaptiveNudgeApi.updateNudgeStatus(
        eventId: eventId,
        status: status,
      );
    }

    if (!mounted) return;

    final label = status == 'dismissed'
        ? 'Nudge dismissed.'
        : status == 'completed'
        ? 'Nudge marked complete.'
        : 'Nudge saved.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(label)));
  }

  Future<void> _remindForNudge(
    AdaptiveNudgeRecommendation recommendation,
  ) async {
    final eventId = recommendation.nudgeEventId;
    if (eventId != null) {
      await AdaptiveNudgeApi.updateNudgeStatus(
        eventId: eventId,
        status: 'snoozed',
      );
    }

    await LocalNotificationService.instance.scheduleAdaptiveReminder(
      title: recommendation.title,
      body: recommendation.message,
      payload: 'adaptive_nudge:${recommendation.nudgeType}',
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reminder scheduled for later.')),
    );
  }

  Future<void> _loadWeeklyPulseStatus() async {
    setState(() {
      _isLoadingWeeklyPulse = true;
    });

    try {
      final data = await LogApi.fetchWeeklyPulseStatus();
      final response = data['response'] as Map<String, dynamic>?;
      if (!mounted) return;

      setState(() {
        _hasWeeklyPulseResponse = data['has_response'] == true;
        _isEditingWeeklyPulse = data['has_response'] != true;
        _productivityFocusLevel = LogApi.parseLikert(
          response?['productivity_focus_level'],
        );
        _recoveryRestLevel = LogApi.parseLikert(
          response?['recovery_rest_level'],
        );
        _detachmentLevel = LogApi.parseLikert(response?['detachment_level']);
        _accomplishmentLevel = LogApi.parseLikert(
          response?['accomplishment_level'],
        );
        _isLoadingWeeklyPulse = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoadingWeeklyPulse = false;
      });
    }
  }

  Future<void> _saveWeeklyPulse() async {
    final productivityFocusLevel = _productivityFocusLevel;
    final recoveryRestLevel = _recoveryRestLevel;
    final detachmentLevel = _detachmentLevel;
    final accomplishmentLevel = _accomplishmentLevel;

    if (productivityFocusLevel == null ||
        recoveryRestLevel == null ||
        detachmentLevel == null ||
        accomplishmentLevel == null) {
      return;
    }

    setState(() {
      _isSavingWeeklyPulse = true;
    });

    try {
      await LogApi.saveWeeklyPulse(
        productivityFocusLevel: productivityFocusLevel,
        recoveryRestLevel: recoveryRestLevel,
        detachmentLevel: detachmentLevel,
        accomplishmentLevel: accomplishmentLevel,
      );

      if (!mounted) return;

      setState(() {
        _hasWeeklyPulseResponse = true;
        _isEditingWeeklyPulse = false;
        _isSavingWeeklyPulse = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Weekly pulse saved.')));
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSavingWeeklyPulse = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to save weekly pulse: ${error.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  Future<void> _chooseExercise(
    ExerciseRecommendationModel recommendation,
  ) async {
    final goal = await ExerciseGoalService.instance.chooseExercise(
      recommendation,
    );
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          goal.isNoneToday
              ? 'None today saved as your exercise status.'
              : '${goal.exerciseName} saved as today\'s goal.',
        ),
      ),
    );

    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _completeGoal() async {
    await ExerciseGoalService.instance.completeGoal();
  }

  void _redoWeeklyPulse() {
    setState(() {
      _isEditingWeeklyPulse = true;
    });
  }

  Future<void> _cancelGoal() async {
    await ExerciseGoalService.instance.cancelGoal();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Today\'s exercise goal canceled.')),
    );
    await _loadRecommendations();
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.78;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 12,
        ),
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF0F1B2D)
                : const Color(0xFFF6FBF9),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: pageBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: ValueListenableBuilder<ExerciseGoalState>(
            valueListenable: ExerciseGoalService.instance.notifier,
            builder: (context, goalState, _) {
              return ValueListenableBuilder<ActivityTrackingState>(
                valueListenable: ActivityService.instance.notifier,
                builder: (context, activityState, _) {
                  final goal = goalState.goal;
                  final hasGoal = goal != null && goal.hasSelectedGoal;
                  final pages = <Widget>[
                    _SmartNudgeDialogCard(
                      emoji: widget.emoji,
                      message: widget.message,
                      recommendations: _adaptiveNudges,
                      isLoading: _isLoadingAdaptiveNudges,
                      onStatusChanged: _handleNudgeStatus,
                      onRemind: _remindForNudge,
                    ),
                    if (hasGoal)
                      SelectedExerciseGoalCard(
                        goal: goal,
                        distanceMeters: activityState.log.distanceMeters,
                        isSaving: goalState.isSaving,
                        onDone: _completeGoal,
                        onCancel: _cancelGoal,
                      )
                    else if (_isLoadingRecommendations)
                      const _AssistantLoadingCard()
                    else
                      AssistantExerciseCard(
                        recommendations: _recommendations,
                        isSaving: goalState.isSaving,
                        onChoose: _chooseExercise,
                      ),
                    _WeeklyPulseCard(
                      isLoading: _isLoadingWeeklyPulse,
                      isSaving: _isSavingWeeklyPulse,
                      hasResponse: _hasWeeklyPulseResponse,
                      isEditing: _isEditingWeeklyPulse,
                      productivityFocusLevel: _productivityFocusLevel,
                      recoveryRestLevel: _recoveryRestLevel,
                      detachmentLevel: _detachmentLevel,
                      accomplishmentLevel: _accomplishmentLevel,
                      onProductivityChanged: (value) {
                        setState(() {
                          _productivityFocusLevel = value;
                        });
                      },
                      onRecoveryChanged: (value) {
                        setState(() {
                          _recoveryRestLevel = value;
                        });
                      },
                      onDetachmentChanged: (value) {
                        setState(() {
                          _detachmentLevel = value;
                        });
                      },
                      onAccomplishmentChanged: (value) {
                        setState(() {
                          _accomplishmentLevel = value;
                        });
                      },
                      onSave: _saveWeeklyPulse,
                      onRedo: _redoWeeklyPulse,
                    ),
                  ];

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFF1FB489), Color(0xFF59B7EF)],
                              ),
                            ),
                            child: _AssistantLottieIcon(
                              emoji: widget.emoji,
                              size: 36,
                              fallbackFontSize: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'VitalySync Assistant',
                              style: TextStyle(
                                color: pagePrimaryTextColor(context),
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Flexible(
                        child: PageView(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _pageIndex = index;
                            });
                          },
                          children: pages
                              .map((page) => SingleChildScrollView(child: page))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _AssistantPageDots(
                        count: pages.length,
                        currentIndex: min(_pageIndex, pages.length - 1),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SmartNudgeDialogCard extends StatelessWidget {
  final String emoji;
  final String message;
  final List<AdaptiveNudgeRecommendation> recommendations;
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
    required this.isLoading,
    required this.onStatusChanged,
    required this.onRemind,
  });

  @override
  Widget build(BuildContext context) {
    final primary = recommendations.isEmpty ? null : recommendations.first;
    final title = primary?.title ?? 'Smart Nudge';
    final body = primary?.message ?? message;
    final actionLabel = primary?.actionLabel ?? 'Done';
    final priority = primary?.priority ?? 'low';
    final priorityColor = _priorityColor(priority);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1FB489), Color(0xFF5DB8F0)],
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
              emoji: emoji,
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
          if (isLoading) ...[
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
            if (recommendations.length > 1) ...[
              const SizedBox(height: 12),
              ...recommendations
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    await onStatusChanged(primary, 'dismissed');
                  },
                  icon: const Icon(Icons.close_rounded, size: 17),
                  label: const Text('Dismiss'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await onRemind(primary);
                  },
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
                  onPressed: () async {
                    await onStatusChanged(primary, 'completed');
                  },
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text(actionLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF187A66),
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

class _WeeklyPulseCard extends StatelessWidget {
  final bool isLoading;
  final bool isSaving;
  final bool hasResponse;
  final bool isEditing;
  final int? productivityFocusLevel;
  final int? recoveryRestLevel;
  final int? detachmentLevel;
  final int? accomplishmentLevel;
  final ValueChanged<int> onProductivityChanged;
  final ValueChanged<int> onRecoveryChanged;
  final ValueChanged<int> onDetachmentChanged;
  final ValueChanged<int> onAccomplishmentChanged;
  final VoidCallback onSave;
  final VoidCallback onRedo;

  const _WeeklyPulseCard({
    required this.isLoading,
    required this.isSaving,
    required this.hasResponse,
    required this.isEditing,
    required this.productivityFocusLevel,
    required this.recoveryRestLevel,
    required this.detachmentLevel,
    required this.accomplishmentLevel,
    required this.onProductivityChanged,
    required this.onRecoveryChanged,
    required this.onDetachmentChanged,
    required this.onAccomplishmentChanged,
    required this.onSave,
    required this.onRedo,
  });

  bool get _canSave =>
      productivityFocusLevel != null &&
      recoveryRestLevel != null &&
      detachmentLevel != null &&
      accomplishmentLevel != null &&
      !isSaving;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _AssistantLoadingCard();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? const Color(0xFF0F1F2E).withValues(alpha: 0.96)
        : const Color(0xFFF8FEFC);
    final headerGradient = isDark
        ? const [Color(0xFF123655), Color(0xFF1FB489)]
        : const [Color(0xFFE8FFF5), Color(0xFFE8F7FF)];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFBCEBDD),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF1FB489,
            ).withValues(alpha: isDark ? 0.12 : 0.08),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: headerGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.82),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.7),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.9),
                    ),
                  ),
                  child: const Text(
                    '\u{1F33F}',
                    style: TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Pulse',
                        style: TextStyle(
                          color: pagePrimaryTextColor(context),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasResponse
                            ? 'Your check-in is saved for this Monday-based week.'
                            : 'A calm check-in for focus, rest, distance, and wins.',
                        style: TextStyle(
                          color: pageSecondaryTextColor(context),
                          fontSize: 13.5,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (hasResponse && !isEditing) ...[
            const SizedBox(height: 16),
            _WeeklyPulseSavedView(onRedo: onRedo),
          ] else ...[
            const SizedBox(height: 16),
            _PulseLikertQuestion(
              emoji: '\u{1F3AF}',
              title: 'I was able to stay focused on important tasks this week.',
              lowLabel: 'Scattered',
              highLabel: 'Focused',
              accentColor: const Color(0xFF38BDF8),
              value: productivityFocusLevel,
              onChanged: onProductivityChanged,
            ),
            const SizedBox(height: 12),
            _PulseLikertQuestion(
              emoji: '\u{1F319}',
              title: 'I had enough breaks or recovery time this week.',
              lowLabel: 'Limited',
              highLabel: 'Rested',
              accentColor: const Color(0xFF8B5CF6),
              value: recoveryRestLevel,
              onChanged: onRecoveryChanged,
            ),
            const SizedBox(height: 12),
            _PulseLikertQuestion(
              emoji: '\u{1FAE7}',
              title:
                  'I felt emotionally distant from my responsibilities this week.',
              lowLabel: 'Connected',
              highLabel: 'Detached',
              accentColor: const Color(0xFF14B8A6),
              value: detachmentLevel,
              onChanged: onDetachmentChanged,
            ),
            const SizedBox(height: 12),
            _PulseLikertQuestion(
              emoji: '\u{2728}',
              title: 'I felt I made meaningful progress this week.',
              lowLabel: 'Stuck',
              highLabel: 'Progress',
              accentColor: const Color(0xFFF59E0B),
              value: accomplishmentLevel,
              onChanged: onAccomplishmentChanged,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _canSave ? onSave : null,
                icon: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline_rounded),
                label: Text(
                  isSaving
                      ? 'Saving...'
                      : hasResponse
                      ? 'Update Weekly Pulse'
                      : 'Save Weekly Pulse',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1FB489),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeeklyPulseSavedView extends StatelessWidget {
  final VoidCallback onRedo;

  const _WeeklyPulseSavedView({required this.onRedo});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFD7F5E7),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFDCFCE7),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: const Text('\u{2705}', style: TextStyle(fontSize: 28)),
          ),
          const SizedBox(height: 12),
          Text(
            'Weekly pulse saved',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: pagePrimaryTextColor(context),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'You are set for this week. A fresh pulse opens again next Monday.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: pageSecondaryTextColor(context),
              fontSize: 13.5,
              height: 1.38,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRedo,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Redo Weekly Pulse'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF15803D),
              side: const BorderSide(color: Color(0xFF86EFAC)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseLikertQuestion extends StatelessWidget {
  final String emoji;
  final String title;
  final String lowLabel;
  final String highLabel;
  final Color accentColor;
  final int? value;
  final ValueChanged<int> onChanged;

  const _PulseLikertQuestion({
    required this.emoji,
    required this.title,
    required this.lowLabel,
    required this.highLabel,
    required this.accentColor,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.045)
            : Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : accentColor.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 17)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: pagePrimaryTextColor(context),
                    fontSize: 14.5,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(5, (index) {
              final optionValue = index + 1;
              final selected = value == optionValue;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index == 4 ? 0 : 7),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => onChanged(optionValue),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? accentColor
                            : isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? accentColor
                              : pageBorderColor(context),
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: accentColor.withValues(alpha: 0.24),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        '$optionValue',
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : pagePrimaryTextColor(context),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  lowLabel,
                  style: TextStyle(
                    color: pageSecondaryTextColor(context),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                highLabel,
                style: TextStyle(
                  color: pageSecondaryTextColor(context),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssistantLoadingCard extends StatelessWidget {
  const _AssistantLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: pageBorderColor(context)),
      ),
      child: const CircularProgressIndicator(),
    );
  }
}

class _AssistantPageDots extends StatelessWidget {
  final int count;
  final int currentIndex;

  const _AssistantPageDots({required this.count, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final selected = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: selected ? 22 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF1FB489)
                : pageBorderColor(context),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _AssistantLottieIcon extends StatelessWidget {
  final String emoji;
  final double size;
  final double fallbackFontSize;

  const _AssistantLottieIcon({
    required this.emoji,
    required this.size,
    required this.fallbackFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      _assistantAnimationPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      repeat: true,
      animate: true,
      errorBuilder: (context, error, stackTrace) {
        return Text(
          emoji,
          style: TextStyle(fontSize: fallbackFontSize, height: 1),
        );
      },
    );
  }
}

class _FloatingHeartButton extends StatelessWidget {
  final String emoji;
  final double size;
  final bool isActive;
  final bool isDragging;
  final bool? hasPendingWeeklyPulse;
  final VoidCallback onTap;

  const _FloatingHeartButton({
    required this.emoji,
    required this.size,
    required this.isActive,
    required this.isDragging,
    required this.hasPendingWeeklyPulse,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: 'Wellness assistant',
      child: Semantics(
        button: true,
        label: 'Open wellness assistant',
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              scale: isDragging
                  ? 1.08
                  : isActive
                  ? 1.04
                  : 1,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: size,
                    height: size,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isDark
                            ? const [Color(0xFF123655), Color(0xFF1FB489)]
                            : const [Color(0xFFFFFFFF), Color(0xFFE8FAFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.white.withValues(alpha: 0.92),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.32 : 0.14,
                          ),
                          blurRadius: 22,
                          offset: const Offset(0, 12),
                        ),
                        BoxShadow(
                          color: const Color(
                            0xFF40B8D6,
                          ).withValues(alpha: isDark ? 0.2 : 0.26),
                          blurRadius: 20,
                          spreadRadius: -4,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: _AssistantLottieIcon(
                      emoji: emoji,
                      size: 44,
                      fallbackFontSize: 26,
                    ),
                  ),
                  if (hasPendingWeeklyPulse == true)
                    Positioned(
                      right: 1,
                      top: 1,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFACC15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF123655)
                                : Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFEAB308,
                              ).withValues(alpha: 0.38),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
