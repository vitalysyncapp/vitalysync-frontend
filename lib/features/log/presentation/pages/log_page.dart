import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/app_bar.dart';
import '../../../../shared/widgets/app_skeleton.dart';
import '../../../../shared/widgets/reveal_on_build.dart';
import '../../../onboarding/services/onboarding_service.dart';
import '../../../streaks/data/streak_models.dart';
import '../../data/log_api.dart';
import '../widgets/log_widgets.dart';

const _streakFireAnimationPath = 'assets/animations/streak_fire.json';
const _healthyHeartAnimationPath = 'assets/animations/healthy_heart.json';
const _wellnessConfettiColors = [
  Color(0xFF1FB489),
  Color(0xFF56CCF2),
  Color(0xFFFACC15),
  Color(0xFFFF8A4C),
  Color(0xFFE879F9),
];

@immutable
class LogNavigationState {
  final bool isLoading;
  final bool hasLoggedToday;
  final bool isSaving;
  final bool isFormVisible;

  const LogNavigationState({
    this.isLoading = true,
    this.hasLoggedToday = false,
    this.isSaving = false,
    this.isFormVisible = false,
  });

  bool get canSave => !isLoading && !isSaving && isFormVisible;
}

class LogPageController extends ValueNotifier<LogNavigationState> {
  LogPageController() : super(const LogNavigationState());

  Future<void> Function()? _saveAction;

  void bindSaveAction(Future<void> Function() saveAction) {
    _saveAction = saveAction;
  }

  void unbindSaveAction(Future<void> Function() saveAction) {
    if (_saveAction == saveAction) {
      _saveAction = null;
    }
  }

  void updateState({
    required bool isLoading,
    required bool hasLoggedToday,
    required bool isSaving,
    required bool isFormVisible,
  }) {
    final current = value;
    if (current.isLoading == isLoading &&
        current.hasLoggedToday == hasLoggedToday &&
        current.isSaving == isSaving &&
        current.isFormVisible == isFormVisible) {
      return;
    }
    value = LogNavigationState(
      isLoading: isLoading,
      hasLoggedToday: hasLoggedToday,
      isSaving: isSaving,
      isFormVisible: isFormVisible,
    );
  }

  Future<void> save() async {
    final saveAction = _saveAction;
    if (!value.canSave || saveAction == null) {
      return;
    }
    await saveAction();
  }
}

class LogPage extends StatefulWidget {
  final LogPageController? controller;

  const LogPage({super.key, this.controller});

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> with WidgetsBindingObserver {
  int currentStreak = 0;
  double sleepHours = 7;
  int sleepQuality = 2;
  int moodIndex = 3;
  int? energyLevel;
  double hydration = 0.5;
  String workloadHoursBand = 'None';
  int? perceivedStressLevel;
  int? breakQualityLevel;
  int? dailyDetachmentLevel;
  int? dailyFocusLevel;
  int? dailyAccomplishmentLevel;
  double defaultSleepHours = 7;
  String exerciseGoalLabel = '3–4 days';
  int? workloadContext;

  final Set<String> selectedExercises = {};
  final Set<String> selectedSymptoms = {};
  final Set<String> selectedHabits = {};

  final List<String> sleepLabels = [
    'Poor',
    'Fair',
    'Good',
    'Very good',
    'Excellent',
  ];

  final List<int> sleepStars = [1, 2, 3, 4, 5];

  final List<String> moods = [
    '\u{1F61E}',
    '\u{1F641}',
    '\u{1F610}',
    '\u{1F642}',
    '\u{1F60A}',
  ];

  final List<String> exercises = LogApi.exerciseOptions;

  final List<String> symptoms = [
    'Headache',
    'Fatigue',
    'Irritability',
    'Anxiety',
    'Body pain',
    'Back pain',
    'None',
  ];

  final List<String> habits = [
    'Quiet break',
    'Sunlight or fresh air',
    'Less screen time',
    'Balanced meal',
    'Talked with someone',
    'None',
  ];

  bool isSubmitted = false;
  bool isLoading = true;
  bool hasSavedLogToday = false;
  bool isSaving = false;
  bool hasPendingSync = false;
  bool lastSaveWasOffline = false;
  int pendingSyncCount = 0;

  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller?.bindSaveAction(_saveLog);
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _publishNavigationState();
    _loadLogState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller?.unbindSaveAction(_saveLog);
    _confettiController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant LogPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }
    oldWidget.controller?.unbindSaveAction(_saveLog);
    widget.controller?.bindSaveAction(_saveLog);
    _publishNavigationState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadLogState(showLoader: false);
    }
  }

  Future<void> _loadLogState({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() {
        isLoading = true;
      });
      _publishNavigationState();
    }

    try {
      final defaults = await OnboardingService.loadDefaults();
      final data = await LogApi.fetchTodayLog();
      final hydrationPrefill = await LogApi.readHydrationPrefill();
      final exercisePrefill = await LogApi.readExercisePrefill();
      final streak = data['streak'] as Map<String, dynamic>?;
      final hasLog = data['has_log'] == true;
      final pendingCount = LogApi.parseInt(data['pending_sync_count']);

      if (!mounted) return;

      setState(() {
        currentStreak = LogApi.parseInt(streak?['current_streak']);
        defaultSleepHours = defaults.sleepHours();
        exerciseGoalLabel = defaults.exerciseGoalDays ?? '3–4 days';
        workloadContext = defaults.workloadLevel;
        hasSavedLogToday = hasLog;
        isSubmitted = hasLog;
        hasPendingSync = pendingCount > 0;
        lastSaveWasOffline = data['is_offline'] == true && pendingCount > 0;
        pendingSyncCount = pendingCount;
        isLoading = false;
      });
      _publishNavigationState();

      if (hasLog) {
        _populateFromLog(data['log'] as Map<String, dynamic>);
      } else {
        setState(() {
          _resetForm(
            hydrationPrefill: hydrationPrefill,
            exercisePrefill: exercisePrefill,
          );
        });
      }

      await refreshAppBarStreak();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
      _publishNavigationState();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load today\'s log: $error')),
      );
    }
  }

  void _publishNavigationState() {
    widget.controller?.updateState(
      isLoading: isLoading,
      hasLoggedToday: hasSavedLogToday,
      isSaving: isSaving,
      isFormVisible: !isLoading && !isSubmitted,
    );
  }

  void _populateFromLog(Map<String, dynamic> log) {
    setState(() {
      sleepHours = LogApi.parseDouble(log['sleep_hours'], fallback: 7);
      sleepQuality = LogApi.parseInt(log['sleep_quality'], fallback: 2);
      moodIndex = LogApi.parseInt(log['mood_index'], fallback: 3);
      energyLevel = LogApi.parseEnergyLevel(log['energy_level']);
      hydration = LogApi.parseDouble(log['hydration_liters'], fallback: 0.5);
      workloadHoursBand =
          LogApi.normalizeWorkloadHoursBand(log['workload_hours_band']) ??
          'None';
      perceivedStressLevel = LogApi.parseLikert(log['perceived_stress_level']);
      breakQualityLevel = LogApi.parseLikert(log['break_quality_level']);
      dailyDetachmentLevel = LogApi.parseLikert(log['daily_detachment_level']);
      dailyFocusLevel = LogApi.parseLikert(log['daily_focus_level']);
      dailyAccomplishmentLevel = LogApi.parseLikert(
        log['daily_accomplishment_level'],
      );
      selectedExercises
        ..clear()
        ..addAll(
          ((log['exercise_names'] as List<dynamic>? ?? const []).map(
            (item) => item.toString(),
          )),
        );
      selectedSymptoms
        ..clear()
        ..addAll(
          ((log['symptom_names'] as List<dynamic>? ?? const []).map(
            (item) => item.toString(),
          )),
        );
      selectedHabits
        ..clear()
        ..addAll(
          ((log['habit_names'] as List<dynamic>? ?? const []).map(
            (item) => _readableHabitName(item.toString()),
          )),
        );
    });
  }

  String _readableHabitName(String habit) {
    switch (habit) {
      case 'Mindful break':
        return 'Quiet break';
      case 'Outdoor light':
        return 'Sunlight or fresh air';
      case 'Screen boundary':
        return 'Less screen time';
      case 'Healthy meal':
        return 'Balanced meal';
      case 'Social connection':
        return 'Talked with someone';
      default:
        return habit;
    }
  }

  bool _validateLog() {
    if (hydration <= 0) return false;
    if (energyLevel == null) return false;
    if (workloadHoursBand.isEmpty) return false;
    if (perceivedStressLevel == null) return false;
    if (breakQualityLevel == null) return false;
    if (dailyDetachmentLevel == null) return false;
    if (dailyFocusLevel == null) return false;
    if (dailyAccomplishmentLevel == null) return false;
    if (selectedExercises.isEmpty) return false;
    if (selectedSymptoms.isEmpty) return false;
    if (selectedHabits.isEmpty) return false;
    return true;
  }

  Future<void> _saveLog({String streakRestoreDecision = 'defer'}) async {
    if (!_validateLog()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please complete all daily dimension questions, hydration, workload, exercise, symptoms, and recovery habits before saving.',
          ),
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });
    _publishNavigationState();

    try {
      final data = await LogApi.saveDailyLog(
        sleepHours: sleepHours,
        sleepQuality: sleepQuality,
        moodIndex: moodIndex,
        energyLevel: energyLevel!,
        hydrationLiters: hydration,
        workloadHoursBand: workloadHoursBand,
        perceivedStressLevel: perceivedStressLevel!,
        breakQualityLevel: breakQualityLevel,
        dailyDetachmentLevel: dailyDetachmentLevel!,
        dailyFocusLevel: dailyFocusLevel!,
        dailyAccomplishmentLevel: dailyAccomplishmentLevel!,
        exerciseNames: selectedExercises.toList()..sort(),
        symptomNames: selectedSymptoms.toList()..sort(),
        habitNames: selectedHabits.toList()..sort(),
        streakRestoreDecision: streakRestoreDecision,
      );

      final streak = data['streak'] as Map<String, dynamic>?;
      final pendingCount = LogApi.parseInt(data['pending_sync_count']);
      final savedOffline = data['is_offline'] == true;

      if (!mounted) return;

      setState(() {
        currentStreak = LogApi.parseInt(streak?['current_streak']);
        hasSavedLogToday = true;
        isSubmitted = true;
        hasPendingSync = pendingCount > 0;
        lastSaveWasOffline = savedOffline;
        pendingSyncCount = pendingCount;
        isSaving = false;
      });
      _publishNavigationState();

      await refreshAppBarStreak();
      if (!mounted) return;

      _confettiController.play();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            savedOffline
                ? 'Saved offline. $pendingCount check-in${pendingCount == 1 ? '' : 's'} waiting to sync.'
                : 'Daily check-in synced successfully.',
          ),
        ),
      );
    } on StreakRestoreRequiredException catch (error) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });
      _publishNavigationState();

      final decision = await _showStreakRestoreDialog(
        StreakRestoreDetails.fromJson(error.restore),
      );
      if (decision != null && mounted) {
        await _saveLog(streakRestoreDecision: decision);
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });
      _publishNavigationState();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to save log: $error')));
    }
  }

  Future<String?> _showStreakRestoreDialog(StreakRestoreDetails details) async {
    final missingDays = details.missingDays <= 0
        ? details.missingDates.length
        : details.missingDays;
    final saversRequired = details.saversRequired <= 0
        ? missingDays
        : details.saversRequired;
    final canRestore = details.availableSavers >= saversRequired;

    return showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final primaryText = pagePrimaryTextColor(context);
        final secondaryText = pageSecondaryTextColor(context);
        final accent = canRestore
            ? const Color(0xFFFF8A1F)
            : const Color(0xFFE5484D);

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF132235).withValues(alpha: 0.98)
                    : Colors.white.withValues(alpha: 0.98),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: pageBorderColor(context)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.34 : 0.14),
                    blurRadius: 28,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: isDark ? 0.2 : 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      canRestore
                          ? Icons.local_fire_department_rounded
                          : Icons.warning_amber_rounded,
                      color: accent,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    canRestore ? 'Restore your streak?' : 'Savers unavailable',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: primaryText,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    canRestore
                        ? 'You missed $missingDays day${missingDays == 1 ? '' : 's'}. Use $saversRequired streak saver${saversRequired == 1 ? '' : 's'} to protect your streak before saving today.'
                        : 'You need $saversRequired saver${saversRequired == 1 ? '' : 's'}, but only have ${details.availableSavers}. You can still save today and start a fresh streak.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: secondaryText,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.055)
                          : const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: accent.withValues(alpha: isDark ? 0.22 : 0.18),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.shield_outlined, color: accent, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${details.availableSavers} saver${details.availableSavers == 1 ? '' : 's'} available this month',
                            style: TextStyle(
                              color: primaryText,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (canRestore)
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context, 'use'),
                          icon: const Icon(Icons.shield_rounded),
                          label: Text(
                            'Use $saversRequired saver${saversRequired == 1 ? '' : 's'} and save',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      if (canRestore) const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context, 'skip'),
                        icon: const Icon(Icons.restart_alt_rounded),
                        label: const Text('Save without restoring'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryText,
                          side: BorderSide(color: pageBorderColor(context)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Not now'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _redoLog() {
    setState(() {
      isSubmitted = false;
    });
    _publishNavigationState();
  }

  void _resetForm({double hydrationPrefill = 0, String? exercisePrefill}) {
    sleepHours = defaultSleepHours;
    sleepQuality = 2;
    moodIndex = 3;
    energyLevel = null;
    hydration = hydrationPrefill > 0
        ? hydrationPrefill.clamp(0, 10).toDouble()
        : 0.5;
    workloadHoursBand = 'None';
    perceivedStressLevel = null;
    breakQualityLevel = null;
    dailyDetachmentLevel = null;
    dailyFocusLevel = null;
    dailyAccomplishmentLevel = null;
    selectedExercises.clear();
    final normalizedExercisePrefill = exercisePrefill == null
        ? null
        : LogApi.normalizeExerciseNameForLog(exercisePrefill);
    if (normalizedExercisePrefill != null &&
        normalizedExercisePrefill.isNotEmpty) {
      selectedExercises.add(normalizedExercisePrefill);
    }
    selectedSymptoms.clear();
    selectedHabits.clear();
  }

  void _toggleExercise(String exercise) {
    setState(() {
      if (exercise == 'None') {
        if (selectedExercises.contains('None')) {
          selectedExercises.remove('None');
        } else {
          selectedExercises
            ..clear()
            ..add('None');
        }
      } else {
        selectedExercises.remove('None');
        if (selectedExercises.contains(exercise)) {
          selectedExercises.remove(exercise);
        } else {
          selectedExercises.add(exercise);
        }
      }
    });
  }

  void _toggleSymptom(String symptom) {
    setState(() {
      if (symptom == 'None') {
        if (selectedSymptoms.contains('None')) {
          selectedSymptoms.remove('None');
        } else {
          selectedSymptoms
            ..clear()
            ..add('None');
        }
      } else {
        selectedSymptoms.remove('None');
        if (selectedSymptoms.contains(symptom)) {
          selectedSymptoms.remove(symptom);
        } else {
          selectedSymptoms.add(symptom);
        }
      }
    });
  }

  void _toggleHabit(String habit) {
    setState(() {
      if (habit == 'None') {
        if (selectedHabits.contains('None')) {
          selectedHabits.remove('None');
        } else {
          selectedHabits
            ..clear()
            ..add('None');
        }
      } else {
        selectedHabits.remove('None');
        if (selectedHabits.contains(habit)) {
          selectedHabits.remove(habit);
        } else {
          selectedHabits.add(habit);
        }
      }
    });
  }

  void _showLogScoringInfo() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _LogScoringInfoSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: buildPageDecoration(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: isLoading
              ? AppSkeletonList(
                  padding: EdgeInsets.fromLTRB(
                    12,
                    10,
                    12,
                    mainPageBottomContentPadding(context),
                  ),
                  cardHeights: const [104, 178, 178, 152, 118],
                )
              : Stack(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: isSubmitted
                          ? _buildSuccessScreen()
                          : SingleChildScrollView(
                              key: const ValueKey('log_form'),
                              padding: EdgeInsets.fromLTRB(
                                12,
                                10,
                                12,
                                mainPageBottomContentPadding(context),
                              ),
                              child: Column(
                                children: [
                                  RevealOnBuild(child: _buildLogHeader()),
                                  const SizedBox(height: 12),
                                  RevealOnBuild(
                                    delay: const Duration(milliseconds: 90),
                                    child: LogWidgets(
                                      sleepHours: sleepHours,
                                      sleepQuality: sleepQuality,
                                      moodIndex: moodIndex,
                                      energyLevel: energyLevel,
                                      hydration: hydration,
                                      workloadHoursBand: workloadHoursBand,
                                      perceivedStressLevel:
                                          perceivedStressLevel,
                                      breakQualityLevel: breakQualityLevel,
                                      dailyDetachmentLevel:
                                          dailyDetachmentLevel,
                                      dailyFocusLevel: dailyFocusLevel,
                                      dailyAccomplishmentLevel:
                                          dailyAccomplishmentLevel,
                                      selectedExercises: selectedExercises,
                                      selectedSymptoms: selectedSymptoms,
                                      selectedHabits: selectedHabits,
                                      sleepLabels: sleepLabels,
                                      sleepStars: sleepStars,
                                      moods: moods,
                                      exercises: exercises,
                                      symptoms: symptoms,
                                      habits: habits,
                                      exerciseGoalLabel: exerciseGoalLabel,
                                      workloadOptions:
                                          LogApi.workloadHoursBandOptions,
                                      onSleepChanged: (value) {
                                        setState(() {
                                          sleepHours = value;
                                        });
                                      },
                                      onSleepQualityChanged: (value) {
                                        setState(() {
                                          sleepQuality = value;
                                        });
                                      },
                                      onMoodChanged: (value) {
                                        setState(() {
                                          moodIndex = value;
                                        });
                                      },
                                      onEnergyChanged: (value) {
                                        setState(() {
                                          energyLevel = value;
                                        });
                                      },
                                      onHydrationAdd: (value) {
                                        setState(() {
                                          hydration = (hydration + value).clamp(
                                            0,
                                            10,
                                          );
                                        });
                                      },
                                      onHydrationSubtract: () {
                                        setState(() {
                                          hydration = (hydration - 0.25).clamp(
                                            0,
                                            10,
                                          );
                                        });
                                      },
                                      onHydrationReset: () {
                                        setState(() {
                                          hydration = 0;
                                        });
                                      },
                                      onWorkloadChanged: (value) {
                                        setState(() {
                                          workloadHoursBand = value;
                                        });
                                      },
                                      onPerceivedStressChanged: (value) {
                                        setState(() {
                                          perceivedStressLevel = value;
                                        });
                                      },
                                      onBreakQualityChanged: (value) {
                                        setState(() {
                                          breakQualityLevel = value;
                                        });
                                      },
                                      onDailyDetachmentChanged: (value) {
                                        setState(() {
                                          dailyDetachmentLevel = value;
                                        });
                                      },
                                      onDailyFocusChanged: (value) {
                                        setState(() {
                                          dailyFocusLevel = value;
                                        });
                                      },
                                      onDailyAccomplishmentChanged: (value) {
                                        setState(() {
                                          dailyAccomplishmentLevel = value;
                                        });
                                      },
                                      onExerciseToggle: _toggleExercise,
                                      onSymptomToggle: _toggleSymptom,
                                      onHabitToggle: _toggleHabit,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  RevealOnBuild(
                                    delay: const Duration(milliseconds: 180),
                                    child: _buildSaveButton(),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    _buildConfettiOverlay(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildConfettiOverlay() {
    return IgnorePointer(
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.045,
              numberOfParticles: 18,
              maxBlastForce: 22,
              minBlastForce: 7,
              gravity: 0.2,
              colors: _wellnessConfettiColors,
              createParticlePath: _drawHeartParticle,
              shouldLoop: false,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 0,
              emissionFrequency: 0.026,
              numberOfParticles: 8,
              maxBlastForce: 16,
              minBlastForce: 5,
              gravity: 0.16,
              colors: _wellnessConfettiColors,
              createParticlePath: _drawLeafParticle,
              shouldLoop: false,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi,
              emissionFrequency: 0.026,
              numberOfParticles: 8,
              maxBlastForce: 16,
              minBlastForce: 5,
              gravity: 0.16,
              colors: _wellnessConfettiColors,
              createParticlePath: _drawLeafParticle,
              shouldLoop: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isSaving ? null : _saveLog,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark
              ? const Color.fromARGB(255, 36, 66, 148)
              : const Color(0xFF1FB489),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                hasSavedLogToday
                    ? 'Update today\'s check-in'
                    : 'Save daily check-in',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Center(
      key: const ValueKey('success_screen'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSuccessAnimation(),
            const SizedBox(height: 18),
            Text(
              lastSaveWasOffline ? 'Check-in saved offline' : 'Check-in saved!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                color: pagePrimaryTextColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasPendingSync
                  ? 'Your daily wellness log is saved on this device. It will sync automatically when internet access is available again.'
                  : 'Your daily wellness log has been recorded. Come back tomorrow for your next check-in, or redo today\'s entry if you need to update it.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: pageSecondaryTextColor(context),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            _buildSuccessStreakBadge(),
            if (hasPendingSync) ...[
              const SizedBox(height: 12),
              _buildPendingSyncBanner(),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: _redoLog,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Redo today\'s log',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessAnimation() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.85, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: SizedBox(
        width: 104,
        height: 104,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.22),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Lottie.asset(
                _healthyHeartAnimationPath,
                width: 86,
                height: 86,
                fit: BoxFit.contain,
                repeat: true,
                animate: true,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.favorite_rounded,
                    size: 48,
                    color: Color(0xFF1FB489),
                  );
                },
              ),
            ),
            Positioned(
              right: 4,
              bottom: 6,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF1FB489),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 19,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessStreakBadge() {
    final streakText = currentStreak == 1
        ? '1 day streak'
        : '$currentStreak day streak';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFFFF8A1F).withValues(alpha: 0.12)
            : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF8A1F).withValues(alpha: 0.34),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildFireAnimation(size: 46),
          const SizedBox(height: 3),
          Text(
            streakText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFFFBBF24)
                  : const Color(0xFF7C2D12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingSyncBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_upload_outlined, color: Color(0xFF2563EB)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$pendingSyncCount pending check-in${pendingSyncCount == 1 ? '' : 's'} will upload in the background.',
              style: const TextStyle(
                color: Color(0xFF1E3A8A),
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogHeader() {
    final isCompact = MediaQuery.sizeOf(context).width < 380;

    return Padding(
      key: const ValueKey('log-header'),
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1FB489),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        'DAILY CHECK-IN',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: pageSecondaryTextColor(context),
                          fontSize: isCompact ? 9.5 : 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: isCompact ? 0.8 : 1.05,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildHeaderHelpButton(isCompact: isCompact),
              const SizedBox(width: 8),
              _buildHeaderStreakChip(isCompact: isCompact),
            ],
          ),
          SizedBox(height: isCompact ? 9 : 11),
          Text(
            'Log your day',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: isCompact ? 22 : 26,
              fontWeight: FontWeight.w800,
              height: 1.08,
              letterSpacing: -0.55,
              color: pagePrimaryTextColor(context),
            ),
          ),
          SizedBox(height: isCompact ? 4 : 5),
          Text(
            'An evening check-in works best.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: isCompact ? 12 : 13,
              fontWeight: FontWeight.w500,
              color: pageSecondaryTextColor(context),
              height: 1.35,
            ),
          ),
          SizedBox(height: isCompact ? 10 : 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildDefaultChip(
                Icons.bedtime_outlined,
                'Sleep ${defaultSleepHours.toStringAsFixed(defaultSleepHours % 1 == 0 ? 0 : 1)}h',
              ),
              _buildDefaultChip(
                Icons.fitness_center_rounded,
                'Goal $exerciseGoalLabel',
              ),
              if (workloadContext != null)
                _buildDefaultChip(
                  Icons.work_outline_rounded,
                  'Workload $workloadContext/5',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStreakChip({required bool isCompact}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final streakLabel = '$currentStreak day${currentStreak == 1 ? '' : 's'}';

    return Semantics(
      label: '$streakLabel streak',
      child: Container(
        height: isCompact ? 38 : 40,
        padding: EdgeInsets.symmetric(horizontal: isCompact ? 9 : 11),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFFFF8A1F).withValues(alpha: 0.12)
              : const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: const Color(0xFFFF8A1F).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFireAnimation(size: isCompact ? 18 : 20),
            const SizedBox(width: 5),
            Text(
              streakLabel,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: isCompact ? 11.5 : 12.5,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? const Color(0xFFFBBF24)
                    : const Color(0xFF9A3412),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderHelpButton({required bool isCompact}) {
    final primary = Theme.of(context).colorScheme.primary;

    return Tooltip(
      message: 'Log scoring guide',
      child: Semantics(
        button: true,
        label: 'Open log scoring guide',
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _showLogScoringInfo,
            customBorder: const CircleBorder(),
            child: Ink(
              width: isCompact ? 22 : 24,
              height: isCompact ? 22 : 24,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: primary.withValues(alpha: 0.18)),
              ),
              child: Icon(
                Icons.question_mark_rounded,
                size: isCompact ? 13 : 14,
                color: primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFireAnimation({required double size}) {
    return Lottie.asset(
      _streakFireAnimationPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      repeat: true,
      animate: true,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.local_fire_department_rounded,
          size: size * 0.86,
          color: const Color(0xFFFF6B35),
        );
      },
    );
  }

  Widget _buildDefaultChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFEFFAF6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: pageBorderColor(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: pagePrimaryTextColor(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogScoringInfoSheet extends StatelessWidget {
  const _LogScoringInfoSheet();

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: screenHeight * 0.84),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: pageSurfaceColor(context),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border.all(color: pageBorderColor(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.38 : 0.14),
                  blurRadius: 24,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: pageBorderColor(context),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 10, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          Icons.functions_rounded,
                          size: 21,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Log and scoring guide',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: pagePrimaryTextColor(context),
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'How today\'s answers support burnout-risk awareness.',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: pageSecondaryTextColor(context),
                                fontSize: 12.5,
                                height: 1.3,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: pageSecondaryTextColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      18,
                      4,
                      18,
                      pageBottomContentPadding(context, extra: 18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _ScoringInfoBlock(
                          icon: Icons.fact_check_outlined,
                          title: 'Log order',
                          text:
                              'Sleep duration and sleep quality are standalone recovery inputs and stay first. The three Maslach-style sections follow with four daily questionnaires each.',
                        ),
                        SizedBox(height: 10),
                        _ScoringFormulaBlock(),
                        SizedBox(height: 10),
                        _ScoringInfoBlock(
                          icon: Icons.bedtime_rounded,
                          title: 'Sleep signals',
                          text:
                              'Sleep duration uses hour-based risk bands. Sleep quality uses the 0-4 good formula. They are not direct Maslach dimension items, but they support emotional exhaustion and recovery-deficit scoring.',
                        ),
                        SizedBox(height: 10),
                        _ScoringInfoBlock(
                          icon: Icons.local_fire_department_rounded,
                          title: 'Emotional exhaustion',
                          text:
                              'Pressure, energy level, mood, and symptoms form the daily emotional-exhaustion group. Sleep, workload, and symptoms also support the backend exhaustion formula.',
                        ),
                        SizedBox(height: 10),
                        _ScoringInfoBlock(
                          icon: Icons.spa_outlined,
                          title: 'Detachment',
                          text:
                              'Daily detachment, recovery breaks, recovery habits, and hydration form the detachment group. The weekly detachment pulse still anchors the dimension score.',
                        ),
                        SizedBox(height: 10),
                        _ScoringInfoBlock(
                          icon: Icons.center_focus_strong_rounded,
                          title: 'Reduced accomplishment',
                          text:
                              'Daily focus, daily accomplishment, workload hours, and exercise form the reduced-accomplishment group. Weekly focus and accomplishment remain supporting pulse inputs.',
                        ),
                        SizedBox(height: 10),
                        _ScoringInfoBlock(
                          icon: Icons.self_improvement_rounded,
                          title: 'Recovery and workload support',
                          text:
                              'Break quality, recovery habits, hydration, exercise, activity minutes, and workload hours shape recovery deficit, workload strain, and daily functioning context.',
                        ),
                        SizedBox(height: 10),
                        _ScoringInfoBlock(
                          icon: Icons.health_and_safety_outlined,
                          title: 'Wellness framing',
                          text:
                              'This score is for risk awareness, not diagnosis. Missing values are skipped and available weights are normalized.',
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
    );
  }
}

class _ScoringFormulaBlock extends StatelessWidget {
  const _ScoringFormulaBlock();

  @override
  Widget build(BuildContext context) {
    return _ScoringInfoContainer(
      icon: Icons.calculate_outlined,
      title: 'Scoring method',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: const [
              _FormulaPill('High-risk: (value - 1) / 4 * 100'),
              _FormulaPill('High-good: (5 - value) / 4 * 100'),
              _FormulaPill('0-4 good: (4 - value) / 4 * 100'),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'The backend converts answers into 0-100 risk values, then combines them with weighted averages for each dimension.',
            style: TextStyle(
              color: pageSecondaryTextColor(context),
              fontSize: 12.5,
              height: 1.38,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoringInfoBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _ScoringInfoBlock({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return _ScoringInfoContainer(
      icon: icon,
      title: title,
      child: Text(
        text,
        style: TextStyle(
          color: pageSecondaryTextColor(context),
          fontSize: 12.5,
          height: 1.38,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ScoringInfoContainer extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _ScoringInfoContainer({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.045)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: pageBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: primary),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: pagePrimaryTextColor(context),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          child,
        ],
      ),
    );
  }
}

class _FormulaPill extends StatelessWidget {
  final String label;

  const _FormulaPill(this.label);

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: primary.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: primary,
          fontSize: 10.8,
          height: 1.2,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

Path _drawHeartParticle(Size size) {
  final width = size.width;
  final height = size.height;
  final path = Path();

  path.moveTo(width * 0.5, height * 0.92);
  path.cubicTo(
    width * 0.1,
    height * 0.62,
    0,
    height * 0.34,
    width * 0.18,
    height * 0.16,
  );
  path.cubicTo(
    width * 0.32,
    height * 0.02,
    width * 0.47,
    height * 0.08,
    width * 0.5,
    height * 0.25,
  );
  path.cubicTo(
    width * 0.53,
    height * 0.08,
    width * 0.68,
    height * 0.02,
    width * 0.82,
    height * 0.16,
  );
  path.cubicTo(
    width,
    height * 0.34,
    width * 0.9,
    height * 0.62,
    width * 0.5,
    height * 0.92,
  );
  path.close();

  return path;
}

Path _drawLeafParticle(Size size) {
  final width = size.width;
  final height = size.height;
  final path = Path();

  path.moveTo(width * 0.5, 0);
  path.cubicTo(
    width,
    height * 0.2,
    width * 0.9,
    height * 0.78,
    width * 0.5,
    height,
  );
  path.cubicTo(width * 0.1, height * 0.78, 0, height * 0.2, width * 0.5, 0);
  path.close();

  return path;
}
