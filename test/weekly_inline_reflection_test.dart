import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/features/log/data/check_in_models.dart';
import 'package:vitalysync/features/log/data/log_api.dart';
import 'package:vitalysync/features/log/presentation/pages/log_page.dart';
import 'package:vitalysync/shared/assistant/floating_smart_nudge_assistant.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'user_id': 1,
      'app_token': 'token-123',
    });
  });

  final today = LogApi.todayKey();

  testWidgets(
    'LogPage displays 11 weekly reflection cards inline after the 9 daily questions when weekly mode is active',
    (tester) async {
      final weeklyStatusJson = {
        'required_mode': 'weekly',
        'has_today_log': false,
        'schedule': {
          'is_due': true,
          'due_date': today,
          'next_due_date': today,
        },
        'daily_input_mode': 'weekly',
        'existing_check_in': null,
      };

      final client = MockClient((request) async {
        if (request.url.path.endsWith('/status')) {
          return http.Response(jsonEncode(weeklyStatusJson), 200);
        }
        if (request.url.path.endsWith('/logs/today')) {
          return http.Response(jsonEncode({'streak': {'current_streak': 3}}), 200);
        }
        if (request.url.path.endsWith('/weekly-assessment')) {
          return http.Response(
            jsonEncode({
              'is_due': true,
              'completed_today': false,
              'due_date': today,
              'today': null,
            }),
            200,
          );
        }
        return http.Response('{}', 200);
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LogPage(),
            ),
          ),
        );

        await flushWidgets(tester);

        // Header shows WEEKLY CHECK-IN and 9 practical inputs message
        expect(find.text('WEEKLY CHECK-IN'), findsOneWidget);
        expect(find.text('Your daily essentials'), findsOneWidget);

        // The 5 daily reflection cards are omitted
        expect(find.byKey(const ValueKey('log-card-daily-pressure')), findsNothing);
        expect(find.byKey(const ValueKey('log-card-daily-detachment')), findsNothing);
        expect(find.byKey(const ValueKey('log-card-recovery-breaks')), findsNothing);
        expect(find.byKey(const ValueKey('log-card-daily-focus')), findsNothing);
        expect(find.byKey(const ValueKey('log-card-daily-accomplishment')), findsNothing);

        // The 9 practical daily cards are present
        expect(find.byKey(const ValueKey('log-card-sleep-duration')), findsOneWidget);
        expect(find.byKey(const ValueKey('log-card-sleep-quality')), findsOneWidget);
        expect(find.byKey(const ValueKey('log-card-energy')), findsOneWidget);
        expect(find.byKey(const ValueKey('log-card-mood')), findsOneWidget);
        expect(find.byKey(const ValueKey('log-card-symptoms')), findsOneWidget);
        expect(find.byKey(const ValueKey('log-card-habits')), findsOneWidget);
        expect(find.byKey(const ValueKey('log-card-hydration')), findsOneWidget);
        expect(find.byKey(const ValueKey('log-card-workload')), findsOneWidget);
        expect(find.byKey(const ValueKey('log-card-exercise')), findsOneWidget);

        // The inline weekly cards are present directly on the screen
        expect(find.byKey(const ValueKey('log-card-weekly-intro')), findsOneWidget);
        expect(find.text('Weekly reflection'), findsOneWidget);
        expect(find.text('0 of 11 answered'), findsOneWidget);

        // Verify weekly question cards exist inline
        expect(find.byKey(const ValueKey('log-card-weekly-ee_01')), findsOneWidget);
        expect(find.byKey(const ValueKey('log-card-weekly-dp_01')), findsOneWidget);
        expect(find.byKey(const ValueKey('log-card-weekly-pa_01')), findsOneWidget);

        // Verify weekly question cards switch hierarchy:
        // Card header is smaller and lighter; sub question is bolder and larger.
        final headerText = tester.widget<Text>(
          find.descendant(
            of: find.byKey(const ValueKey('log-card-weekly-ee_01')),
            matching: find.text('Emotional exhaustion · 1/5'),
          ),
        );
        expect(headerText.style?.fontSize, 12.5);
        expect(headerText.style?.fontWeight, FontWeight.w600);

        final questionText = tester.widget<Text>(
          find.descendant(
            of: find.byKey(const ValueKey('log-card-weekly-ee_01')),
            matching: find.text('I feel emotionally drained by my daily responsibilities.'),
          ),
        );
        expect(questionText.style?.fontSize, 15.5);
        expect(questionText.style?.fontWeight, FontWeight.w800);

        // Standard cards (like the intro card) retain the primary header hierarchy
        final introTitle = tester.widget<Text>(
          find.descendant(
            of: find.byKey(const ValueKey('log-card-weekly-intro')),
            matching: find.text('Weekly reflection'),
          ),
        );
        expect(introTitle.style?.fontSize, 16.5);
        expect(introTitle.style?.fontWeight, FontWeight.w800);
      }, () => client);
    },
  );

  testWidgets(
    'Assistant check-in section displays weekly reflection inline when weekly mode is active',
    (tester) async {
      final weeklyStatus = CheckInStatus(
        requiredMode: CheckInMode.weekly,
        hasTodayLog: false,
        schedule: CheckInSchedule(
          isDue: true,
          dueDate: today,
          nextDueDate: today,
        ),
      );

      final client = MockClient((request) async {
        if (request.url.path.endsWith('/weekly-assessment')) {
          return http.Response(
            jsonEncode({
              'is_due': true,
              'completed_today': false,
              'due_date': today,
              'today': null,
            }),
            200,
          );
        }
        return http.Response('{}', 200);
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AssistantExperiencePanel(
                message: 'Hello',
                emoji: '😊',
                recommendations: const [],
                adaptiveNudges: const [],
                onRefreshRecommendations: () async => [],
                onRefreshAdaptiveNudges: ({forceRefresh = false}) async => [],
                onRefreshNutritionInsight: ({forceRefresh = false}) async => null,
                onRefreshEnvironment: () async => null,
                checkInStatusLoader: () async => weeklyStatus,
                todayLogLoader: () async => {'streak': {'current_streak': 2}},
                initialSectionIndex: 1, // Daily check-in section
              ),
            ),
          ),
        );

        await flushWidgets(tester);

        // The 9 practical questions are rendered
        expect(find.byKey(const ValueKey('log-card-sleep-duration')), findsOneWidget);
        expect(find.byKey(const ValueKey('log-card-exercise')), findsOneWidget);

        // The inline weekly reflection is rendered below the 9 questions
        expect(find.byKey(const ValueKey('log-card-weekly-intro')), findsOneWidget);
        expect(find.byKey(const ValueKey('log-card-weekly-ee_01')), findsOneWidget);
        expect(find.text('0 of 11 answered'), findsOneWidget);
      }, () => client);
    },
  );
}

Future<void> flushWidgets(WidgetTester tester) async {
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
