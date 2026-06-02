import 'package:flutter/material.dart';

import '../../../../shared/theme/app_page_style.dart';
import '../../data/log_api.dart';

part 'log_sleep_mood_cards.dart';
part 'log_hydration_activity_cards.dart';
part 'log_pressure_recovery_cards.dart';
part 'log_widget_shared_builders.dart';

class LogWidgets extends StatelessWidget {
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
    return Column(
      children: [
        _buildSleepDurationCard(context),
        const SizedBox(height: 12),
        _buildSleepQualityCard(),
        const SizedBox(height: 12),
        _buildDimensionHeader(
          context,
          icon: Icons.battery_5_bar_rounded,
          title: 'Emotional exhaustion',
          dimensionLabel: 'Maslach dimension',
          description:
              'Tracks strain, depleted energy, low mood, and physical symptoms that can signal exhaustion.',
          accentColor: const Color(0xFFFF8A1F),
        ),
        const SizedBox(height: 12),
        _buildPerceivedStressCard(),
        const SizedBox(height: 12),
        _buildEnergyCard(context),
        const SizedBox(height: 12),
        _buildMoodCard(),
        const SizedBox(height: 12),
        _buildSymptomsCard(),
        const SizedBox(height: 12),
        _buildDimensionHeader(
          context,
          icon: Icons.spa_outlined,
          title: 'Depersonalization or detachment',
          dimensionLabel: 'Maslach dimension',
          description:
              'Tracks emotional distance and recovery supports that can affect connection to daily responsibilities.',
          accentColor: const Color(0xFF14B8A6),
        ),
        const SizedBox(height: 12),
        _buildDailyDetachmentCard(),
        const SizedBox(height: 12),
        _buildBreakQualityCard(),
        const SizedBox(height: 12),
        _buildHabitsCard(),
        const SizedBox(height: 12),
        _buildHydrationCard(),
        const SizedBox(height: 12),
        _buildDimensionHeader(
          context,
          icon: Icons.center_focus_strong_rounded,
          title: 'Reduced accomplishment',
          dimensionLabel: 'Maslach dimension',
          description:
              'Connects workload, activity, and body-support signals with weekly focus and progress answers.',
          accentColor: const Color(0xFF2563EB),
        ),
        const SizedBox(height: 12),
        _buildDailyFocusCard(),
        const SizedBox(height: 12),
        _buildDailyAccomplishmentCard(),
        const SizedBox(height: 12),
        _buildWorkloadCard(),
        const SizedBox(height: 12),
        _buildExerciseCard(),
      ],
    );
  }
}
