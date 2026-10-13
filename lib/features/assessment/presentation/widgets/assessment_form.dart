import 'package:flutter/material.dart';
import '../../../onboarding/widgets/likert_question.dart';
import '../../../onboarding/widgets/onboarding_card.dart';
import '../../data/assessment_models.dart';

/// All instrument content comes from the pinned backend definition. Plain Text
/// deliberately preserves its English wording regardless of app language.
class AssessmentForm extends StatelessWidget {
  final AssessmentDefinition definition;
  final Map<String, int> answers;
  final void Function(String, int?) onChanged;
  const AssessmentForm({
    super.key,
    required this.definition,
    required this.answers,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      OnboardingCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              definition.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(definition.explanation),
            const SizedBox(height: 12),
            Text(definition.contextExplanation),
            const SizedBox(height: 12),
            const Text(
              'Answer all six CBI questions to complete this assessment. You can leave the four lifestyle-context questions unanswered. Your draft is saved on this device.',
            ),
          ],
        ),
      ),
      for (final item in definition.items)
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: OnboardingCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.required
                      ? 'CBI Personal Burnout · Required'
                      : 'Lifestyle context · Optional · Not scored',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 12),
                LikertQuestion(
                  key: ValueKey(item.id),
                  question: item.text,
                  value: answers[item.id],
                  options: definition.options,
                  translate: false,
                  showLegend: true,
                  onChanged: (value) => onChanged(item.id, value),
                ),
                if (!item.required && answers.containsKey(item.id))
                  TextButton(
                    onPressed: () => onChanged(item.id, null),
                    child: const Text('Clear optional answer'),
                  ),
              ],
            ),
          ),
        ),
      const SizedBox(height: 16),
      ExpansionTile(
        title: const Text('Sources and assessment version'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              '${definition.version}\n\n${definition.attributions.join('\n\n')}',
            ),
          ),
        ],
      ),
    ],
  );
}
