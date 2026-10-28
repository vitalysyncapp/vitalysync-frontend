import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/app/main_navigation.dart';
import 'package:vitalysync/features/activity/data/activity_service.dart';
import 'package:vitalysync/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:vitalysync/features/onboarding/widgets/likert_question.dart';

import '../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(configureTestAssets);
  tearDownAll(clearTestAssets);

  testWidgets('repeated Next activation cannot skip the required wake time', (
    tester,
  ) async {
    configureLoggedInSession(onboardingCompleted: false);
    await pumpTestApp(tester, const OnboardingPage(userId: 1));
    await _chooseAndContinue(tester, 'Student');
    await _chooseAndContinue(tester, 'Lightly active');
    await _chooseAndContinue(tester, 'Improve sleep');
    await tester.enterText(
      find.byKey(const ValueKey('onboarding-height-field')),
      '170',
    );
    await tester.enterText(
      find.byKey(const ValueKey('onboarding-weight-field')),
      '65',
    );
    await _continue(tester);
    await tester.tap(find.text('Choose time'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('OK'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    final next = tester
        .widget<InkWell>(
          find
              .ancestor(of: find.text('Next'), matching: find.byType(InkWell))
              .last,
        )
        .onTap!;
    next();
    next();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('What time do you usually wake up?'), findsOneWidget);
    expect(find.text('Choose time'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final missingEarlierAnswer in [false, true]) {
    testWidgets(
      missingEarlierAnswer
          ? 'finish returns to an earlier missing answer without submitting'
          : 'repeated Finish saves the baseline once and opens the tutorial',
      (tester) async {
        configureLoggedInSession(onboardingCompleted: false);
        final preferences = await SharedPreferences.getInstance();
        // Native notification plugins are outside this navigation test.
        await preferences.setBool('notifications_enabled', false);
        Map<String, dynamic>? submitted;
        var submissionCount = 0;
        await http.runWithClient(
          () async {
            await pumpTestApp(tester, const OnboardingPage(userId: 1));
            await tester.pump();
            await _chooseAndContinue(tester, 'Student');
            await _chooseAndContinue(tester, 'Lightly active');
            await _chooseAndContinue(tester, 'Improve sleep');
            await tester.enterText(
              find.byKey(const ValueKey('onboarding-height-field')),
              '170',
            );
            await tester.enterText(
              find.byKey(const ValueKey('onboarding-weight-field')),
              '65',
            );
            final heightController = tester
                .widget<TextFormField>(
                  find.descendant(
                    of: find.byKey(const ValueKey('onboarding-height-field')),
                    matching: find.byType(TextFormField),
                  ),
                )
                .controller!;
            await _continue(tester);

            for (var time = 0; time < 2; time++) {
              await tester.tap(find.text('Choose time'));
              await tester.pump();
              await tester.pump(const Duration(milliseconds: 350));
              await tester.tap(find.text('OK'));
              await tester.pump();
              await tester.pump(const Duration(milliseconds: 350));
              await _continue(tester);
            }
            await _chooseAndContinue(tester, '3-4 days');
            tester
                .widget<LikertQuestion>(find.byType(LikertQuestion))
                .onChanged(3);
            await _continue(tester);
            await _chooseAndContinue(tester, 'No');

            for (var section = 0; section < 3; section++) {
              for (final question
                  in tester
                      .widgetList<LikertQuestion>(find.byType(LikertQuestion))
                      .toList()) {
                question.onChanged(3);
              }
              if (section < 2) await _continue(tester);
            }
            if (missingEarlierAnswer) heightController.clear();
            await tester.pump();
            final finish = find
                .ancestor(
                  of: find.text('Finish setup'),
                  matching: find.byType(InkWell),
                )
                .last;
            expect(tester.widget<InkWell>(finish).onTap, isNotNull);
            final finishCallback = tester.widget<InkWell>(finish).onTap!;
            finishCallback();
            if (!missingEarlierAnswer) finishCallback();
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 600));
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 1200));

            if (missingEarlierAnswer) {
              expect(submissionCount, 0);
              expect(
                find.text('What are your height and weight?'),
                findsOneWidget,
              );
              expect(
                find.text('Complete this step before finishing setup.'),
                findsOneWidget,
              );
              expect(preferences.getBool('onboarding_completed'), isFalse);
              expect(tester.takeException(), isNull);
              await tester.pumpWidget(const SizedBox.shrink());
              return;
            }
            expect(submissionCount, 1);
            expect(submitted?['burnout_answers'], hasLength(22));
            expect(find.byType(MainNavigation), findsOneWidget);
            expect(
              find.text('Welcome to your VitalySync tour'),
              findsOneWidget,
            );
            final prefs = await SharedPreferences.getInstance();
            expect(prefs.getBool('onboarding_completed'), isTrue);
            expect(tester.takeException(), isNull);

            await tester.pumpWidget(const SizedBox.shrink());
            await ActivityService.instance.disposeTracking();
            await tester.pump(const Duration(seconds: 1));
          },
          () => MockClient((request) async {
            if (request.method == 'POST' &&
                request.url.path.endsWith('/onboarding/submit')) {
              submissionCount++;
              submitted = jsonDecode(request.body) as Map<String, dynamic>;
              return http.Response(
                jsonEncode({'profile': submitted!['profile']}),
                201,
              );
            }
            return http.Response('{}', 200);
          }),
        );
      },
    );
  }
}

Future<void> _chooseAndContinue(WidgetTester tester, String option) async {
  await tester.tap(find.text(option));
  await _continue(tester);
}

Future<void> _continue(WidgetTester tester) async {
  await tester.pump();
  final next = find
      .ancestor(of: find.text('Next'), matching: find.byType(InkWell))
      .last;
  expect(tester.widget<InkWell>(next).onTap, isNotNull);
  tester.widget<InkWell>(next).onTap!();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));
}
