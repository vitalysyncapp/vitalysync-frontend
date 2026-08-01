import 'package:flutter/material.dart';
import 'package:vitalysync/l10n/localized_text.dart';

import '../../../../shared/theme/app_page_style.dart';
import '../../data/log_api.dart';

part 'log_sleep_mood_cards.dart';
part 'log_hydration_activity_cards.dart';
part 'log_pressure_recovery_cards.dart';
part 'log_widget_shared_builders.dart';
part 'log_widget_motion.dart';

class LogWidgets extends StatelessWidget {
  final bool revealCards;
  final bool showWeeklyQuestions;
  final double sleepHours;
  final int sleepQuality;
  final int moodIndex;
  final int? energyLevel;
  final double hydration;
  final String workloadHoursBand;
  final int? perceivedStressLevel;
  final int? breakQualityLevel;
  final int? dailyDetachmentLevel;
  final int? dailyFocusLevel;
  final int? dailyAccomplishmentLevel;

  final Set<String> selectedExercises;
  final Set<String> selectedSymptoms;
  final Set<String> selectedHabits;

  final List<String> sleepLabels;
  final List<int> sleepStars;
  final List<String> moods;
  final List<String> exercises;
  final List<String> symptoms;
  final List<String> habits;
  final String exerciseGoalLabel;
  final List<String> workloadOptions;

  final ValueChanged<double> onSleepChanged;
  final ValueChanged<int> onSleepQualityChanged;
  final ValueChanged<int> onMoodChanged;
  final ValueChanged<int> onEnergyChanged;
  final ValueChanged<double> onHydrationAdd;
  final VoidCallback onHydrationSubtract;
  final VoidCallback onHydrationReset;
  final ValueChanged<String> onWorkloadChanged;
  final ValueChanged<int> onPerceivedStressChanged;
  final ValueChanged<int> onBreakQualityChanged;
  final ValueChanged<int> onDailyDetachmentChanged;
  final ValueChanged<int> onDailyFocusChanged;
  final ValueChanged<int> onDailyAccomplishmentChanged;
  final ValueChanged<String> onExerciseToggle;
  final ValueChanged<String> onSymptomToggle;
  final ValueChanged<String> onHabitToggle;

  const LogWidgets({
    super.key,
    this.revealCards = true,
    this.showWeeklyQuestions = false,
    required this.sleepHours,
    required this.sleepQuality,
    required this.moodIndex,
    required this.energyLevel,
    required this.hydration,
    required this.workloadHoursBand,
    required this.perceivedStressLevel,
    required this.breakQualityLevel,
    required this.dailyDetachmentLevel,
    required this.dailyFocusLevel,
    required this.dailyAccomplishmentLevel,
    required this.selectedExercises,
    required this.selectedSymptoms,
    required this.selectedHabits,
    required this.sleepLabels,
    required this.sleepStars,
    required this.moods,
    required this.exercises,
    required this.symptoms,
    required this.habits,
    required this.exerciseGoalLabel,
    required this.workloadOptions,
    required this.onSleepChanged,
    required this.onSleepQualityChanged,
    required this.onMoodChanged,
    required this.onEnergyChanged,
    required this.onHydrationAdd,
    required this.onHydrationSubtract,
    required this.onHydrationReset,
    required this.onWorkloadChanged,
    required this.onPerceivedStressChanged,
    required this.onBreakQualityChanged,
    required this.onDailyDetachmentChanged,
    required this.onDailyFocusChanged,
    required this.onDailyAccomplishmentChanged,
    required this.onExerciseToggle,
    required this.onSymptomToggle,
    required this.onHabitToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[];

    void addCard(String id, Widget child) {
      if (cards.isNotEmpty) {
        cards.add(const SizedBox(height: 14));
      }
      cards.add(
        _LogCardEntrance(
          key: ValueKey('log-card-$id'),
          order: cards.length ~/ 2,
          reveal: revealCards,
          child: child,
        ),
      );
    }

    addCard('sleep-duration', _buildSleepDurationCard(context));
    addCard('sleep-quality', _buildSleepQualityCard());
    if (showWeeklyQuestions) {
      addCard('weekly-pressure', _buildPerceivedStressCard());
    }
    addCard('energy', _buildEnergyCard(context));
    addCard('mood', _buildMoodCard());
    addCard('symptoms', _buildSymptomsCard());
    if (showWeeklyQuestions) {
      addCard('weekly-detachment', _buildDailyDetachmentCard());
      addCard('recovery-breaks', _buildBreakQualityCard());
    }
    addCard('habits', _buildHabitsCard());
    addCard('hydration', _buildHydrationCard());
    if (showWeeklyQuestions) {
      addCard('weekly-focus', _buildDailyFocusCard());
      addCard('weekly-accomplishment', _buildDailyAccomplishmentCard());
    }
    addCard('workload', _buildWorkloadCard());
    addCard('exercise', _buildExerciseCard());

    return Column(children: cards);
  }
}
