part of 'log_widgets.dart';

extension _LogHydrationActivityCards on LogWidgets {
  Widget _buildHydrationCard(BuildContext context) {
    final hydrationStatus = LogApi.getHydrationStatus(hydration);
    final hydrationAccent = Color(hydrationStatus.colorValue);
    final glasses = hydration * 4;
    final glassCount = glasses
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'\.?0+$'), '');

    return _buildCard(
      accentColor: const Color(0xFF00A3D7),
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
                  subtitle: "Tap to add glasses. 1 glass = 250 mL.",
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
              _hydrationButton(1),
              const SizedBox(width: 8),
              _hydrationButton(2),
              const SizedBox(width: 8),
              _hydrationButton(3),
              const SizedBox(width: 8),
              _hydrationButton(4),
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
                  child: LocalizedText(
                    "$glassCount ${glasses == 1 ? 'glass' : 'glasses'}",
                    key: ValueKey(hydration),
                    style: TextStyle(
                      fontSize: 29,
                      fontWeight: FontWeight.w800,
                      color: pageAccentColor(context, const Color(0xFF0891B2)),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                LocalizedText(
                  "Goal: 10 glasses",
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? pageAccentColor(context, hydrationAccent)
                        : hydrationAccent.withValues(alpha: 0.82),
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
      accentColor: const Color(0xFF16A34A),
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
          _buildCenteredSelectionGrid(
            options: exercises,
            minItemWidth: 104,
            isSelected: selectedExercises.contains,
            leadingIconFor: (exercise) => exerciseIconFor(name: exercise),
            onSelected: onExerciseToggle,
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomsCard() {
    return _buildCard(
      accentColor: const Color(0xFFEF4444),
      child: Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Column(
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
                  return _LogPressable(
                    onTap: () => onSymptomToggle(symptom),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(
                                0xFFEF4444,
                              ).withValues(alpha: isDark ? 0.16 : 0.08)
                            : pageSubtleSurfaceColor(context),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFFEF4444)
                              : pageBorderColor(context),
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
                      child: LocalizedText(
                        symptom,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: selected
                              ? const Color(0xFFFF6B6B)
                              : pagePrimaryTextColor(context),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHabitsCard() {
    return _buildCard(
      accentColor: const Color(0xFF16A34A),
      child: Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Column(
            children: [
              _sectionHeader(
                icon: Icons.spa_outlined,
                iconBg: const Color(0xFFE7F8EF),
                iconColor: const Color(0xFF16A34A),
                title: "Recovery habits",
                subtitle: "Pick what helped you rest or feel supported today.",
              ),
              const SizedBox(height: 7),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: habits.map((habit) {
                  final selected = selectedHabits.contains(habit);
                  return _LogPressable(
                    onTap: () => onHabitToggle(habit),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(
                                0xFF16A34A,
                              ).withValues(alpha: isDark ? 0.16 : 0.08)
                            : pageSubtleSurfaceColor(context),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF16A34A)
                              : pageBorderColor(context),
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
                      child: LocalizedText(
                        habit,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: selected
                              ? const Color(0xFF4ADE80)
                              : pagePrimaryTextColor(context),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWorkloadCard() {
    return _buildCard(
      accentColor: const Color(0xFF15803D),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.work_history_outlined,
            iconBg: const Color(0xFFE8F8F1),
            iconColor: const Color(0xFF15803D),
            title: "Workload hours",
            subtitle: "How much focused work did today ask from you?",
          ),
          const SizedBox(height: 8),
          _buildCenteredSelectionGrid(
            options: workloadOptions,
            minItemWidth: 116,
            labelFor: LogApi.workloadHoursDisplayLabel,
            isSelected: (option) =>
                LogApi.workloadHoursDisplayLabel(workloadHoursBand) ==
                LogApi.workloadHoursDisplayLabel(option),
            leadingIconFor: (option) => option == 'None'
                ? Icons.self_improvement_rounded
                : Icons.schedule_rounded,
            onSelected: onWorkloadChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildCenteredSelectionGrid({
    required List<String> options,
    required double minItemWidth,
    String Function(String option)? labelFor,
    required bool Function(String option) isSelected,
    required IconData Function(String option) leadingIconFor,
    required ValueChanged<String> onSelected,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 6.0;
        final screenSize = MediaQuery.sizeOf(context);
        final isNarrowScreen = screenSize.width < 430;
        final isTallNarrowScreen = isNarrowScreen && screenSize.height >= 780;
        final comfortableColumnCount =
            ((constraints.maxWidth + spacing) / (minItemWidth + spacing))
                .floor();
        final columnCount = isNarrowScreen
            ? (isTallNarrowScreen ? 2 : 3)
            : comfortableColumnCount.clamp(2, 3).toInt();
        final totalSpacing = spacing * (columnCount - 1);
        final availableItemWidth =
            (constraints.maxWidth - totalSpacing) / columnCount;
        final itemWidth = availableItemWidth <= 0
            ? constraints.maxWidth
            : availableItemWidth;
        final rows = <List<String>>[];

        for (var index = 0; index < options.length; index += columnCount) {
          final end = index + columnCount > options.length
              ? options.length
              : index + columnCount;
          rows.add(options.sublist(index, end));
        }

        Widget tile(String option) {
          return _selectionBox(
            label: labelFor?.call(option) ?? option,
            selected: isSelected(option),
            width: itemWidth,
            height: 36,
            contentPadding: EdgeInsets.symmetric(
              horizontal: columnCount == 3 ? 6 : 8,
            ),
            alignment: Alignment.center,
            leadingIcon: leadingIconFor(option),
            iconSize: columnCount == 3 ? 13 : 14,
            fontSize: columnCount == 3 ? 10.8 : 11.5,
            checkIconSize: columnCount == 3 ? 13 : 14,
            onTap: () => onSelected(option),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: rows.asMap().entries.map((entry) {
            final row = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: entry.key == rows.length - 1 ? 0 : spacing,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: row.asMap().entries.map((rowEntry) {
                  return Padding(
                    padding: EdgeInsets.only(
                      right: rowEntry.key == row.length - 1 ? 0 : spacing,
                    ),
                    child: tile(rowEntry.value),
                  );
                }).toList(),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
