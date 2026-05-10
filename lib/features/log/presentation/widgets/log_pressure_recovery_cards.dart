part of 'log_widgets.dart';

extension _LogPressureRecoveryCards on LogWidgets {
  Widget _buildPerceivedStressCard() {
    const stressLabels = ['Calm', 'Light', 'Steady', 'Heavy', 'Intense'];
    final selectedLevel = perceivedStressLevel;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color.fromARGB(255, 157, 94, 230), Color(0xFF56B4D3)],
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
    const breakLabels = ['None', 'Brief', 'Okay', 'Good', 'Restored'];
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
                                colors: [Color(0xFF1FB489), Color(0xFF56B4D3)],
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
}
