import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../features/activity/data/activity_service.dart';
import '../../features/exercise/data/exercise_goal_service.dart';
import '../../features/exercise/data/exercise_recommendation_model.dart';
import '../../features/exercise/data/exercise_recommendation_service.dart';
import '../../features/exercise/presentation/widgets/assistant_exercise_card.dart';
import '../../features/exercise/presentation/widgets/selected_exercise_goal_card.dart';
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
  int _lastCompletionEventId = 0;

  final ExerciseRecommendationService _recommendationService =
      const ExerciseRecommendationService();

  @override
  void initState() {
    super.initState();
    ExerciseGoalService.instance.start();
    ExerciseGoalService.instance.notifier.addListener(_handleGoalEvent);
    _loadRecommendations();
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
          onRefreshRecommendations: _loadRecommendations,
        );
      },
    );
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
                            message: widget.message,
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
  final Future<void> Function() onRefreshRecommendations;

  const _AssistantExerciseDialog({
    required this.message,
    required this.emoji,
    required this.recommendations,
    required this.onRefreshRecommendations,
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
  int _pageIndex = 0;
  bool _isLoadingRecommendations = false;

  @override
  void initState() {
    super.initState();
    _recommendations = widget.recommendations;
    if (_recommendations.isEmpty) {
      _loadRecommendations();
    }
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

  const _SmartNudgeDialogCard({required this.emoji, required this.message});

  @override
  Widget build(BuildContext context) {
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
          const Text(
            'Smart Nudge',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
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
  final VoidCallback onTap;

  const _FloatingHeartButton({
    required this.emoji,
    required this.size,
    required this.isActive,
    required this.isDragging,
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
              child: Container(
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
            ),
          ),
        ),
      ),
    );
  }
}
