import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../../features/adaptive/data/adaptive_nudge_api.dart';
import '../../features/activity/data/activity_service.dart';
import '../../features/exercise/data/exercise_goal_service.dart';
import '../../features/exercise/data/exercise_recommendation_model.dart';
import '../../features/exercise/data/exercise_recommendation_service.dart';
import '../../features/exercise/presentation/widgets/assistant_exercise_card.dart';
import '../../features/exercise/presentation/widgets/selected_exercise_goal_card.dart';
import '../../features/home/data/environment_model.dart';
import '../../features/log/data/log_api.dart';
import '../../features/nutrition/data/nutrition_analyzer.dart';
import '../../features/nutrition/data/nutrition_coach.dart';
import '../../features/nutrition/data/nutrition_insight_store.dart';
import '../../features/nutrition/data/nutrition_reminder_engine.dart';
import '../learning/first_week_learning_service.dart';
import '../theme/app_page_style.dart';
import '../widgets/app_skeleton.dart';
import '../widgets/first_week_learning_pill.dart';

part 'assistant_bubbles.dart';
part 'assistant_experience_panel.dart';
part 'assistant_quick_log_bar.dart';
part 'smart_nudge_dialog_card.dart';
part 'weekly_pulse_widgets.dart';
part 'assistant_visual_widgets.dart';

const _assistantAnimationPath = 'assets/animations/Assistant.json';
const _assistantSmartNudgeSectionIndex = 0;
const _assistantExerciseSectionIndex = 1;

enum _AssistantBubbleKind { smartNudge, nutrition, exercise }

enum _AssistantDockEdge { left, right }

String _shortAssistantText(String value, {int maxChars = 112}) {
  final clean = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (clean.isEmpty) {
    return '';
  }

  final sentenceMatch = RegExp(r'^(.+?[.!?])(?:\s|$)').firstMatch(clean);
  final firstSentence = sentenceMatch?.group(1)?.trim();
  final candidate = firstSentence != null && firstSentence.length <= maxChars
      ? firstSentence
      : clean;

  if (candidate.length <= maxChars) {
    return candidate;
  }

  final clipped = candidate.substring(0, maxChars).trimRight();
  final lastSpace = clipped.lastIndexOf(' ');
  final safeClip = lastSpace > maxChars * 0.62
      ? clipped.substring(0, lastSpace)
      : clipped;
  return '$safeClip...';
}

bool _isAiEnhancedNudge(AdaptiveNudgeRecommendation recommendation) {
  return recommendation.metadata['ai_enhanced'] == true;
}

bool _isFallbackNudge(AdaptiveNudgeRecommendation recommendation) {
  return recommendation.triggerReason == 'Local fallback' ||
      recommendation.metadata['local_fallback'] == true;
}

List<AdaptiveNudgeRecommendation> prioritizeAssistantNudges(
  List<AdaptiveNudgeRecommendation> recommendations,
) {
  final unique = <String, AdaptiveNudgeRecommendation>{};
  for (final recommendation in recommendations) {
    final key =
        '${recommendation.nudgeEventId ?? 0}:${recommendation.nudgeType}:${recommendation.title}';
    unique[key] = recommendation;
  }

  final visibleItems = unique.values
      .where(
        (item) => item.metadata['assistant_feedback_status'] != 'dismissed',
      )
      .toList();
  final items = visibleItems.isEmpty ? unique.values.toList() : visibleItems;

  return items..sort((left, right) {
    final rightScore = _assistantNudgeRankScore(right);
    final leftScore = _assistantNudgeRankScore(left);
    return rightScore.compareTo(leftScore);
  });
}

int _assistantNudgeRankScore(AdaptiveNudgeRecommendation recommendation) {
  var score = 0;
  if (_isAiEnhancedNudge(recommendation)) {
    score += 8;
  }
  if (!_isFallbackNudge(recommendation)) {
    score += 4;
  }
  if (recommendation.metadata['assistant_feedback_status'] == 'accepted') {
    score += 1;
  }
  return score;
}

class FloatingSmartNudgeAssistant extends StatefulWidget {
  final String message;
  final String emoji;
  final double buttonSize;
  final Duration autoHideDuration;
  final VoidCallback? onLogMealRequested;
  final VoidCallback? onLogPageRequested;

  const FloatingSmartNudgeAssistant({
    super.key,
    required this.message,
    this.emoji = '\u{1F499}',
    this.buttonSize = 54,
    this.autoHideDuration = const Duration(seconds: 10),
    this.onLogMealRequested,
    this.onLogPageRequested,
  });

  @override
  State<FloatingSmartNudgeAssistant> createState() =>
      _FloatingSmartNudgeAssistantState();
}

class AssistantFloatingBubbleVisual extends StatefulWidget {
  final String emoji;
  final double size;

  const AssistantFloatingBubbleVisual({
    super.key,
    this.emoji = '\u{1F499}',
    this.size = 58,
  });

  @override
  State<AssistantFloatingBubbleVisual> createState() =>
      _AssistantFloatingBubbleVisualState();
}

class _AssistantFloatingBubbleVisualState
    extends State<AssistantFloatingBubbleVisual> {
  bool? _hasPendingWeeklyPulse;

  @override
  void initState() {
    super.initState();
    unawaited(_loadWeeklyPulseIndicator());
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

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: _FloatingHeartButton(
        emoji: widget.emoji,
        size: widget.size,
        isActive: false,
        isDragging: false,
        hasPendingWeeklyPulse: _hasPendingWeeklyPulse == true,
        onTap: () {},
      ),
    );
  }
}

class _FloatingSmartNudgeAssistantState
    extends State<FloatingSmartNudgeAssistant> {
  static const _moveAnimationDuration = Duration(milliseconds: 220);

  bool _isBubbleVisible = false;
  _AssistantBubbleKind _activeBubbleKind = _AssistantBubbleKind.smartNudge;
  bool _isDragging = false;
  bool _isDialogOpen = false;
  bool _hasCustomPosition = false;
  _AssistantDockEdge _dockEdge = _AssistantDockEdge.right;
  Offset _buttonOffset = Offset.zero;
  Timer? _bubbleSwitchTimer;
  List<ExerciseRecommendationModel> _recommendations = const [];
  List<AdaptiveNudgeRecommendation> _adaptiveNudges = const [];
  NutritionInsight? _nutritionInsight;
  Future<List<AdaptiveNudgeRecommendation>>? _adaptiveNudgeLoadFuture;
  Future<NutritionInsight?>? _nutritionInsightLoadFuture;
  bool _hasLoadedAdaptiveNudges = false;
  bool _hasLoadedNutritionInsight = false;
  int _lastCompletionEventId = 0;
  bool? _hasPendingWeeklyPulse;

  final ExerciseRecommendationService _recommendationService =
      const ExerciseRecommendationService();

  @override
  void initState() {
    super.initState();
    unawaited(ActivityService.instance.startTracking());
    unawaited(ExerciseGoalService.instance.start());
    ExerciseGoalService.instance.notifier.addListener(_handleGoalEvent);
    unawaited(_loadRecommendations());
    unawaited(_loadAdaptiveNudges());
    unawaited(_loadNutritionInsight());
    unawaited(_loadWeeklyPulseIndicator());
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

  Future<List<ExerciseRecommendationModel>> _loadRecommendations() async {
    await ActivityService.instance.startTracking(refreshFromBackend: false);

    try {
      final recommendations = await _recommendationService
          .loadRecommendations();
      if (!mounted) return recommendations;

      setState(() {
        _recommendations = recommendations;
      });
      return recommendations;
    } catch (_) {
      return _recommendations;
    }
  }

  Future<EnvironmentSnapshot?> _loadEnvironmentSnapshot() {
    return _recommendationService.loadEnvironmentSnapshot();
  }

  Future<List<AdaptiveNudgeRecommendation>> _loadAdaptiveNudges({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _adaptiveNudgeLoadFuture != null) {
      return _adaptiveNudgeLoadFuture!;
    }

    late final Future<List<AdaptiveNudgeRecommendation>> loadFuture;
    loadFuture = _loadAdaptiveNudgesInternal(forceRefresh: forceRefresh)
        .whenComplete(() {
          if (identical(_adaptiveNudgeLoadFuture, loadFuture)) {
            _adaptiveNudgeLoadFuture = null;
          }
        });
    _adaptiveNudgeLoadFuture = loadFuture;
    return loadFuture;
  }

  Future<List<AdaptiveNudgeRecommendation>> _loadAdaptiveNudgesInternal({
    bool forceRefresh = false,
  }) async {
    try {
      final response = await AdaptiveNudgeApi.fetchAssistantRecommendations(
        limit: 3,
        forceRefresh: forceRefresh,
      );
      final recommendations = prioritizeAssistantNudges(
        response.recommendations,
      );
      if (!mounted) {
        return recommendations;
      }

      setState(() {
        _adaptiveNudges = recommendations;
        _hasLoadedAdaptiveNudges = true;
      });

      return recommendations;
    } catch (_) {
      if (!mounted) {
        return _adaptiveNudges;
      }

      setState(() {
        _hasLoadedAdaptiveNudges = true;
      });
      return _adaptiveNudges;
    }
  }

  Future<NutritionInsight?> _loadNutritionInsight({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _nutritionInsightLoadFuture != null) {
      return _nutritionInsightLoadFuture!;
    }

    late final Future<NutritionInsight?> loadFuture;
    loadFuture = _loadNutritionInsightInternal(forceRefresh: forceRefresh)
        .whenComplete(() {
          if (identical(_nutritionInsightLoadFuture, loadFuture)) {
            _nutritionInsightLoadFuture = null;
          }
        });
    _nutritionInsightLoadFuture = loadFuture;
    return loadFuture;
  }

  Future<NutritionInsight?> _loadNutritionInsightInternal({
    bool forceRefresh = false,
  }) async {
    try {
      final insight = await NutritionReminderEngine.instance
          .assistantInsightForToday(forceRefresh: forceRefresh);
      if (!mounted) {
        return insight;
      }

      setState(() {
        _nutritionInsight = insight;
        _hasLoadedNutritionInsight = true;
      });
      return insight;
    } catch (_) {
      if (!mounted) {
        return _nutritionInsight;
      }

      setState(() {
        _hasLoadedNutritionInsight = true;
      });
      return _nutritionInsight;
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
    final completedGoal = state.goal;
    if (completedGoal != null &&
        completedGoal.isCompleted &&
        !completedGoal.isNoneToday) {
      unawaited(
        LogApi.applyExerciseGoalSelection(completedGoal).catchError((_) {
          return <String, dynamic>{};
        }),
      );
    }
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(state.completionMessage!)));
  }

  void _showBubble() {
    _bubbleSwitchTimer?.cancel();

    setState(() {
      _isBubbleVisible = true;
      _activeBubbleKind = _availableBubbleKinds().first;
    });

    _scheduleNextBubble();
  }

  void _hideBubble() {
    _bubbleSwitchTimer?.cancel();

    if (!mounted || !_isBubbleVisible) return;

    setState(() {
      _isBubbleVisible = false;
    });
  }

  List<_AssistantBubbleKind> _availableBubbleKinds() {
    return [
      _AssistantBubbleKind.smartNudge,
      if (_nutritionInsight != null &&
          _nutritionInsight!.message.trim().isNotEmpty)
        _AssistantBubbleKind.nutrition,
      _AssistantBubbleKind.exercise,
    ];
  }

  void _scheduleNextBubble() {
    _bubbleSwitchTimer?.cancel();
    _bubbleSwitchTimer = Timer(widget.autoHideDuration, _advanceBubblePreview);
  }

  void _advanceBubblePreview() {
    if (!mounted || !_isBubbleVisible) return;

    final bubbleKinds = _availableBubbleKinds();
    final currentIndex = bubbleKinds.indexOf(_activeBubbleKind);
    final nextIndex = currentIndex < 0 ? 0 : currentIndex + 1;

    if (nextIndex >= bubbleKinds.length) {
      _hideBubble();
      return;
    }

    setState(() {
      _activeBubbleKind = bubbleKinds[nextIndex];
    });

    _scheduleNextBubble();
  }

  Future<void> _openAssistantDialog({
    int initialSectionIndex = _assistantSmartNudgeSectionIndex,
  }) async {
    if (_isDialogOpen) {
      return;
    }

    _bubbleSwitchTimer?.cancel();
    setState(() {
      _isDialogOpen = true;
      _isBubbleVisible = false;
    });

    if (!mounted) return;

    try {
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: MaterialLocalizations.of(
          context,
        ).modalBarrierDismissLabel,
        barrierColor: Colors.black.withValues(alpha: 0.42),
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (dialogContext, _, _) {
          return SafeArea(
            minimum: const EdgeInsets.all(8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: Material(
                      color: Colors.transparent,
                      child: AssistantExperiencePanel(
                        message: widget.message,
                        emoji: widget.emoji,
                        recommendations: _recommendations,
                        adaptiveNudges: _adaptiveNudges,
                        nutritionInsight: _nutritionInsight,
                        hasLoadedAdaptiveNudges: _hasLoadedAdaptiveNudges,
                        hasLoadedNutritionInsight: _hasLoadedNutritionInsight,
                        initialSectionIndex: initialSectionIndex,
                        onRefreshRecommendations: _loadRecommendations,
                        onRefreshAdaptiveNudges: _loadAdaptiveNudges,
                        onRefreshNutritionInsight: _loadNutritionInsight,
                        onRefreshEnvironment: _loadEnvironmentSnapshot,
                        onLogMealRequested: widget.onLogMealRequested,
                        onLogPageRequested: widget.onLogPageRequested,
                        useSafeAreaPadding: false,
                        onClose: () => Navigator.of(dialogContext).pop(),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
        transitionBuilder: (context, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
              child: child,
            ),
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDialogOpen = false;
        });
      }
    }

    if (!mounted) return;

    await _loadWeeklyPulseIndicator();
  }

  void _handleAssistantTap() {
    _openAssistantDialog();
  }

  void _openExerciseDialog() {
    _openAssistantDialog(initialSectionIndex: _assistantExerciseSectionIndex);
  }

  Future<void> _acceptExercisePreview(
    ExerciseRecommendationModel recommendation,
  ) async {
    if (ExerciseGoalService.instance.notifier.value.isSaving) {
      return;
    }

    _bubbleSwitchTimer?.cancel();
    try {
      final goal = await ExerciseGoalService.instance.chooseExercise(
        recommendation,
      );
      var appliedToLog = false;
      var queuedForLog = false;

      try {
        final result = await LogApi.applyExerciseGoalSelection(goal);
        appliedToLog = result['exercise_applied_to_log'] == true;
        queuedForLog = result['exercise_applied_to_log'] == false;
      } catch (_) {
        // The goal remains saved locally even if today's log sync is delayed.
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _exerciseSelectionMessage(
              exerciseName: goal.exerciseName,
              isNoneToday: goal.isNoneToday,
              appliedToLog: appliedToLog,
              queuedForLog: queuedForLog,
            ),
          ),
        ),
      );

      if (goal.isNoneToday) {
        setState(() {
          _isBubbleVisible = true;
          _activeBubbleKind = _AssistantBubbleKind.exercise;
        });
        _scheduleNextBubble();
        return;
      }

      await _openAssistantDialog(
        initialSectionIndex: _assistantExerciseSectionIndex,
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to save exercise: ${error.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
      _scheduleNextBubble();
    }
  }

  String _exerciseSelectionMessage({
    required String exerciseName,
    required bool isNoneToday,
    required bool appliedToLog,
    required bool queuedForLog,
  }) {
    final normalizedName = LogApi.normalizeExerciseNameForLog(exerciseName);
    var message = '$exerciseName saved as today\'s goal.';
    if (isNoneToday) {
      message = 'Rest choice saved for today.';
      if (appliedToLog) {
        message += ' Today\'s log now shows None.';
      } else if (queuedForLog) {
        message += ' None will prefill the log page.';
      }
    } else if (appliedToLog) {
      message += ' $normalizedName also updated today\'s log.';
    } else if (queuedForLog) {
      message += ' $normalizedName will prefill the log page.';
    }

    return message;
  }

  EdgeInsets _dragPadding(BuildContext context, Size bounds) {
    final safePadding = MediaQuery.paddingOf(context);

    return EdgeInsets.only(
      left: safePadding.left,
      top: safePadding.top + 12,
      right: safePadding.right,
      bottom: safePadding.bottom + 16,
    );
  }

  Offset _defaultButtonOffset(Size bounds, EdgeInsets padding) {
    return Offset(
      max(padding.left, bounds.width - padding.right - widget.buttonSize),
      padding.top + 112,
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

  double _dockedButtonX(
    _AssistantDockEdge edge,
    Size bounds,
    EdgeInsets padding,
  ) {
    final maxX = max(
      padding.left,
      bounds.width - padding.right - widget.buttonSize,
    );

    return edge == _AssistantDockEdge.left ? padding.left : maxX;
  }

  _AssistantDockEdge _nearestDockEdge(Offset offset, Size bounds) {
    return offset.dx + (widget.buttonSize / 2) < bounds.width / 2
        ? _AssistantDockEdge.left
        : _AssistantDockEdge.right;
  }

  Offset _snapButtonOffsetToEdge(
    Offset offset,
    Size bounds,
    EdgeInsets padding,
    _AssistantDockEdge edge,
  ) {
    final clampedOffset = _clampButtonOffset(offset, bounds, padding);
    return Offset(_dockedButtonX(edge, bounds, padding), clampedOffset.dy);
  }

  Offset _effectiveButtonOffset(Size bounds, EdgeInsets padding) {
    if (!_hasCustomPosition) {
      return _defaultButtonOffset(bounds, padding);
    }

    if (_isDragging) {
      return _clampButtonOffset(_buttonOffset, bounds, padding);
    }

    return _snapButtonOffsetToEdge(_buttonOffset, bounds, padding, _dockEdge);
  }


  void _handlePanStart(Size bounds, EdgeInsets padding) {
    _bubbleSwitchTimer?.cancel();
    final currentOffset = _effectiveButtonOffset(bounds, padding);

    setState(() {
      _isDragging = true;
      _hasCustomPosition = true;
      _buttonOffset = currentOffset;
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
    final dockEdge = _nearestDockEdge(_buttonOffset, bounds);

    setState(() {
      _isDragging = false;
      _dockEdge = dockEdge;
      _buttonOffset = _snapButtonOffsetToEdge(
        _buttonOffset,
        bounds,
        padding,
        dockEdge,
      );
    });

    if (_isBubbleVisible) {
      _scheduleNextBubble();
    }
  }

  Widget _buildActiveBubble(
    ExerciseGoalState goalState, {
    required bool tailOnRight,
  }) {
    final primaryNudge = _adaptiveNudges.isEmpty ? null : _adaptiveNudges.first;

    switch (_activeBubbleKind) {
      case _AssistantBubbleKind.nutrition:
        final insight = _nutritionInsight;
        if (insight == null) {
          return _SmartNudgeBubble(
            emoji: widget.emoji,
            message: _shortAssistantText(
              primaryNudge?.message ?? widget.message,
            ),
            onClose: _hideBubble,
            tailOnRight: tailOnRight,
          );
        }

        return _NutritionNudgeBubble(
          insight: insight,
          onClose: _hideBubble,
          tailOnRight: tailOnRight,
        );
      case _AssistantBubbleKind.exercise:
        return _ExercisePreviewBubble(
          goalState: goalState,
          recommendations: _recommendations,
          onClose: _hideBubble,
          onChoose: _openExerciseDialog,
          onAccept: _acceptExercisePreview,
          tailOnRight: tailOnRight,
        );
      case _AssistantBubbleKind.smartNudge:
        return _SmartNudgeBubble(
          emoji: widget.emoji,
          message: _shortAssistantText(primaryNudge?.message ?? widget.message),
          onClose: _hideBubble,
          tailOnRight: tailOnRight,
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
        final isDockedRight = _dockEdge == _AssistantDockEdge.right;
        const bubbleGap = 10.0;
        // Bubble sits beside the button, on the opposite side of the dock.
        final availableWidth = isDockedRight
            ? buttonOffset.dx - padding.left - bubbleGap
            : bounds.width - padding.right - buttonOffset.dx -
                widget.buttonSize - bubbleGap;
        final maxBubbleWidth = min(max(availableWidth, 200.0), 356.0);
        final bubbleLeft = isDockedRight
            ? max(padding.left, buttonOffset.dx - bubbleGap - maxBubbleWidth)
            : buttonOffset.dx + widget.buttonSize + bubbleGap;
        // Horizontal slide animation toward the button.
        final bubbleSlideOffset = isDockedRight
            ? const Offset(0.08, 0)
            : const Offset(-0.08, 0);
        final moveDuration = _isDragging
            ? Duration.zero
            : _moveAnimationDuration;

        return SizedBox.expand(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedPositioned(
                duration: moveDuration,
                curve: Curves.easeOutCubic,
                left: bubbleLeft,
                top: buttonOffset.dy,
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
                        builder: (context, goalState, _) =>
                            _buildActiveBubble(
                              goalState,
                              tailOnRight: isDockedRight,
                            ),
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
