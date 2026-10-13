import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../onboarding/widgets/onboarding_card.dart';
import '../../data/assessment_models.dart';

class AssessmentResultCard extends StatelessWidget {
  final AssessmentRecord assessment;
  const AssessmentResultCard({super.key, required this.assessment});

  @override
  Widget build(BuildContext context) => OnboardingCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Exhaustion assessment — CBI Personal Burnout',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Text(
          '${assessment.displayScore} / 100',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Complete · ${DateFormat('MMM d, yyyy · h:mm a', 'en').format(assessment.completedAt.toLocal())}',
        ),
        const SizedBox(height: 8),
        const Text(
          'Self-reported physical and psychological exhaustion. This is not a diagnosis or probability. Daily logs and lifestyle-context answers do not change this score.',
        ),
      ],
    ),
  );
}
