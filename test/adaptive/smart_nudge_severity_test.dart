import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalysync/features/adaptive/data/adaptive_nudge_api.dart';
import 'package:vitalysync/features/home/presentation/widgets/smart_nudge.dart';

void main() {
  test('adaptive nudge maps internal severity to user-facing labels', () {
    final needsSupport = AdaptiveNudgeRecommendation.fromJson({
      'priority': 'urgent',
      'severity': 'critical',
    });
    final watch = AdaptiveNudgeRecommendation.fromJson({
      'priority': 'medium',
      'severity': 'moderate',
    });

    expect(needsSupport.userFacingSeverity, 'needs support');
    expect(watch.userFacingSeverity, 'watch');
  });

  testWidgets('smart nudge card never renders critical as a user label', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SmartNudgeCard(
            severity: 'critical',
            message: 'Alex, lower one demand and reach out if needed.',
          ),
        ),
      ),
    );

    expect(find.text('Needs Support'), findsOneWidget);
    expect(find.text('Critical'), findsNothing);
  });
}
