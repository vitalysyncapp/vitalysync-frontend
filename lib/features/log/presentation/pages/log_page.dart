import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/app_bar.dart';
import '../../data/log_api.dart';
import '../widgets/LogWidgets.dart';

class LogPage extends StatefulWidget {
  const LogPage({Key? key}) : super(key: key);

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> with WidgetsBindingObserver {
  int currentStreak = 0;
  double sleepHours = 7;
  int sleepQuality = 2;
  int moodIndex = 3;
  double energyLevel = 1;
  double hydration = 1.5;

  final Set<String> selectedExercises = {};
  final Set<String> selectedSymptoms = {};

  final List<String> sleepLabels = [
    'Poor',
    'Fair',
    'Good',
    'Very Good',
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

  final List<String> exercises = [
    'Walking',
    'Running',
    'Gym',
    'Yoga',
    'Cycling',
    'Swimming',
    'None',
  ];

  final List<String> symptoms = [
    'Headache',
    'Fatigue',
    'Irritability',
    'Anxiety',
    'Body Pain',
    'Back Pain',
    'None',
  ];

  bool isSubmitted = false;
  bool isLoading = true;
  bool hasSavedLogToday = false;
  bool isSaving = false;

  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _loadLogState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _confettiController.dispose();
    super.dispose();
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
    }

    try {
      final data = await LogApi.fetchTodayLog();
      final streak = data['streak'] as Map<String, dynamic>?;
      final hasLog = data['has_log'] == true;

      if (!mounted) return;

      setState(() {
        currentStreak = LogApi.parseInt(streak?['current_streak']);
        hasSavedLogToday = hasLog;
        isSubmitted = hasLog;
        isLoading = false;
      });

      if (hasLog) {
        _populateFromLog(data['log'] as Map<String, dynamic>);
      } else {
        setState(() {
          _resetForm();
        });
      }

      await refreshAppBarStreak();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load today\'s log: $error')),
      );
    }
  }

  void _populateFromLog(Map<String, dynamic> log) {
    setState(() {
      sleepHours = LogApi.parseDouble(log['sleep_hours'], fallback: 7);
      sleepQuality = LogApi.parseInt(log['sleep_quality'], fallback: 2);
      moodIndex = LogApi.parseInt(log['mood_index'], fallback: 3);
      energyLevel = LogApi.parseDouble(log['energy_level'], fallback: 1);
      hydration = LogApi.parseDouble(log['hydration_liters'], fallback: 1.5);
      selectedExercises
        ..clear()
        ..addAll(
          ((log['exercise_names'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())),
        );
      selectedSymptoms
        ..clear()
        ..addAll(
          ((log['symptom_names'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())),
        );
    });
  }

  bool _validateLog() {
    if (hydration <= 0) return false;
    if (selectedExercises.isEmpty) return false;
    if (selectedSymptoms.isEmpty) return false;
    return true;
  }

  Future<void> _saveLog() async {
    if (!_validateLog()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please complete hydration, exercise, and symptoms before saving.',
          ),
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final data = await LogApi.saveDailyLog(
        sleepHours: sleepHours,
        sleepQuality: sleepQuality,
        moodIndex: moodIndex,
        energyLevel: energyLevel.round(),
        hydrationLiters: hydration,
        exerciseNames: selectedExercises.toList()..sort(),
        symptomNames: selectedSymptoms.toList()..sort(),
      );

      final streak = data['streak'] as Map<String, dynamic>?;

      if (!mounted) return;

      setState(() {
        currentStreak = LogApi.parseInt(streak?['current_streak']);
        hasSavedLogToday = true;
        isSubmitted = true;
        isSaving = false;
      });

      await refreshAppBarStreak();
      _confettiController.play();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save log: $error')),
      );
    }
  }

  void _redoLog() {
    setState(() {
      isSubmitted = false;
    });
  }

  void _resetForm() {
    sleepHours = 7;
    sleepQuality = 2;
    moodIndex = 3;
    energyLevel = 1;
    hydration = 1.5;
    selectedExercises.clear();
    selectedSymptoms.clear();
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: buildPageDecoration(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: buildAppBar(context),
        body: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
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
                              padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
                              child: Column(
                                children: [
                                  _buildLogHeaderCard(),
                                  const SizedBox(height: 18),
                                  LogWidgets(
                                    sleepHours: sleepHours,
                                    sleepQuality: sleepQuality,
                                    moodIndex: moodIndex,
                                    energyLevel: energyLevel,
                                    hydration: hydration,
                                    selectedExercises: selectedExercises,
                                    selectedSymptoms: selectedSymptoms,
                                    sleepLabels: sleepLabels,
                                    sleepStars: sleepStars,
                                    moods: moods,
                                    exercises: exercises,
                                    symptoms: symptoms,
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
                                        hydration = (hydration + value).clamp(0, 10);
                                      });
                                    },
                                    onHydrationSubtract: () {
                                      setState(() {
                                        hydration = (hydration - 0.25).clamp(0, 10);
                                      });
                                    },
                                    onHydrationReset: () {
                                      setState(() {
                                        hydration = 0;
                                      });
                                    },
                                    onExerciseToggle: _toggleExercise,
                                    onSymptomToggle: _toggleSymptom,
                                  ),
                                  const SizedBox(height: 22),
                                  _buildSaveButton(),
                                ],
                              ),
                            ),
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: ConfettiWidget(
                        confettiController: _confettiController,
                        blastDirection: pi / 2,
                        emissionFrequency: 0.05,
                        numberOfParticles: 20,
                        maxBlastForce: 20,
                        minBlastForce: 8,
                        gravity: 0.22,
                        shouldLoop: false,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: isSaving ? null : _saveLog,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
                    ? 'Update Today\'s Check-in'
                    : 'Save Daily Check-in',
                style: const TextStyle(
                  fontSize: 22,
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.85, end: 1),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF38BDF8).withOpacity(0.22),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 64,
                  color: Color(0xFF0284C7),
                ),
              ),
            ),
            const SizedBox(height: 26),
            Text(
              'Check-in Saved!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: pagePrimaryTextColor(context),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your daily wellness log has been recorded. Come back tomorrow for your next check-in, or redo today\'s entry if you need to update it.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 34),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: _redoLog,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Redo Today\'s Log',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pageSurfaceColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: pageBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Log Your Day',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: pagePrimaryTextColor(context),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'It is recommended to log after your day or at night.',
                  style: TextStyle(
                    fontSize: 14,
                    color: pageSecondaryTextColor(context),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: Row(
              children: [
                Text(
                  '$currentStreak',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF9A3412),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.local_fire_department_rounded,
                  size: 18,
                  color: Color(0xFFFF6B35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
