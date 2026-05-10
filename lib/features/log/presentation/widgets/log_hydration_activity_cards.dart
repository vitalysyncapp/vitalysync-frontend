part of 'log_widgets.dart';

extension _LogHydrationActivityCards on LogWidgets {
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
                  subtitle: "1 normal glass is about 0.25L. 10 glasses = 2.5L.",
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
              color: hydrationAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: hydrationAccent.withValues(alpha: 0.16),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: hydrationAccent.withValues(alpha: 0.24),
              ),
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
                    color: hydrationAccent.withValues(alpha: 0.82),
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
                              color: const Color(
                                0xFFEF4444,
                              ).withValues(alpha: 0.15),
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
}
