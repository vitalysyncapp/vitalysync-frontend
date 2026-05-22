part of 'floating_smart_nudge_assistant.dart';

class AssistantExperiencePanel extends StatefulWidget {
  final String message;
  final String emoji;
  final List<ExerciseRecommendationModel> recommendations;
  final List<AdaptiveNudgeRecommendation> adaptiveNudges;
  final NutritionInsight? nutritionInsight;
  final Future<List<ExerciseRecommendationModel>> Function()
  onRefreshRecommendations;
  final Future<List<AdaptiveNudgeRecommendation>> Function({bool forceRefresh})
  onRefreshAdaptiveNudges;
  final Future<NutritionInsight?> Function({bool forceRefresh})
  onRefreshNutritionInsight;
  final Future<EnvironmentSnapshot?> Function() onRefreshEnvironment;
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
    required this.onRefreshRecommendations,
    required this.onRefreshAdaptiveNudges,
    required this.onRefreshNutritionInsight,
    required this.onRefreshEnvironment,
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

  late List<ExerciseRecommendationModel> _recommendations;
  late List<AdaptiveNudgeRecommendation> _adaptiveNudges;
  NutritionInsight? _nutritionInsight;
  EnvironmentSnapshot? _environmentSnapshot;
  int _pageIndex = _assistantSmartNudgeSectionIndex;
  bool _isLoadingRecommendations = false;
  bool _isLoadingAdaptiveNudges = false;
  bool _isLoadingNutritionInsight = false;
  bool _isLoadingEnvironment = false;
  bool _isLoadingWeeklyPulse = true;
  bool _isSavingWeeklyPulse = false;
  bool _showHydrationLogger = false;
  bool _isLoadingHydrationContext = false;
  bool _isSavingHydration = false;
  bool _hasTodayHydrationLog = false;
  double _quickHydrationAmount = 0.25;
  double _todayHydrationLiters = 0;
  String? _hydrationHelperText;
  bool _hasWeeklyPulseResponse = false;
  bool _isEditingWeeklyPulse = false;
  int? _productivityFocusLevel;
  int? _recoveryRestLevel;
  int? _detachmentLevel;
  int? _accomplishmentLevel;

  @override
  void initState() {
    super.initState();
    _pageIndex = widget.initialSectionIndex;
    _pageController = PageController(initialPage: _pageIndex);
    _recommendations = widget.recommendations;
    _adaptiveNudges = prioritizeAssistantNudges(widget.adaptiveNudges);
    _nutritionInsight = widget.nutritionInsight;
    if (_recommendations.isEmpty) {
      unawaited(_loadRecommendations());
    }
    if (_adaptiveNudges.isEmpty) {
      unawaited(_loadAdaptiveNudges());
    }
    if (_nutritionInsight == null) {
      unawaited(_loadNutritionInsight());
    }
    unawaited(_loadEnvironment());
    unawaited(_loadWeeklyPulseStatus());
  }

  @override
  void didUpdateWidget(covariant AssistantExperiencePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.recommendations, widget.recommendations) &&
        widget.recommendations.isNotEmpty) {
      _recommendations = widget.recommendations;
    }
    if (!identical(oldWidget.adaptiveNudges, widget.adaptiveNudges) &&
        widget.adaptiveNudges.isNotEmpty) {
      _adaptiveNudges = prioritizeAssistantNudges(widget.adaptiveNudges);
    }
    if (oldWidget.nutritionInsight != widget.nutritionInsight &&
        widget.nutritionInsight != null) {
      _nutritionInsight = widget.nutritionInsight;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

  Future<void> _handleNudgeStatus(
    AdaptiveNudgeRecommendation recommendation,
    String status,
  ) async {
    await AdaptiveNudgeApi.saveNudgeFeedback(
      recommendation: recommendation,
      status: status,
    );

    if (!mounted) return;

    final label = status == 'dismissed' ? 'Insight hidden.' : 'Saved to likes.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(label)));
  }

  Future<void> _handleNutritionInsightStatus(
    NutritionInsight insight,
    String status,
  ) async {
    await NutritionInsightStore.instance.saveFeedbackStatus(insight.id, status);
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

    final label = status == 'dismissed'
        ? 'Nutrition insight hidden.'
        : 'Nutrition insight liked.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(label)));
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
            : 'No daily check-in yet. I prefilled this for the Log page.';
      });
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
    var appliedToLog = false;
    var queuedForLog = false;

    try {
      final result = await LogApi.applyExerciseGoalSelection(goal);
      appliedToLog = result['exercise_applied_to_log'] == true;
      queuedForLog = result['exercise_applied_to_log'] == false;
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
        snackBarMessage += ' None will prefill the Log page.';
      }
    } else if (appliedToLog) {
      snackBarMessage += ' $exerciseName also updated today\'s log.';
    } else if (queuedForLog) {
      snackBarMessage += ' $exerciseName will prefill the Log page.';
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
    final maxHeight =
        MediaQuery.sizeOf(context).height *
        (widget.useSafeAreaPadding ? 0.78 : 1.0);
    final sections = _sections();
    final currentIndex = min(_pageIndex, sections.length - 1);
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            const SizedBox(height: 10),
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
            const SizedBox(height: 12),
            _AssistantSectionNavigator(
              sections: sections,
              currentIndex: currentIndex,
              onSelected: _selectPage,
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
                children: sections
                    .map(
                      (section) => SingleChildScrollView(
                        key: PageStorageKey<String>(section.label),
                        child: section.child,
                      ),
                    )
                    .toList(),
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
            'VitalySync Assistant',
            style: TextStyle(
              color: pagePrimaryTextColor(context),
              fontSize: 18,
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
            if (_showHydrationLogger) {
              unawaited(_loadHydrationContext());
            }
          },
          icon: const Icon(Icons.refresh_rounded),
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
        label: 'Insights',
        child: _SmartNudgeDialogCard(
          emoji: widget.emoji,
          message: widget.message,
          recommendations: _adaptiveNudges,
          nutritionInsight: _nutritionInsight,
          isLoading: _isLoadingAdaptiveNudges,
          isNutritionLoading: _isLoadingNutritionInsight,
          onStatusChanged: _handleNudgeStatus,
          onNutritionStatusChanged: _handleNutritionInsightStatus,
        ),
      ),
      _AssistantSection(
        icon: Icons.directions_run_rounded,
        label: 'Exercise',
        child: _buildExercisePage(),
      ),
      _AssistantSection(
        icon: Icons.fact_check_rounded,
        label: 'Pulse',
        child: _buildWeeklyPulsePage(),
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

  Widget _buildWeeklyPulsePage() {
    return _WeeklyPulseCard(
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
                      ? const Color(0xFF1FB489)
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
                              ? const Color(0xFF1FB489)
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
    final stepLabel = activityState.isTracking
        ? 'Live steps'
        : activityState.permissionGranted
        ? 'Steps cached'
        : 'Step access needed';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFEAF8F1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: pageBorderColor(context)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _AssistantContextMetric(
                  icon: Icons.wb_sunny_rounded,
                  label: isLoadingEnvironment ? 'Weather loading' : weatherText,
                  value: airText,
                  isLoading: isLoadingEnvironment,
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
          const SizedBox(height: 8),
          _AssistantContextMetric(
            icon: Icons.directions_walk_rounded,
            label: stepLabel,
            value: '${numberFormat.format(activityState.log.steps)} steps',
            isLoading: activityState.isLoading,
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
  final String value;
  final bool isLoading;

  const _AssistantContextMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFF1FB489).withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(11),
          ),
          child: isLoading
              ? const Padding(
                  padding: EdgeInsets.all(7),
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon, size: 17, color: const Color(0xFF1FB489)),
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
              const SizedBox(height: 1),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: pageSecondaryTextColor(context),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
