part of 'log_widgets.dart';

extension _LogPressureRecoveryCards on LogWidgets {
  Widget _buildDailyDetachmentCard() {
    const detachmentLabels = [
      'Connected',
      'Present',
      'Mixed',
      'Distant',
      'Detached',
    ];

    return _buildLikertLevelCard(
      icon: Icons.link_off_rounded,
      iconBg: const Color(0xFFE0F7F1),
      iconColor: const Color(0xFF14B8A6),
      title: 'Daily detachment',
      subtitle: 'How emotionally distant did you feel from responsibilities?',
      labels: detachmentLabels,
      selectedLevel: dailyDetachmentLevel,
      onChanged: onDailyDetachmentChanged,
      emptyMessage: 'Choose a 1-5 detachment level to complete this group.',
      selectedMessagePrefix: 'Detachment logged as',
    );
  }

  Widget _buildDailyFocusCard() {
    const focusLabels = ['Scattered', 'Low', 'Okay', 'Focused', 'Clear'];

    return _buildLikertLevelCard(
      icon: Icons.center_focus_strong_rounded,
      iconBg: const Color(0xFFEFF6FF),
      iconColor: const Color(0xFF2563EB),
      title: 'Daily focus',
      subtitle: 'How well could you stay with important tasks today?',
      labels: focusLabels,
      selectedLevel: dailyFocusLevel,
      onChanged: onDailyFocusChanged,
      emptyMessage: 'Choose a 1-5 focus level to complete this group.',
      selectedMessagePrefix: 'Focus logged as',
    );
  }

  Widget _buildDailyAccomplishmentCard() {
    const accomplishmentLabels = ['Stuck', 'Limited', 'Some', 'Good', 'Strong'];

    return _buildLikertLevelCard(
      icon: Icons.emoji_events_rounded,
      iconBg: const Color(0xFFFFF7ED),
      iconColor: const Color(0xFFF59E0B),
      title: 'Daily accomplishment',
      subtitle: 'How much meaningful progress did you feel today?',
      labels: accomplishmentLabels,
      selectedLevel: dailyAccomplishmentLevel,
      onChanged: onDailyAccomplishmentChanged,
      emptyMessage: 'Choose a 1-5 accomplishment level to complete this group.',
      selectedMessagePrefix: 'Accomplishment logged as',
    );
  }

  Widget _buildPerceivedStressCard() {
    const stressLabels = ['Calm', 'Light', 'Steady', 'Heavy', 'Intense'];
    final selectedLevel = perceivedStressLevel;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color.fromARGB(255, 157, 94, 230), Color(0xFF56B4D3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1FB489).withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 5),
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.spa_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's pressure check",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      "Choose the level that best matches how much pressure you carried today.",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(stressLabels.length, (index) {
              final value = index + 1;
              final selected = selectedLevel == value;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == stressLabels.length - 1 ? 0 : 6,
                  ),
                  child: GestureDetector(
                    onTap: () => onPerceivedStressChanged(value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      height: 58,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(13),
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
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              stressLabels[index],
                              maxLines: 1,
                              style: TextStyle(
                                color: selected
                                    ? const Color(0xFF0F766E)
                                    : Colors.white,
                                fontSize: 11,
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
          const SizedBox(height: 9),
          Text(
            selectedLevel == null
                ? 'Your answer helps VitalySync understand today with more care.'
                : 'Logged as ${stressLabels[selectedLevel - 1].toLowerCase()} pressure.',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
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
      child: Builder(
        builder: (context) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(
                icon: Icons.self_improvement_rounded,
                iconBg: const Color(0xFFE0F7F1),
                iconColor: const Color(0xFF0F766E),
                title: 'Recovery breaks',
                subtitle: 'How restorative were your pauses today?',
              ),
              const SizedBox(height: 12),
              Row(
                children: List.generate(breakLabels.length, (index) {
                  final value = index + 1;
                  final selected = selectedLevel == value;

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index == breakLabels.length - 1 ? 0 : 6,
                      ),
                      child: GestureDetector(
                        onTap: () => onBreakQualityChanged(value),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          height: 56,
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
                            color: selected
                                ? null
                                : pageSubtleSurfaceColor(context),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF1FB489)
                                  : pageBorderColor(context),
                              width: selected ? 1.7 : 1.1,
                            ),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF1FB489,
                                      ).withValues(alpha: 0.18),
                                      blurRadius: 9,
                                      offset: const Offset(0, 4),
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
                                      : pagePrimaryTextColor(context),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  breakLabels[index],
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : pagePrimaryTextColor(context),
                                    fontSize: 11,
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
              const SizedBox(height: 9),
              Text(
                selectedLevel == null
                    ? 'Optional, but useful for spotting recovery patterns over time.'
                    : 'Recovery logged as ${breakLabels[selectedLevel - 1].toLowerCase()}.',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF5EEAD4)
                      : const Color(0xFF0F766E),
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
