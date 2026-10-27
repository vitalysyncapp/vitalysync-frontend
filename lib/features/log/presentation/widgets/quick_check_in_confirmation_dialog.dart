import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../l10n/localized_text.dart';
import '../../../../shared/theme/app_page_style.dart';
import '../../../onboarding/data/burnout_baseline_questions.dart';
import '../../data/check_in_models.dart';
import '../../data/quick_check_in_preset.dart';

enum QuickCheckInConfirmationAction { confirm, edit }

Future<QuickCheckInConfirmationAction?> showQuickCheckInConfirmationDialog({
  required BuildContext context,
  required QuickCheckInPreset preset,
  bool replacesToday = false,
}) {
  return showDialog<QuickCheckInConfirmationAction>(
    context: context,
    builder: (_) => _QuickCheckInConfirmationDialog(
      preset: preset,
      replacesToday: replacesToday,
    ),
  );
}

class _QuickCheckInConfirmationDialog extends StatelessWidget {
  const _QuickCheckInConfirmationDialog({
    required this.preset,
    required this.replacesToday,
  });

  final QuickCheckInPreset preset;
  final bool replacesToday;

  @override
  Widget build(BuildContext context) {
    final avatar = QuickCheckInAvatarCatalog.find(preset.avatarId);
    return Dialog(
      key: const ValueKey('quick-check-in-confirmation'),
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Container(
          decoration: buildPageDecoration(context).copyWith(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: pageBorderColor(context)),
            boxShadow: pageCardShadow(context),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: LocalizedText(
                        'Confirm quick check-in',
                        style: TextStyle(
                          color: pagePrimaryTextColor(context),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close'.localizedCopy(context),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    children: [
                      SvgPicture.asset(
                        avatar.assetPath,
                        width: 112,
                        height: 112,
                        semanticsLabel: avatar.semanticLabel.localizedCopy(
                          context,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        preset.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: pagePrimaryTextColor(context),
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      LocalizedText(
                        preset.mode == CheckInMode.weekly
                            ? 'Weekly check-in'
                            : 'Daily check-in',
                        style: TextStyle(
                          color: pageSecondaryTextColor(context),
                        ),
                      ),
                      if (replacesToday) ...[
                        const SizedBox(height: 12),
                        LocalizedText(
                          '${preset.name} will replace the answers already saved for today.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: pagePrimaryTextColor(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: pageSurfaceColor(context),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: pageBorderColor(context)),
                        ),
                        child: Text(
                          _summary(context, preset),
                          key: const ValueKey('quick-check-in-preview-values'),
                          style: TextStyle(
                            color: pagePrimaryTextColor(context),
                            fontSize: 14,
                            height: 1.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        key: const ValueKey('quick-check-in-edit'),
                        onPressed: () => Navigator.pop(
                          context,
                          QuickCheckInConfirmationAction.edit,
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 48),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: const LocalizedText('Edit'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        key: const ValueKey('quick-check-in-confirm'),
                        onPressed: () => Navigator.pop(
                          context,
                          QuickCheckInConfirmationAction.confirm,
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF16815F),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 48),
                        ),
                        child: const LocalizedText('Confirm'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _summary(BuildContext context, QuickCheckInPreset preset) {
  final draft = preset.draft;
  String translated(String value) => value.localizedCopy(context);
  String field(String label, String value) => '${translated(label)}: $value';
  String number(double value) => value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
  String rating(int? value) =>
      value == null ? translated('Not answered') : '$value/5';
  String selection(Set<String> values) => values.isEmpty
      ? translated('Not answered')
      : (values.toList()..sort()).map(translated).join(', ');
  String indexedRating(List<String> labels, int index) =>
      index >= 0 && index < labels.length
      ? '${translated(labels[index])} (${index + 1}/5)'
      : translated('Not answered');

  return [
    field('Sleep', '${number(draft.sleepHours)}h'),
    field(
      'Sleep quality',
      indexedRating(CheckInFormOptions.sleepLabels, draft.sleepQuality),
    ),
    field(
      'Mood',
      indexedRating(const [
        'Very sad',
        'Sad',
        'Neutral',
        'Happy',
        'Very happy',
      ], draft.moodIndex),
    ),
    field('Energy', rating(draft.energyLevel)),
    field('Hydration', '${number(draft.hydrationLiters)}L'),
    field('Workload', translated(draft.workloadHoursBand)),
    field('Exercise', selection(draft.exerciseNames)),
    field('Symptoms', selection(draft.symptomNames)),
    field('Recovery habits', selection(draft.habitNames)),
    if (preset.mode == CheckInMode.daily) ...[
      field('Pressure', rating(draft.perceivedPressureLevel)),
      field('Recovery breaks', rating(draft.recoveryRestLevel)),
      field('Detachment', rating(draft.detachmentLevel)),
      field('Focus', rating(draft.productivityFocusLevel)),
      field('Accomplishment', rating(draft.accomplishmentLevel)),
    ],
    if (preset.mode == CheckInMode.weekly)
      for (final section in kBurnoutWeeklySections)
        for (final question in section.questions)
          field(
            question.questionText,
            _weeklyAnswer(context, preset.weeklyAnswers[question.questionKey]),
          ),
  ].join(' | ');
}

String _weeklyAnswer(BuildContext context, int? value) {
  if (value == null || value < 1 || value > 5) {
    return 'Not answered'.localizedCopy(context);
  }
  final label = kBurnoutBaselineScale
      .firstWhere((option) => option.value == value)
      .label;
  return '${label.localizedCopy(context)} ($value/5)';
}
