import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../shared/widgets/app_bar.dart';
import '../widgets/LogWidgets.dart';

class LogPage extends StatefulWidget {
  const LogPage({Key? key}) : super(key: key);

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> with WidgetsBindingObserver {
  int currentStreak = 5; // This should ideally be loaded from SharedPreferences or a backend
  double sleepHours = 7;
  int sleepQuality = 2; // 0=Poor, 1=Fair, 2=Good, 3=Very Good, 4=Excellent
  int moodIndex = 3;
  double energyLevel = 1; // 0=Low, 1=Medium, 2=High
  double hydration = 1.5;

  final Set<String> selectedExercises = {};
  final Set<String> selectedSymptoms = {};

  final List<String> sleepLabels = [
    "Poor",
    "Fair",
    "Good",
    "Very Good",
    "Excellent",
  ];

  final List<int> sleepStars = [1, 2, 3, 4, 5];

  final List<String> moods = ["😰", "😟", "😐", "🙂", "😊"];

  final List<String> exercises = [
    "Walking",
    "Running",
    "Gym",
    "Yoga",
    "Cycling",
    "Swimming",
    "None",
  ];

  final List<String> symptoms = [
    "Headache",
    "Fatigue",
    "Irritability",
    "Anxiety",
    "Body Pain",
    "Back Pain",
    "None",
  ];

  bool isSubmitted = false;
  bool isLoading = true;

  late ConfettiController _confettiController;

  static const String _lastLogDateKey = 'last_log_date';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _loadSubmissionState();
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
      _refreshForNewDay();
    }
  }

  String _todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  Future<void> _loadSubmissionState() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSavedDate = prefs.getString(_lastLogDateKey);
    final today = _todayKey();

    if (!mounted) return;

    setState(() {
      isSubmitted = lastSavedDate == today;
      isLoading = false;
    });
  }

  Future<void> _refreshForNewDay() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSavedDate = prefs.getString(_lastLogDateKey);
    final today = _todayKey();

    if (!mounted) return;

    if (lastSavedDate != today && isSubmitted) {
      setState(() {
        isSubmitted = false;
      });
    }
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
            "Please complete hydration, exercise, and symptoms before saving.",
          ),
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastLogDateKey, _todayKey());

    await refreshAppBarStreak();

    if (!mounted) return;

    setState(() {
      isSubmitted = true;
    });

    _confettiController.play();
  }

  void _redoLog() {
    setState(() {
      isSubmitted = false;
    });
  }

  Future<void> _logNew() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastLogDateKey);
    await refreshAppBarStreak();

    if (!mounted) return;

    setState(() {
      _resetForm();
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
      if (exercise == "None") {
        if (selectedExercises.contains("None")) {
          selectedExercises.remove("None");
        } else {
          selectedExercises
            ..clear()
            ..add("None");
        }
      } else {
        selectedExercises.remove("None");
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
      if (symptom == "None") {
        if (selectedSymptoms.contains("None")) {
          selectedSymptoms.remove("None");
        } else {
          selectedSymptoms
            ..clear()
            ..add("None");
        }
      } else {
        selectedSymptoms.remove("None");
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 229, 241, 255),
            Color(0xFFFFFFFF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
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
        onPressed: _saveLog,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          "Save Daily Check-in",
          style: TextStyle(
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
            const Text(
              "Check-in Saved!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Your daily wellness log has been recorded successfully.",
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
              child: ElevatedButton(
                onPressed: _logNew,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Log New",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
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
                  "Redo Log",
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE5E7EB)),
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
        // 🔹 LEFT SIDE (Title + Note)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Log Your Day",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 6),
              Text(
                "It’s recommended to log after your day or at night.",
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // 🔥 RIGHT SIDE (Streak)
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
                "$currentStreak",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF9A3412),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                "🔥",
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
}
