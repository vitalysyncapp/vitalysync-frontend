part of 'log_widgets.dart';

const _weeklyReflectionColor = Color(0xFF8B5CF6);
const _weeklyReflectionIconBg = Color(0xFFF3E8FF);

const _weeklyCategoryLabels = {
  'emotional_exhaustion': 'Emotional exhaustion',
  'depersonalization': 'Detachment',
  'personal_accomplishment': 'Accomplishment',
};

const _weeklyCategoryIcons = {
  'emotional_exhaustion': Icons.battery_alert_rounded,
  'depersonalization': Icons.link_off_rounded,
  'personal_accomplishment': Icons.emoji_events_rounded,
};

/// Weekly reflection questions rendered inline after the daily essentials,
/// using the same card style as the daily likert questions.
extension _LogWeeklyReflectionCards on LogWidgets {
  void _addWeeklyReflectionCards(void Function(String id, Widget child) add) {
    add('weekly-intro', _buildWeeklyReflectionIntroCard());
    for (final section in kBurnoutWeeklySections) {
      final count = section.questions.length;
      for (var index = 0; index < count; index++) {
        final question = section.questions[index];
        add(
          'weekly-${question.questionKey}',
          _buildWeeklyQuestionCard(
            category: section.category,
            questionKey: question.questionKey,
            questionText: question.questionText,
            position: index + 1,
            count: count,
          ),
        );
      }
    }
  }

  Widget _buildWeeklyReflectionIntroCard() {
    final answered = weeklyAnswers.length.clamp(0, kWeeklyQuestionCount);

    return _buildCard(
      accentColor: _weeklyReflectionColor,
      child: Builder(
        builder: (context) {
          final accent = pageAccentColor(context, _weeklyReflectionColor);
          final reduceMotion = MediaQuery.of(context).disableAnimations;

          return Column(
            key: const ValueKey('weekly-reflection-inline'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(
                icon: Icons.calendar_view_week_rounded,
                iconBg: _weeklyReflectionIconBg,
                iconColor: _weeklyReflectionColor,
                title: 'Weekly reflection',
                subtitle:
                    'Think about the past seven days. Scored separately from your daily index.',
                subtitleMaxLines: 3,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(end: answered / kWeeklyQuestionCount),
                        duration: reduceMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return LinearProgressIndicator(
                            value: value,
                            minHeight: 7,
                            backgroundColor: pageSubtleSurfaceColor(context),
                            valueColor: AlwaysStoppedAnimation(accent),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  LocalizedText(
                    '$answered of $kWeeklyQuestionCount answered',
                    style: TextStyle(
                      color: accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              LocalizedText(
                'Custom Maslach-based reflection. This is an adaptation, not the official MBI or a diagnosis.',
                style: TextStyle(
                  color: pageSecondaryTextColor(context),
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWeeklyQuestionCard({
    required String category,
    required String questionKey,
    required String questionText,
    required int position,
    required int count,
  }) {
    final label = _weeklyCategoryLabels[category] ?? 'Weekly reflection';

    return _buildLikertLevelCard(
      icon: _weeklyCategoryIcons[category] ?? Icons.psychology_alt_rounded,
      iconBg: _weeklyReflectionIconBg,
      iconColor: _weeklyReflectionColor,
      title: '$label · $position/$count',
      subtitle: questionText,
      subtitleMaxLines: 4,
      labels: [for (final option in kBurnoutBaselineScale) option.label],
      selectedLevel: weeklyAnswers[questionKey],
      onChanged: (value) => onWeeklyAnswerChanged?.call(questionKey, value),
      emptyMessage: 'How often did this happen over the past seven days?',
      selectedMessagePrefix: 'Answered',
    );
  }
}
