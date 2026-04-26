import 'package:flutter/material.dart';

import '../../data/log_api.dart';

class LogWidgets extends StatelessWidget {
  final double sleepHours;
  final int sleepQuality;
  final int moodIndex;
  final double energyLevel;
  final double hydration;

  final Set<String> selectedExercises;
  final Set<String> selectedSymptoms;

  final List<String> sleepLabels;
  final List<int> sleepStars;
  final List<String> moods;
  final List<String> exercises;
  final List<String> symptoms;
  final String exerciseGoalLabel;

  final ValueChanged<double> onSleepChanged;
  final ValueChanged<int> onSleepQualityChanged;
  final ValueChanged<int> onMoodChanged;
  final ValueChanged<double> onEnergyChanged;
  final ValueChanged<double> onHydrationAdd;
  final VoidCallback onHydrationSubtract;
  final VoidCallback onHydrationReset;
  final ValueChanged<String> onExerciseToggle;
  final ValueChanged<String> onSymptomToggle;

  const LogWidgets({
    Key? key,
    required this.sleepHours,
    required this.sleepQuality,
    required this.moodIndex,
    required this.energyLevel,
    required this.hydration,
    required this.selectedExercises,
    required this.selectedSymptoms,
    required this.sleepLabels,
    required this.sleepStars,
    required this.moods,
    required this.exercises,
    required this.symptoms,
    required this.exerciseGoalLabel,
    required this.onSleepChanged,
    required this.onSleepQualityChanged,
    required this.onMoodChanged,
    required this.onEnergyChanged,
    required this.onHydrationAdd,
    required this.onHydrationSubtract,
    required this.onHydrationReset,
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 15, color: Color(0xFF64748B)),
            ),
          ],
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
