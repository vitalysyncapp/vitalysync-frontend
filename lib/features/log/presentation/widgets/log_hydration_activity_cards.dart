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
          const SizedBox(height: 12),
          Row(
            children: [
              _hydrationButton("+0.25L", 0.25),
              const SizedBox(width: 8),
              _hydrationButton("+0.5L", 0.5),
              const SizedBox(width: 8),
              _hydrationButton("+0.75L", 0.75),
              const SizedBox(width: 8),
              _hydrationButton("+1L", 1.0),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: hydrationAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: hydrationAccent.withValues(alpha: 0.16),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
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
                      fontSize: 29,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0891B2),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Goal: 2.5L",
                  style: TextStyle(
                    fontSize: 14,
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
      padding: const EdgeInsets.all(10),
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
          const SizedBox(height: 8),
          _buildTwoRowSelectionGrid(
            options: exercises,
            minItemWidth: 104,
            isSelected: selectedExercises.contains,
            leadingIconFor: (exercise) => exercise == 'None'
                ? Icons.block_rounded
                : Icons.directions_run_rounded,
            onSelected: onExerciseToggle,
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
          const SizedBox(height: 7),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: symptoms.map((symptom) {
              final selected = selectedSymptoms.contains(symptom);
              return GestureDetector(
                onTap: () => onSymptomToggle(symptom),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
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
                      fontSize: 12,
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

  Widget _buildHabitsCard() {
    return _buildCard(
      child: Column(
        children: [
          _sectionHeader(
            icon: Icons.spa_outlined,
            iconBg: const Color(0xFFE7F8EF),
            iconColor: const Color(0xFF16A34A),
            title: "Recovery Habits",
            subtitle: "Pick what helped you rest or feel supported today.",
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: habits.map((habit) {
              final selected = selectedHabits.contains(habit);
              return GestureDetector(
                onTap: () => onHabitToggle(habit),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFECFDF5) : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFD1D5DB),
                      width: selected ? 1.6 : 1.3,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xFF16A34A,
                              ).withValues(alpha: 0.15),
                              blurRadius: 8,
                              spreadRadius: 1,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Text(
                    habit,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected
                          ? const Color(0xFF166534)
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
      padding: const EdgeInsets.all(10),
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
          const SizedBox(height: 8),
          _buildTwoRowSelectionGrid(
            options: workloadOptions,
            minItemWidth: 116,
            isSelected: (option) => workloadHoursBand == option,
            leadingIconFor: (option) => option == 'None'
                ? Icons.self_improvement_rounded
                : Icons.schedule_rounded,
            onSelected: onWorkloadChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildTwoRowSelectionGrid({
    required List<String> options,
    required double minItemWidth,
    required bool Function(String option) isSelected,
    required IconData Function(String option) leadingIconFor,
    required ValueChanged<String> onSelected,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 6.0;
        final columns = (options.length / 2).ceil();
        final minimumGridWidth =
            (columns * minItemWidth) + (spacing * (columns - 1));
        final gridWidth = minimumGridWidth > constraints.maxWidth
            ? minimumGridWidth
            : constraints.maxWidth;
        final itemWidth = (gridWidth - (spacing * (columns - 1))) / columns;
        final firstRow = options.take(columns).toList();
        final secondRow = options.skip(columns).toList();

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: gridWidth,
            child: Column(
              children: [
                _selectionGridRow(
                  items: firstRow,
                  itemWidth: itemWidth,
                  spacing: spacing,
                  isSelected: isSelected,
                  leadingIconFor: leadingIconFor,
                  onSelected: onSelected,
                ),
                if (secondRow.isNotEmpty) ...[
                  const SizedBox(height: spacing),
                  _selectionGridRow(
                    items: secondRow,
                    itemWidth: itemWidth,
                    spacing: spacing,
                    isSelected: isSelected,
                    leadingIconFor: leadingIconFor,
                    onSelected: onSelected,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _selectionGridRow({
    required List<String> items,
    required double itemWidth,
    required double spacing,
    required bool Function(String option) isSelected,
    required IconData Function(String option) leadingIconFor,
    required ValueChanged<String> onSelected,
  }) {
    return Row(
      children: List.generate(items.length, (index) {
        final option = items[index];

        return Padding(
          padding: EdgeInsets.only(
            right: index == items.length - 1 ? 0 : spacing,
          ),
          child: _selectionBox(
            label: option,
            selected: isSelected(option),
            width: itemWidth,
            height: 36,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerLeft,
            leadingIcon: leadingIconFor(option),
            iconSize: 14,
            fontSize: 11.5,
            checkIconSize: 14,
            onTap: () => onSelected(option),
          ),
        );
      }),
    );
  }
}
