part of 'floating_smart_nudge_assistant.dart';

class AssistantExperiencePanel extends StatefulWidget {
  final String message;
  final String emoji;
  final List<ExerciseRecommendationModel> recommendations;
  final List<AdaptiveNudgeRecommendation> adaptiveNudges;
  final NutritionInsight? nutritionInsight;
  final bool hasLoadedAdaptiveNudges;
  final bool hasLoadedNutritionInsight;
  final Future<List<ExerciseRecommendationModel>> Function()
  onRefreshRecommendations;
  final Future<List<AdaptiveNudgeRecommendation>> Function({bool forceRefresh})
  onRefreshAdaptiveNudges;
  final Future<NutritionInsight?> Function({bool forceRefresh})
  onRefreshNutritionInsight;
  final Future<EnvironmentSnapshot?> Function() onRefreshEnvironment;
  final Future<CheckInStatus> Function()? checkInStatusLoader;
  final Future<Map<String, dynamic>> Function()? todayLogLoader;
  final VoidCallback? onLogMealRequested;
  final VoidCallback? onLogPageRequested;
  final VoidCallback? onClose;
  final bool useSafeAreaPadding;
  final int initialSectionIndex;

  const AssistantExperiencePanel({
    super.key,
    required this.message,
    required this.emoji,
    required this.recommendations,
    required this.adaptiveNudges,
    this.nutritionInsight,
    this.hasLoadedAdaptiveNudges = false,
    this.hasLoadedNutritionInsight = false,
    required this.onRefreshRecommendations,
    required this.onRefreshAdaptiveNudges,
    required this.onRefreshNutritionInsight,
    required this.onRefreshEnvironment,
    this.checkInStatusLoader,
    this.todayLogLoader,
    this.onLogMealRequested,
    this.onLogPageRequested,
    this.onClose,
    this.useSafeAreaPadding = true,
    this.initialSectionIndex = _assistantSmartNudgeSectionIndex,
  });

  @override
  State<AssistantExperiencePanel> createState() =>
      _AssistantExperiencePanelState();
}

class _AssistantExperiencePanelState extends State<AssistantExperiencePanel> {
  late final PageController _pageController;
  late final List<ScrollController> _sectionScrollControllers;

  late List<ExerciseRecommendationModel> _recommendations;
  late List<AdaptiveNudgeRecommendation> _adaptiveNudges;
  NutritionInsight? _nutritionInsight;
  EnvironmentSnapshot? _environmentSnapshot;
  int _pageIndex = _assistantSmartNudgeSectionIndex;
  bool _isLoadingRecommendations = false;
  bool _isLoadingAdaptiveNudges = false;
  bool _isLoadingNutritionInsight = false;
  bool _isLoadingEnvironment = false;
  bool _isLoadingCheckIn = true;
  FirstWeekLearningState _firstWeekLearning =
      const FirstWeekLearningState.hidden();
  bool _isSavingCheckIn = false;
  bool _showHydrationLogger = false;
  bool _isLoadingHydrationContext = false;
  bool _isSavingHydration = false;
  bool _hasTodayHydrationLog = false;
  double _quickHydrationAmount = 0.25;
  double _todayHydrationLiters = 0;
  String? _hydrationHelperText;
  bool _isEditingCheckIn = false;
  CheckInStatus? _checkInStatus;
  CheckInDraft _checkInDraft = const CheckInDraft();
  String _exerciseGoalLabel = '3-4 days';
  int _checkInStreak = 0;

  @override
  void initState() {
    super.initState();
    _pageIndex = widget.initialSectionIndex;
    _pageController = PageController(initialPage: _pageIndex);
    _sectionScrollControllers = List.generate(3, (_) => ScrollController());
    _recommendations = widget.recommendations;
    _adaptiveNudges = prioritizeAssistantNudges(widget.adaptiveNudges);
    _nutritionInsight = widget.nutritionInsight;
    _recordVisibleProductEvents();
    CheckInStateCoordinator.instance.changes.addListener(
      _handleCheckInStateChanged,
    );
    if (_recommendations.isEmpty) {
      unawaited(_loadRecommendations());
    }
    if (_adaptiveNudges.isEmpty && !widget.hasLoadedAdaptiveNudges) {
      unawaited(_loadAdaptiveNudges());
    }
    if (_nutritionInsight == null && !widget.hasLoadedNutritionInsight) {
      unawaited(_loadNutritionInsight());
    }
    unawaited(_loadFirstWeekLearning());
    unawaited(_loadEnvironment());
    unawaited(_loadCheckInStatus());
  }

  @override
  void didUpdateWidget(covariant AssistantExperiencePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.recommendations, widget.recommendations) &&
        widget.recommendations.isNotEmpty) {
      _recommendations = widget.recommendations;
      _recordExerciseRecommendationImpressions(_recommendations);
    }
    if (!identical(oldWidget.adaptiveNudges, widget.adaptiveNudges) &&
        widget.adaptiveNudges.isNotEmpty) {
      _adaptiveNudges = prioritizeAssistantNudges(widget.adaptiveNudges);
    }
    if (oldWidget.nutritionInsight != widget.nutritionInsight &&
        widget.nutritionInsight != null) {
      _nutritionInsight = widget.nutritionInsight;
      _recordNutritionImpression(_nutritionInsight!);
    }
  }

  @override
  void dispose() {
    CheckInStateCoordinator.instance.changes.removeListener(
      _handleCheckInStateChanged,
    );
    _pageController.dispose();
    for (final controller in _sectionScrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleCheckInStateChanged() {
    final change = CheckInStateCoordinator.instance.changes.value;
    if (change == null || identical(change.source, this) || _isSavingCheckIn) {
      return;
    }
    _loadCheckInStatus();
  }

  void _recordVisibleProductEvents() {
    _recordExerciseRecommendationImpressions(_recommendations);
    final insight = _nutritionInsight;
    if (insight != null) _recordNutritionImpression(insight);
  }

  void _recordExerciseRecommendationImpressions(
    List<ExerciseRecommendationModel> recommendations,
  ) {
    final date = ExerciseGoalService.todayKey();
    for (final recommendation in recommendations.take(5)) {
      final key = _productEventToken(recommendation.exerciseName);
      unawaited(
        AdaptiveNudgeApi.recordProductEvent(
          eventName: 'exercise_recommendation_shown',
          eventKey: '$date:$key',
          dimensions: {
            'recommendation_key': recommendation.exerciseName,
            'exercise_category': recommendation.exerciseCategory,
            'is_none_today': recommendation.isNoneToday,
            'source': recommendation.recommendedBy,
          },
        ),
      );
    }
  }

  void _recordNutritionImpression(NutritionInsight insight) {
    final metadata = insight.metadata;
    unawaited(
      AdaptiveNudgeApi.recordProductEvent(
        eventName: 'nutrition_nudge_shown',
        eventKey:
            '${ExerciseGoalService.todayKey()}:${_productEventToken(insight.id)}',
        dimensions: {
          if (metadata['macro_focus'] != null)
            'macro_focus': metadata['macro_focus'].toString(),
          if (metadata['food_group'] != null)
            'food_group': metadata['food_group'].toString(),
          if (metadata['nutrition_nudge_type'] != null)
            'nutrition_nudge_type': metadata['nutrition_nudge_type'].toString(),
          'source': insight.source,
          'ai_enhanced': metadata['ai_enhanced'] == true,
        },
      ),
    );
  }

  String _productEventToken(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return normalized.isEmpty
        ? 'unspecified'
        : normalized.substring(0, min(normalized.length, 80));
  }

  Future<void> _loadRecommendations() async {
    if (_isLoadingRecommendations) {
      return;
    }

    setState(() {
      _isLoadingRecommendations = true;
    });

    try {
      final recommendations = await widget.onRefreshRecommendations();
      if (!mounted) return;

      setState(() {
        _recommendations = recommendations;
        _isLoadingRecommendations = false;
      });
      _recordExerciseRecommendationImpressions(recommendations);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoadingRecommendations = false;
      });
    }
  }

  Future<void> _loadAdaptiveNudges({
    bool showLoading = true,
    bool forceRefresh = false,
  }) async {
    if (_isLoadingAdaptiveNudges) {
      return;
    }

    if (showLoading) {
      setState(() {
        _isLoadingAdaptiveNudges = true;
      });
    }

    try {
      final recommendations = await widget.onRefreshAdaptiveNudges(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;

      setState(() {
        _adaptiveNudges = prioritizeAssistantNudges(recommendations);
        _isLoadingAdaptiveNudges = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoadingAdaptiveNudges = false;
      });
    }
  }

  Future<void> _loadNutritionInsight({
    bool showLoading = true,
    bool forceRefresh = false,
  }) async {
    if (_isLoadingNutritionInsight) {
      return;
    }

    if (showLoading) {
      setState(() {
        _isLoadingNutritionInsight = true;
      });
    }

    try {
      final insight = await widget.onRefreshNutritionInsight(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;

      setState(() {
        if (insight != null || _nutritionInsight == null) {
          _nutritionInsight = insight;
        }
        _isLoadingNutritionInsight = false;
      });
      if (insight != null) _recordNutritionImpression(insight);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoadingNutritionInsight = false;
      });
    }
  }

  Future<void> _loadEnvironment() async {
    if (_isLoadingEnvironment) {
      return;
    }

    setState(() {
      _isLoadingEnvironment = true;
    });

    try {
      final snapshot = await widget.onRefreshEnvironment();
      if (!mounted) return;

      setState(() {
        _environmentSnapshot = snapshot;
        _isLoadingEnvironment = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoadingEnvironment = false;
      });
    }
  }

  Future<void> _loadFirstWeekLearning() async {
    final learningState = await FirstWeekLearningService.load();
    if (!mounted) return;

    setState(() {
      _firstWeekLearning = learningState;
    });
  }

  Future<void> _handleNudgeStatus(
    AdaptiveNudgeRecommendation recommendation,
    String status,
  ) async {
    await AdaptiveNudgeApi.saveNudgeFeedback(
      recommendation: recommendation,
      status: status,
    );

    if (!mounted) return;

    if (status == 'dismissed') {
      setState(() {
        _adaptiveNudges = _adaptiveNudges
            .where((item) => !_isSameAdaptiveNudge(item, recommendation))
            .toList();
      });
      unawaited(_loadAdaptiveNudges(showLoading: false, forceRefresh: true));
    }

    final label = status == 'dismissed' ? 'Insight hidden.' : 'Saved to likes.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(label)));
  }

  Future<void> _handleNutritionInsightStatus(
    NutritionInsight insight,
    String status,
  ) async {
    await NutritionInsightStore.instance.saveFeedbackStatus(
      insight.id,
      status,
      metadata: insight.metadata,
    );
    await AdaptiveNudgeApi.createInsightFeedback(
      nudgeType: 'nutrition_insight',
      title: insight.title,
      message: insight.message,
      status: status,
      triggerReason: insight.source,
      actionLabel: status == 'accepted' ? 'Liked' : 'Disliked',
      metadata: {
        ...insight.metadata,
        'insight_id': insight.id,
        'source': insight.source,
        'confidence': insight.confidence.label,
      },
    );

    if (!mounted) return;

    if (status == 'dismissed') {
      setState(() {
        if (_nutritionInsight?.id == insight.id) {
          _nutritionInsight = null;
        }
      });
      unawaited(_loadNutritionInsight(showLoading: false, forceRefresh: true));
    }

    final label = status == 'dismissed'
        ? 'Nutrition insight hidden.'
        : 'Nutrition insight liked.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(label)));
  }

  bool _isSameAdaptiveNudge(
    AdaptiveNudgeRecommendation left,
    AdaptiveNudgeRecommendation right,
  ) {
    final leftEventId = left.nudgeEventId;
    final rightEventId = right.nudgeEventId;
    if (leftEventId != null && rightEventId != null) {
      return leftEventId == rightEventId;
    }

    return left.nudgeType == right.nudgeType &&
        left.title == right.title &&
        left.message == right.message;
  }

  Future<void> _loadHydrationContext() async {
    if (_isLoadingHydrationContext) {
      return;
    }

    setState(() {
      _isLoadingHydrationContext = true;
      _hydrationHelperText = null;
    });

    try {
      final data = await LogApi.fetchTodayLog();
      final rawLog = data['log'];
      final queued = await LogApi.readHydrationPrefill();
      if (!mounted) return;

      setState(() {
        _hasTodayHydrationLog = data['has_log'] == true && rawLog is Map;
        _todayHydrationLiters = rawLog is Map
            ? LogApi.parseDouble(rawLog['hydration_liters'])
            : queued;
        _isLoadingHydrationContext = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoadingHydrationContext = false;
        _hydrationHelperText = 'Unable to read today\'s log right now.';
      });
    }
  }

  void _openHydrationLogger() {
    setState(() {
      _showHydrationLogger = !_showHydrationLogger;
      _hydrationHelperText = null;
    });

    if (_showHydrationLogger) {
      unawaited(_loadHydrationContext());
    }
  }

  Future<void> _saveHydration() async {
    if (_isSavingHydration) {
      return;
    }

    setState(() {
      _isSavingHydration = true;
      _hydrationHelperText = null;
    });

    try {
      final result = await LogApi.quickAddHydration(
        amountLiters: _quickHydrationAmount,
      );
      final saved = result['quick_hydration_saved'] == true;
      final checkInRequired = result['check_in_required'] == true;
      final hydrationTotal = saved
          ? LogApi.parseDouble(result['hydration_liters'])
          : LogApi.parseDouble(result['queued_hydration_liters']);

      if (!mounted) return;

      setState(() {
        _hasTodayHydrationLog = saved;
        _todayHydrationLiters = hydrationTotal;
        _isSavingHydration = false;
        _hydrationHelperText = saved
            ? 'Water added to today\'s check-in.'
            : checkInRequired
            ? 'Water added to your pending weekly pulse. Complete it in the Check-in tab.'
            : 'No daily check-in yet. I prefilled this for the log page.';
      });
      unawaited(_loadCheckInStatus());
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSavingHydration = false;
        _hydrationHelperText =
            'Unable to save water: ${error.toString().replaceFirst('Exception: ', '')}';
      });
    }
  }

  void _openLogPage() {
    final callback = widget.onLogPageRequested;
    if (callback == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Open VitalySync to finish this log.')),
      );
      return;
    }

    callback();
    widget.onClose?.call();
  }

  void _openMealLog() {
    final callback = widget.onLogMealRequested;
    if (callback == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Open VitalySync to log a meal.')),
      );
      return;
    }

    callback();
    widget.onClose?.call();
  }

  Future<void> _loadCheckInStatus() async {
    setState(() {
      _isLoadingCheckIn = true;
    });

    try {
      final defaults = await OnboardingService.loadDefaults();
      final status =
          await (widget.checkInStatusLoader?.call() ??
              LogApi.fetchCheckInStatus());
      var streak = _checkInStreak;
      try {
        final todayLog =
            await (widget.todayLogLoader?.call() ?? LogApi.fetchTodayLog());
        final streakData = todayLog['streak'] as Map<String, dynamic>?;
        streak = LogApi.parseInt(streakData?['current_streak']);
      } catch (_) {
        // The completion state remains useful if streak metadata is unavailable.
      }
      final hydrationPrefill = await LogApi.readHydrationPrefill();
      final exercisePrefill = await LogApi.readExercisePrefill();
      if (!mounted) return;

      setState(() {
        _checkInStatus = status;
        _checkInStreak = streak;
        _isEditingCheckIn = !status.isComplete;
        _exerciseGoalLabel = defaults.exerciseGoalDays ?? '3-4 days';
        _checkInDraft = CheckInDraft.fromJson(
          daily: status.daily,
          weekly: status.weekly,
          defaultSleepHours: defaults.sleepHours(),
          hydrationPrefill: hydrationPrefill,
          exercisePrefill: exercisePrefill,
        );
        _isLoadingCheckIn = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoadingCheckIn = false;
      });
    }
  }

  Future<void> _saveCheckIn({String streakRestoreDecision = 'defer'}) async {
    final status = _checkInStatus;
    if (status == null) return;
    final missing = _checkInDraft.validationErrors(status.requiredMode);
    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please complete ${missing.join(', ')}.')),
      );
      return;
    }

    setState(() {
      _isSavingCheckIn = true;
    });

    try {
      final data = await LogApi.saveCheckIn(
        draft: _checkInDraft,
        mode: status.requiredMode,
        streakRestoreDecision: streakRestoreDecision,
      );

      if (!mounted) return;

      setState(() {
        _isEditingCheckIn = false;
        _isSavingCheckIn = false;
        final streak = data['streak'] as Map<String, dynamic>?;
        _checkInStreak = LogApi.parseInt(streak?['current_streak']);
      });
      CheckInStateCoordinator.instance.markChanged(this);

      final savedOffline = data['is_offline'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            savedOffline
                ? 'Check-in saved offline and queued to sync.'
                : status.requiredMode == CheckInMode.weekly
                ? 'Weekly pulse and today\'s check-in saved.'
                : 'Today\'s check-in saved.',
          ),
        ),
      );
      await _loadCheckInStatus();
    } on CheckInModeChangedException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSavingCheckIn = false;
      });
      await _loadCheckInStatus();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } on StreakRestoreRequiredException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSavingCheckIn = false;
      });
      final decision = await _showAssistantStreakDecision(error);
      if (decision != null && mounted) {
        await _saveCheckIn(streakRestoreDecision: decision);
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSavingCheckIn = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to save check-in: ${error.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  Future<String?> _showAssistantStreakDecision(
    StreakRestoreRequiredException error,
  ) {
    final available = LogApi.parseInt(error.restore['available_savers']);
    final required = LogApi.parseInt(error.restore['savers_required']);
    final canRestore = required > 0 && available >= required;
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Save today\'s check-in?'),
        content: Text(
          canRestore
              ? 'Use $required streak saver${required == 1 ? '' : 's'} to protect your streak, or save without restoring it.'
              : 'Your check-in can still be saved, but the missed days cannot be restored with the savers currently available.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, 'skip'),
            child: const Text('Save without restoring'),
          ),
          if (canRestore)
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, 'use'),
              child: const Text('Use savers and save'),
            ),
        ],
      ),
    );
  }

  Future<void> _chooseExercise(
    ExerciseRecommendationModel recommendation,
  ) async {
    final goal = await ExerciseGoalService.instance.chooseExercise(
      recommendation,
    );
    var appliedToLog = false;
    var queuedForLog = false;
    var checkInRequired = false;

    try {
      final result = await LogApi.applyExerciseGoalSelection(goal);
      appliedToLog = result['exercise_applied_to_log'] == true;
      queuedForLog = result['exercise_applied_to_log'] == false;
      checkInRequired = result['check_in_required'] == true;
    } catch (_) {
      // The goal itself is still saved through the exercise goal service.
    }

    if (!mounted) return;

    final exerciseName = LogApi.normalizeExerciseNameForLog(goal.exerciseName);
    var snackBarMessage = '${goal.exerciseName} saved as today\'s goal.';
    if (goal.isNoneToday) {
      snackBarMessage = 'Rest choice saved for today.';
      if (appliedToLog) {
        snackBarMessage += ' Today\'s log now shows None.';
      } else if (queuedForLog) {
        snackBarMessage += ' None will prefill the log page.';
      }
    } else if (appliedToLog) {
      snackBarMessage += ' $exerciseName also updated today\'s log.';
    } else if (queuedForLog) {
      snackBarMessage += checkInRequired
          ? ' $exerciseName will prefill the pending weekly pulse.'
          : ' $exerciseName will prefill the log page.';
    }

    if (queuedForLog) {
      unawaited(_loadCheckInStatus());
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(snackBarMessage)));

    _pageController.animateToPage(
      _assistantExerciseSectionIndex,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _completeGoal() async {
    await ExerciseGoalService.instance.completeGoal();
    final goal = ExerciseGoalService.instance.notifier.value.goal;
    if (goal == null || goal.isNoneToday) {
      return;
    }

    try {
      await LogApi.applyExerciseGoalSelection(goal);
    } catch (_) {
      // Completion stays cached in the exercise goal service if log sync fails.
    }
  }

  void _redoCheckIn() {
    setState(() {
      _isEditingCheckIn = true;
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
    final maxHeight =
        MediaQuery.sizeOf(context).height *
        (widget.useSafeAreaPadding ? 0.9 : 1.0);
    final sections = _sections();
    final currentIndex = min(_pageIndex, sections.length - 1);
    final panel = Padding(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        bottom: widget.useSafeAreaPadding
            ? MediaQuery.viewInsetsOf(context).bottom + 12
            : 0,
      ),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            const SizedBox(height: 8),
            ValueListenableBuilder<ActivityTrackingState>(
              valueListenable: ActivityService.instance.notifier,
              builder: (context, activityState, _) {
                return _AssistantContextStrip(
                  activityState: activityState,
                  environmentSnapshot: _environmentSnapshot,
                  isLoadingEnvironment: _isLoadingEnvironment,
                  onRefreshEnvironment: _loadEnvironment,
                );
              },
            ),
            const SizedBox(height: 10),
            _AssistantSectionNavigator(
              sections: sections,
              currentIndex: currentIndex,
              onSelected: _selectPage,
            ),
            const SizedBox(height: 8),
            Flexible(
              child: PageView(
                controller: _pageController,
                allowImplicitScrolling: true,
                physics: const PageScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                onPageChanged: (index) {
                  setState(() {
                    _pageIndex = index;
                  });
                },
                children: List.generate(sections.length, (index) {
                  final section = sections[index];
                  return Scrollbar(
                    controller: _sectionScrollControllers[index],
                    radius: const Radius.circular(999),
                    child: SingleChildScrollView(
                      controller: _sectionScrollControllers[index],
                      key: PageStorageKey<String>(section.label),
                      primary: false,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: const EdgeInsets.only(right: 2, bottom: 4),
                      child: section.child,
                    ),
                  );
                }),
              ),
            ),
            if (_showHydrationLogger) ...[
              const SizedBox(height: 10),
              _AssistantHydrationQuickLogSection(
                amountLiters: _quickHydrationAmount,
                todayHydrationLiters: _todayHydrationLiters,
                hasTodayLog: _hasTodayHydrationLog,
                isLoading: _isLoadingHydrationContext,
                isSaving: _isSavingHydration,
                helperText: _hydrationHelperText,
                onAmountChanged: (value) {
                  setState(() {
                    _quickHydrationAmount = value;
                    _hydrationHelperText = null;
                  });
                },
                onSave: _saveHydration,
                onOpenLog: _openLogPage,
              ),
            ],
            const SizedBox(height: 10),
            _AssistantQuickLogBar(
              isHydrationOpen: _showHydrationLogger,
              onLogWater: _openHydrationLogger,
              onLogMeal: _openMealLog,
            ),
          ],
        ),
      ),
    );

    if (!widget.useSafeAreaPadding) {
      return panel;
    }

    return SafeArea(child: panel);
  }

  Widget _buildHeader(BuildContext context) {
    final isRefreshing =
        _isLoadingAdaptiveNudges ||
        _isLoadingNutritionInsight ||
        _isLoadingRecommendations ||
        _isLoadingEnvironment ||
        _isLoadingCheckIn;

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color.fromARGB(255, 121, 73, 223), Color(0xFF59B7EF)],
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
            'VitalySync assistant',
            style: TextStyle(
              color: pagePrimaryTextColor(context),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Refresh assistant',
          onPressed: () {
            unawaited(_loadAdaptiveNudges(forceRefresh: true));
            unawaited(_loadNutritionInsight(forceRefresh: true));
            unawaited(_loadRecommendations());
            unawaited(_loadEnvironment());
            unawaited(_loadFirstWeekLearning());
            unawaited(_loadCheckInStatus());
            if (_showHydrationLogger) {
              unawaited(_loadHydrationContext());
            }
          },
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: isRefreshing
                ? const SizedBox(
                    key: ValueKey('assistant-refreshing'),
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : const Icon(
                    Icons.refresh_rounded,
                    key: ValueKey('assistant-refresh'),
                  ),
          ),
        ),
        IconButton(
          tooltip: 'Close',
          onPressed: widget.onClose ?? () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }

  List<_AssistantSection> _sections() {
    return [
      _AssistantSection(
        icon: Icons.auto_awesome_rounded,
        label: 'Nudges',
        child: _SmartNudgeDialogCard(
          emoji: widget.emoji,
          message: widget.message,
          recommendations: _adaptiveNudges,
          nutritionInsight: _nutritionInsight,
          firstWeekLearning: _firstWeekLearning,
          isLoading: _isLoadingAdaptiveNudges,
          isNutritionLoading: _isLoadingNutritionInsight,
          onStatusChanged: _handleNudgeStatus,
          onNutritionStatusChanged: _handleNutritionInsightStatus,
        ),
      ),
      _AssistantSection(
        icon: Icons.fact_check_rounded,
        label: _checkInStatus?.requiredMode == CheckInMode.weekly
            ? 'Pulse'
            : 'Check-in',
        child: _buildCheckInPage(),
      ),
      _AssistantSection(
        icon: Icons.directions_run_rounded,
        label: 'Exercise',
        child: _buildExercisePage(),
      ),
    ];
  }

  void _selectPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildExercisePage() {
    return ValueListenableBuilder<ExerciseGoalState>(
      valueListenable: ExerciseGoalService.instance.notifier,
      builder: (context, goalState, _) {
        final goal = goalState.goal;
        final hasGoal = goal != null && goal.hasSelectedGoal;

        if (!hasGoal && _isLoadingRecommendations) {
          return const _AssistantLoadingCard();
        }

        if (!hasGoal) {
          return AssistantExerciseCard(
            recommendations: _recommendations,
            isSaving: goalState.isSaving,
            onChoose: _chooseExercise,
          );
        }

        return ValueListenableBuilder<ActivityTrackingState>(
          valueListenable: ActivityService.instance.notifier,
          builder: (context, activityState, _) {
            return SelectedExerciseGoalCard(
              goal: goal,
              distanceMeters: activityState.log.distanceMeters,
              isSaving: goalState.isSaving,
              onDone: _completeGoal,
              onCancel: _cancelGoal,
            );
          },
        );
      },
    );
  }

  Widget _buildCheckInPage() {
    return _AssistantCheckInCard(
      isLoading: _isLoadingCheckIn,
      isSaving: _isSavingCheckIn,
      status: _checkInStatus,
      draft: _checkInDraft,
      isEditing: _isEditingCheckIn,
      currentStreak: _checkInStreak,
      exerciseGoalLabel: _exerciseGoalLabel,
      onChanged: (draft) {
        setState(() {
          _checkInDraft = draft;
        });
      },
      onSave: _saveCheckIn,
      onRedo: _redoCheckIn,
    );
  }
}

class _AssistantSection {
  final IconData icon;
  final String label;
  final Widget child;

  const _AssistantSection({
    required this.icon,
    required this.label,
    required this.child,
  });
}

class _AssistantSectionNavigator extends StatelessWidget {
  final List<_AssistantSection> sections;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  const _AssistantSectionNavigator({
    required this.sections,
    required this.currentIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highlightColor = isDark
        ? const Color.fromARGB(255, 28, 19, 98)
        : const Color.fromARGB(255, 243, 204, 107);

    return SizedBox(
      height: 42,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: List.generate(sections.length, (index) {
                  final section = sections[index];
                  final selected = index == currentIndex;
                  final foreground = selected
                      ? Colors.white
                      : pagePrimaryTextColor(context);
                  final background = selected
                      ? highlightColor
                      : pageSurfaceColor(context);

                  return Padding(
                    padding: EdgeInsets.only(
                      right: index == sections.length - 1 ? 0 : 8,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? highlightColor
                              : pageBorderColor(context),
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => onSelected(index),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(section.icon, size: 17, color: foreground),
                              const SizedBox(width: 6),
                              Text(
                                section.label,
                                style: TextStyle(
                                  color: foreground,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AssistantContextStrip extends StatelessWidget {
  final ActivityTrackingState activityState;
  final EnvironmentSnapshot? environmentSnapshot;
  final bool isLoadingEnvironment;
  final VoidCallback onRefreshEnvironment;

  const _AssistantContextStrip({
    required this.activityState,
    required this.environmentSnapshot,
    required this.isLoadingEnvironment,
    required this.onRefreshEnvironment,
  });

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.decimalPattern();
    final weatherText = _weatherText();
    final airText = environmentSnapshot == null
        ? 'Air quality pending'
        : 'AQI ${environmentSnapshot!.airQuality.aqi} ${environmentSnapshot!.airQuality.aqiLabel}';
    final dailyStepsUnavailable = !activityState.isStepTrackingSupported;
    final stepLabel = dailyStepsUnavailable
        ? 'Daily steps unavailable'
        : activityState.isTracking
        ? 'Live steps'
        : activityState.permissionGranted
        ? 'Steps cached'
        : 'Step access needed';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFEAF8F1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: pageBorderColor(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _AssistantContextMetric(
              icon: Icons.wb_sunny_rounded,
              label: isLoadingEnvironment ? 'Weather loading' : weatherText,
              value: airText,
              isLoading: isLoadingEnvironment,
            ),
          ),
          Container(
            width: 1,
            height: 34,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: pageBorderColor(context),
          ),
          Expanded(
            child: _AssistantContextMetric(
              icon: Icons.directions_walk_rounded,
              label: stepLabel,
              value: dailyStepsUnavailable
                  ? null
                  : '${numberFormat.format(activityState.log.steps)} steps',
              isLoading: !dailyStepsUnavailable && activityState.isLoading,
            ),
          ),
          SizedBox(
            width: 34,
            height: 34,
            child: IconButton(
              tooltip: 'Refresh weather',
              onPressed: isLoadingEnvironment ? null : onRefreshEnvironment,
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.refresh_rounded, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  String _weatherText() {
    final snapshot = environmentSnapshot;
    if (snapshot == null) {
      return 'Weather pending';
    }

    return '${snapshot.weather.description}, ${snapshot.weather.temperatureC.toStringAsFixed(0)}\u00B0C';
  }
}

class _AssistantContextMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final bool isLoading;

  const _AssistantContextMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      enabled: isLoading,
      ignorePointers: false,
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFF1FB489).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 17, color: const Color(0xFF1FB489)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: pagePrimaryTextColor(context),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (value != null && value!.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: pageSecondaryTextColor(context),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
