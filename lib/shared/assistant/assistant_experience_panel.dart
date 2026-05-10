part of 'floating_smart_nudge_assistant.dart';

class AssistantExperiencePanel extends StatefulWidget {
  final String message;
  final String emoji;
  final List<ExerciseRecommendationModel> recommendations;
  final List<AdaptiveNudgeRecommendation> adaptiveNudges;
  final NutritionInsight? nutritionInsight;
  final Future<void> Function() onRefreshRecommendations;
  final Future<List<AdaptiveNudgeRecommendation>> Function()
  onRefreshAdaptiveNudges;
  final VoidCallback? onClose;
  final bool useSafeAreaPadding;

  const AssistantExperiencePanel({
    super.key,
    required this.message,
    required this.emoji,
    required this.recommendations,
    required this.adaptiveNudges,
    this.nutritionInsight,
    required this.onRefreshRecommendations,
    required this.onRefreshAdaptiveNudges,
    this.onClose,
    this.useSafeAreaPadding = true,
  });

  @override
  State<AssistantExperiencePanel> createState() =>
      _AssistantExperiencePanelState();
}

class _AssistantExperiencePanelState extends State<AssistantExperiencePanel> {
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
    _loadAdaptiveNudges(showLoading: _adaptiveNudges.isEmpty);
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

  Future<void> _loadAdaptiveNudges({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoadingAdaptiveNudges = true;
      });
    }

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
        ? 'Dismissed.'
        : status == 'completed'
        ? 'Accepted.'
        : 'Saved.';
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
    final panel = Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: widget.useSafeAreaPadding
            ? MediaQuery.viewInsetsOf(context).bottom + 12
            : 0,
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
                    nutritionInsight: widget.nutritionInsight,
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
                              colors: [
                                Color.fromARGB(255, 121, 73, 223),
                                Color(0xFF59B7EF),
                              ],
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
                          onPressed:
                              widget.onClose ?? () => Navigator.pop(context),
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
    );

    if (!widget.useSafeAreaPadding) {
      return panel;
    }

    return SafeArea(child: panel);
  }
}
