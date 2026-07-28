import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalysync/features/log/presentation/pages/welcome_back_baseline_page.dart';
import 'package:vitalysync/features/profile/presentation/pages/retake_baseline_questionnaire_page.dart';

void main() {
  testWidgets('welcome-back screen uses gentle baseline-only copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WelcomeBackBaselinePage(
          username: 'Mika',
          onSave: (_) async => true,
        ),
      ),
    );

    expect(find.text('Welcome back, Mika'), findsOneWidget);
    expect(
      find.textContaining('This is only the baseline questions.'),
      findsOneWidget,
    );
    expect(find.textContaining('does not diagnose'), findsOneWidget);
    expect(find.text('Refresh baseline'), findsOneWidget);
    expect(find.textContaining('streak'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('refresh-baseline-button')));
    await tester.pumpAndSettle();

    expect(find.byType(RetakeBaselineQuestionnairePage), findsOneWidget);
    expect(find.text('Refresh baseline'), findsOneWidget);
  });
}
