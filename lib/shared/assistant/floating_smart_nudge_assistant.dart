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
import '../../features/nutrition/data/nutrition_coach.dart';
import '../../features/nutrition/data/nutrition_reminder_engine.dart';
import '../notifications/local_notification_service.dart';
import '../theme/app_page_style.dart';

part 'assistant_bubbles.dart';
part 'assistant_experience_panel.dart';
part 'smart_nudge_dialog_card.dart';
part 'weekly_pulse_widgets.dart';
part 'assistant_visual_widgets.dart';

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
    _loadWeeklyPulseIndicator();
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
  bool _isExercisePreviewVisible = false;
  bool _isDragging = false;
  bool _isDialogOpen = false;
  bool _hasCustomPosition = false;
  Offset _buttonOffset = Offset.zero;
  Timer? _bubbleSwitchTimer;
  List<ExerciseRecommendationModel> _recommendations = const [];
  List<AdaptiveNudgeRecommendation> _adaptiveNudges = const [];
  NutritionInsight? _nutritionInsight;
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
    _loadNutritionInsight();
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

  Future<void> _loadNutritionInsight() async {
    try {
      final insight = await NutritionReminderEngine.instance
          .assistantInsightForToday();
      if (!mounted) {
        return;
      }

      setState(() {
        _nutritionInsight = insight;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _nutritionInsight = null;
      });
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
    if (_isDialogOpen) {
      return;
    }

    _bubbleSwitchTimer?.cancel();
    setState(() {
      _isDialogOpen = true;
      _isBubbleVisible = false;
      _isExercisePreviewVisible = false;
    });

    if (!mounted) return;

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return AssistantExperiencePanel(
            message: widget.message,
            emoji: widget.emoji,
            recommendations: _recommendations,
            adaptiveNudges: _adaptiveNudges,
            nutritionInsight: _nutritionInsight,
            onRefreshRecommendations: _loadRecommendations,
            onRefreshAdaptiveNudges: _loadAdaptiveNudges,
            onClose: () => Navigator.of(context).pop(),
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
                            title: _adaptiveNudges.isEmpty
                                ? 'Smart Nudge'
                                : _adaptiveNudges.first.title,
                            message: _adaptiveNudges.isEmpty
                                ? widget.message
                                : _adaptiveNudges.first.message,
                            nutritionInsight: _nutritionInsight,
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
