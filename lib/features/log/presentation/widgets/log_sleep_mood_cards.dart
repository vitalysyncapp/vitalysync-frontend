part of 'log_widgets.dart';

extension _LogSleepMoodCards on LogWidgets {
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
                                  ).withValues(alpha: 0.16),
                                  blurRadius: 14,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
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
                                                ).withValues(alpha: 0.45),
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
                                                  ).withValues(alpha: 0.45),
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
}
