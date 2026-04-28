import 'package:flutter/material.dart';

import '../../data/log_api.dart';

class LogWidgets extends StatelessWidget {
  final double sleepHours;
  final int sleepQuality;
  final int moodIndex;
  final double energyLevel;
  final double hydration;
  final String workloadHoursBand;
  final int? perceivedStressLevel;
  final int? breakQualityLevel;

  final Set<String> selectedExercises;
  final Set<String> selectedSymptoms;

  final List<String> sleepLabels;
  final List<int> sleepStars;
  final List<String> moods;
  final List<String> exercises;
  final List<String> symptoms;
  final String exerciseGoalLabel;
  final List<String> workloadOptions;

  final ValueChanged<double> onSleepChanged;
  final ValueChanged<int> onSleepQualityChanged;
  final ValueChanged<int> onMoodChanged;
  final ValueChanged<double> onEnergyChanged;
  final ValueChanged<double> onHydrationAdd;
  final VoidCallback onHydrationSubtract;
  final VoidCallback onHydrationReset;
  final ValueChanged<String> onWorkloadChanged;
  final ValueChanged<int> onPerceivedStressChanged;
  final ValueChanged<int> onBreakQualityChanged;
  final ValueChanged<String> onExerciseToggle;
  final ValueChanged<String> onSymptomToggle;

  const LogWidgets({
    Key? key,
    required this.sleepHours,
    required this.sleepQuality,
    required this.moodIndex,
    required this.energyLevel,
    required this.hydration,
    required this.workloadHoursBand,
    required this.perceivedStressLevel,
    required this.breakQualityLevel,
    required this.selectedExercises,
    required this.selectedSymptoms,
    required this.sleepLabels,
    required this.sleepStars,
    required this.moods,
    required this.exercises,
    required this.symptoms,
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
    required this.onExerciseToggle,
    required this.onSymptomToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSleepDurationCard(context),
        const SizedBox(height: 18),
        _buildSleepQualityCard(),
        const SizedBox(height: 18),
        _buildMoodCard(),
        const SizedBox(height: 18),
        _buildEnergyCard(context),
        const SizedBox(height: 18),
        _buildHydrationCard(),
        const SizedBox(height: 18),
        _buildExerciseCard(),
        const SizedBox(height: 18),
        _buildSymptomsCard(),
        const SizedBox(height: 18),
        _buildWorkloadCard(),
        const SizedBox(height: 18),
        _buildPerceivedStressCard(),
        const SizedBox(height: 18),
        _buildBreakQualityCard(),
      ],
    );
  }

  Widget _buildSleepDurationCard(BuildContext context) {
    return _buildCard(
      child: Column(
        children: [
          _sectionHeader(
            icon: Icons.nightlight_round,
            iconBg: const Color(0xFFE8E7FF),
            iconColor: const Color(0xFF4B3FF2),
            title: "Sleep Duration",
            subtitle: "Last night",
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 10,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 18,
                    ),
                    activeTrackColor: const Color(0xFF4B3FF2),
                    inactiveTrackColor: const Color(0xFFD8DCE2),
                    thumbColor: const Color(0xFF4B3FF2),
                    overlayColor: const Color(0x334B3FF2),
                  ),
                  child: Slider(
                    value: sleepHours,
                    min: 0,
                    max: 12,
                    divisions: 12,
                    onChanged: onSleepChanged,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "${sleepHours.round()}h",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4B3FF2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSleepQualityCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Sleep Quality",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(sleepLabels.length, (index) {
                final selected = sleepQuality == index;
                final starCount = sleepStars[index];
                final starSize = (26 - (starCount * 2))
                    .clamp(14, 22)
                    .toDouble();

                return Padding(
                  padding: EdgeInsets.only(
                    right: index == sleepLabels.length - 1 ? 0 : 10,
                  ),
                  child: GestureDetector(
                    onTap: () => onSleepQualityChanged(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      width: 96,
                      padding: EdgeInsets.symmetric(
                        vertical: starCount >= 4 ? 10 : 14,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF4B3FF2)
                              : const Color(0xFFD1D5DB),
                          width: selected ? 2 : 1.3,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF4B3FF2,
                                  ).withOpacity(0.16),
                                  blurRadius: 14,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutBack,
                        scale: selected ? 1.03 : 1.0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (starCount >= 4)
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 2,
                                runSpacing: 2,
                                children: List.generate(
                                  starCount,
                                  (starIndex) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeOut,
                                    decoration: selected
                                        ? BoxDecoration(
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFFF4C430,
                                                ).withOpacity(0.45),
                                                blurRadius: 10,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          )
                                        : null,
                                    child: Icon(
                                      Icons.star_rounded,
                                      size: starSize,
                                      color: const Color(0xFFF4C430),
                                    ),
                                  ),
                                ),
                              )
                            else
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(
                                  starCount,
                                  (starIndex) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 1,
                                    ),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      curve: Curves.easeOut,
                                      decoration: selected
                                          ? BoxDecoration(
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(
                                                    0xFFF4C430,
                                                  ).withOpacity(0.45),
                                                  blurRadius: 10,
                                                  spreadRadius: 1,
                                                ),
                                              ],
                                            )
                                          : null,
                                      child: Icon(
                                        Icons.star_rounded,
                                        size: starSize,
                                        color: const Color(0xFFF4C430),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 10),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOut,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected
                                    ? const Color(0xFF4B3FF2)
                                    : const Color(0xFF334155),
                              ),
                              child: Text(
                                sleepLabels[index],
                                textAlign: TextAlign.center,
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
        ],
      ),
    );
  }

  Widget _buildMoodCard() {
    return _buildCard(
      child: Column(
        children: [
          _sectionHeader(
            icon: Icons.sentiment_satisfied_alt,
            iconBg: const Color(0xFFFFF4CC),
            iconColor: const Color(0xFFE0A100),
            title: "Mood",
            subtitle: "How are you feeling today?",
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(moods.length, (index) {
              final selected = moodIndex == index;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == moods.length - 1 ? 0 : 10,
                  ),
                  child: GestureDetector(
                    onTap: () => onMoodChanged(index),
                    child: Container(
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFFF4B400)
                              : const Color(0xFFD1D5DB),
                          width: selected ? 2 : 1.3,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          moods[index],
                          style: const TextStyle(fontSize: 34),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyCard(BuildContext context) {
    return _buildCard(
      child: Column(
        children: [
          _sectionHeader(
            icon: Icons.battery_5_bar_rounded,
            iconBg: const Color(0xFFFFEEDB),
            iconColor: const Color(0xFFFF5A00),
            title: "Energy Level",
            subtitle: "Current energy",
          ),
          const SizedBox(height: 18),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
              activeTrackColor: const Color(0xFFFF5A00),
              inactiveTrackColor: const Color(0xFFD8DCE2),
              thumbColor: const Color(0xFFFF5A00),
              overlayColor: const Color(0x33FF5A00),
            ),
            child: Slider(
              value: energyLevel,
              min: 0,
              max: 2,
              divisions: 2,
              onChanged: onEnergyChanged,
            ),
          ),
          const SizedBox(height: 2),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Low",
                style: TextStyle(fontSize: 15, color: Color(0xFF64748B)),
              ),
              Text(
                "Medium",
                style: TextStyle(fontSize: 15, color: Color(0xFF64748B)),
              ),
              Text(
                "High",
                style: TextStyle(fontSize: 15, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHydrationCard() {
    final hydrationStatus = LogApi.getHydrationStatus(hydration);
    final hydrationAccent = Color(hydrationStatus.colorValue);

    return _buildCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _sectionHeader(
                  icon: Icons.water_drop_outlined,
                  iconBg: const Color(0xFFDFF7FB),
                  iconColor: const Color(0xFF00A3D7),
                  title: "Hydration",
                  subtitle: "Water intake today",
                ),
              ),
              _iconActionButton(
                icon: Icons.remove,
                color: const Color(0xFF0891B2),
                onTap: onHydrationSubtract,
              ),
              const SizedBox(width: 8),
              _iconActionButton(
                icon: Icons.refresh,
                color: const Color(0xFFEF4444),
                onTap: onHydrationReset,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _hydrationButton("+0.25L", 0.25),
              const SizedBox(width: 10),
              _hydrationButton("+0.5L", 0.5),
              const SizedBox(width: 10),
              _hydrationButton("+0.75L", 0.75),
              const SizedBox(width: 10),
              _hydrationButton("+1L", 1.0),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22),
            decoration: BoxDecoration(
              color: hydrationAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: hydrationAccent.withOpacity(0.16),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: hydrationAccent.withOpacity(0.24)),
            ),
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Text(
                    "${hydration.toStringAsFixed(hydration % 1 == 0 ? 0 : 1)}L",
                    key: ValueKey(hydration),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0891B2),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Goal: 2.5L",
                  style: TextStyle(
                    fontSize: 17,
                    color: hydrationAccent.withOpacity(0.82),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.fitness_center,
            iconBg: const Color(0xFFDDF8E4),
            iconColor: const Color(0xFF16A34A),
            title: "Exercise",
            subtitle: "Goal: $exerciseGoalLabel per week",
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 8.0;
              final isSingleColumn = constraints.maxWidth < 340;
              final itemWidth = isSingleColumn
                  ? constraints.maxWidth
                  : (constraints.maxWidth - spacing) / 2;

              return Wrap(
                alignment: WrapAlignment.start,
                spacing: spacing,
                runSpacing: spacing,
                children: exercises.map((exercise) {
                  final selected = selectedExercises.contains(exercise);

                  return _selectionBox(
                    label: exercise,
                    selected: selected,
                    width: itemWidth,
                    height: 48,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    alignment: Alignment.centerLeft,
                    leadingIcon: exercise == 'None'
                        ? Icons.block_rounded
                        : Icons.directions_run_rounded,
                    onTap: () => onExerciseToggle(exercise),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomsCard() {
    return _buildCard(
      child: Column(
        children: [
          _sectionHeader(
            icon: Icons.monitor_heart_outlined,
            iconBg: const Color(0xFFFFE1E1),
            iconColor: const Color(0xFFEF4444),
            title: "Symptoms",
            subtitle: "Any symptoms today?",
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: symptoms.map((symptom) {
              final selected = selectedSymptoms.contains(symptom);
              return GestureDetector(
                onTap: () => onSymptomToggle(symptom),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFFFF1F2) : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFFEF4444)
                          : const Color(0xFFD1D5DB),
                      width: selected ? 1.6 : 1.3,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withOpacity(0.15),
                              blurRadius: 8,
                              spreadRadius: 1,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Text(
                    symptom,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected
                          ? const Color(0xFFB91C1C)
                          : const Color(0xFF334155),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkloadCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.work_history_outlined,
            iconBg: const Color(0xFFE8F8F1),
            iconColor: const Color(0xFF15803D),
            title: "Workload Hours",
            subtitle: "How much focused work did today ask from you?",
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 8.0;
              final isSingleColumn = constraints.maxWidth < 340;
              final itemWidth = isSingleColumn
                  ? constraints.maxWidth
                  : (constraints.maxWidth - spacing) / 2;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: workloadOptions.map((option) {
                  final selected = workloadHoursBand == option;

                  return _selectionBox(
                    label: option,
                    selected: selected,
                    width: itemWidth,
                    height: 48,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    alignment: Alignment.centerLeft,
                    leadingIcon: option == 'None'
                        ? Icons.self_improvement_rounded
                        : Icons.schedule_rounded,
                    onTap: () => onWorkloadChanged(option),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPerceivedStressCard() {
    const stressLabels = [
      'Calm',
      'Light',
      'Steady',
      'Heavy',
      'Intense',
    ];
    final selectedLevel = perceivedStressLevel;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1FB489), Color(0xFF56B4D3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1FB489).withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.spa_outlined,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Pressure Check",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Choose the level that best matches how much pressure you carried today.",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(stressLabels.length, (index) {
              final value = index + 1;
              final selected = selectedLevel == value;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == stressLabels.length - 1 ? 0 : 7,
                  ),
                  child: GestureDetector(
                    onTap: () => onPerceivedStressChanged(value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      height: 74,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: selected ? 0.95 : 0.32,
                          ),
                          width: selected ? 1.6 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$value',
                            style: TextStyle(
                              color: selected
                                  ? const Color(0xFF0F766E)
                                  : Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              stressLabels[index],
                              maxLines: 1,
                              style: TextStyle(
                                color: selected
                                    ? const Color(0xFF0F766E)
                                    : Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
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
          const SizedBox(height: 12),
          Text(
            selectedLevel == null
                ? 'Your answer helps VitalySync understand today with more care.'
                : 'Logged as ${stressLabels[selectedLevel - 1].toLowerCase()} pressure.',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakQualityCard() {
    const breakLabels = [
      'None',
      'Brief',
      'Okay',
      'Good',
      'Restored',
    ];
    final selectedLevel = breakQualityLevel;

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.self_improvement_rounded,
            iconBg: const Color(0xFFE0F7F1),
            iconColor: const Color(0xFF0F766E),
            title: 'Recovery Breaks',
            subtitle: 'How restorative were your pauses today?',
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(breakLabels.length, (index) {
              final value = index + 1;
              final selected = selectedLevel == value;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == breakLabels.length - 1 ? 0 : 7,
                  ),
                  child: GestureDetector(
                    onTap: () => onBreakQualityChanged(value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      height: 70,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        gradient: selected
                            ? const LinearGradient(
                                colors: [
                                  Color(0xFF1FB489),
                                  Color(0xFF56B4D3),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: selected ? null : const Color(0xFFF0FDF9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF1FB489)
                              : const Color(0xFFBAE6D7),
                          width: selected ? 1.7 : 1.1,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF1FB489,
                                  ).withValues(alpha: 0.18),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$value',
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF0F766E),
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              breakLabels[index],
                              maxLines: 1,
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFF0F766E),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
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
          const SizedBox(height: 12),
          Text(
            selectedLevel == null
                ? 'Optional, but useful for spotting recovery patterns over time.'
                : 'Recovery logged as ${breakLabels[selectedLevel - 1].toLowerCase()}.',
            style: const TextStyle(
              color: Color(0xFF0F766E),
              fontSize: 13.5,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFE),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _hydrationButton(String label, double addAmount) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onHydrationAdd(addAmount),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7F9),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F4C81),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }

  Widget _selectionBox({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    double width = 150,
    double height = 56,
    EdgeInsetsGeometry contentPadding = const EdgeInsets.symmetric(
      horizontal: 12,
    ),
    AlignmentGeometry alignment = Alignment.center,
    IconData? leadingIcon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: contentPadding,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF8FAFC) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF2563EB) : const Color(0xFFD1D5DB),
            width: selected ? 2 : 1.3,
          ),
        ),
        child: Align(
          alignment: alignment,
          child: Row(
            children: [
              if (leadingIcon != null) ...[
                Icon(
                  leadingIcon,
                  size: 18,
                  color: selected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected
                        ? const Color(0xFF1D4ED8)
                        : const Color(0xFF334155),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 18,
                color: selected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
