import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/features/log/data/check_in_models.dart';
import 'package:vitalysync/features/log/data/log_api.dart';
import 'package:vitalysync/features/log/data/quick_check_in_preset.dart';
import 'package:vitalysync/features/log/presentation/pages/log_page.dart';
import 'package:vitalysync/features/log/presentation/widgets/quick_check_in_confirmation_dialog.dart';
import 'package:vitalysync/features/onboarding/data/burnout_baseline_questions.dart';

import '../helpers/test_helpers.dart';

void main() {
  setUpAll(configureTestAssets);
  tearDownAll(clearTestAssets);

  test(
    'all bundled illustrations decode with the Flutter SVG renderer',
    () async {
      for (final avatar in QuickCheckInAvatarCatalog.entries) {
        final svg = await File(avatar.assetPath).readAsString();
        final picture = await vg.loadPicture(SvgStringLoader(svg), null);
        expect(picture.size.isEmpty, isFalse, reason: avatar.id);
        picture.picture.dispose();
      }
    },
  );

  testWidgets(
    'preview includes all daily answers in one pipe-separated paragraph',
    (tester) async {
      await _openPreview(tester, _preset);
      final summary = tester
          .widget<Text>(
            find.byKey(const ValueKey('quick-check-in-preview-values')),
          )
          .data!;
      expect(summary.split(' | '), hasLength(14));
      for (final value in [
        'Sleep: 7.5h',
        'Sleep quality: Very good (4/5)',
        'Mood: Very happy (5/5)',
        'Energy: 4/5',
        'Hydration: 2L',
        'Workload: 5-6 hours',
        'Exercise: Walking',
        'Symptoms: None',
        'Recovery habits: Quiet break',
        'Pressure: 3/5',
        'Recovery breaks: 4/5',
        'Detachment: 2/5',
        'Focus: 4/5',
        'Accomplishment: 5/5',
      ]) {
        expect(summary, contains(value));
      }
      expect(find.text('Productive'), findsOneWidget);
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'weekly preview includes nine inputs and all eleven reflection answers',
    (tester) async {
      final preset = QuickCheckInPreset(
        presetId: 2,
        name: 'Weekly reset',
        mode: CheckInMode.weekly,
        avatarId: 'mindful',
        draft: _draft,
        weeklyAnswers: {
          for (final section in kBurnoutWeeklySections)
            for (final question in section.questions) question.questionKey: 3,
        },
      );
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _openPreview(tester, preset, dark: true, textScale: 1.5);
      final summary = tester
          .widget<Text>(
            find.byKey(const ValueKey('quick-check-in-preview-values')),
          )
          .data!;
      expect(summary.split(' | '), hasLength(20));
      for (final section in kBurnoutWeeklySections) {
        for (final question in section.questions) {
          expect(
            summary,
            contains('${question.questionText}: Sometimes (3/5)'),
          );
        }
      }
      expect(summary, isNot(contains('Pressure:')));
      expect(
        find.byKey(const ValueKey('quick-check-in-confirm')).hitTestable(),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('quick-check-in-edit')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'preview dismiss and edit never log; confirm saves the reviewed preset once',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'user_id': 7,
        'app_token': 'test-token',
      });
      final posted = <Map<String, dynamic>>[];
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith('/check-in/status')) {
          return http.Response(
            jsonEncode({
              'required_mode': 'daily',
              'has_today_log': false,
              'schedule': {'is_due': false, 'next_due_date': LogApi.todayKey()},
              'existing_check_in': null,
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/logs/today')) {
          return http.Response(
            jsonEncode({
              'streak': {'current_streak': 2},
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/check-in-presets')) {
          return http.Response(
            jsonEncode({
              'presets': [_preset.toJson()],
            }),
            200,
          );
        }
        if (request.method == 'POST' &&
            request.url.path.endsWith('/check-in')) {
          posted.add(jsonDecode(request.body) as Map<String, dynamic>);
          return http.Response(
            jsonEncode({
              'log': _draft.dailyJson(),
              'streak': {'current_streak': 3},
            }),
            201,
          );
        }
        return http.Response('{}', 200);
      });
      final controller = LogPageController();
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await http.runWithClient(() async {
        await pumpTestApp(tester, LogPage(controller: controller));
        await _flush(tester);
        controller.showQuickPresets();
        await _flush(tester);
        final tile = find.byKey(const ValueKey('quick-preset-1'));

        await tester.tap(tile);
        await _flush(tester);
        expect(
          find.byKey(const ValueKey('quick-check-in-confirmation')),
          findsOneWidget,
        );
        expect(
          find.text(
            'Productive will replace the answers already saved for today.',
          ),
          findsNothing,
        );
        expect(posted, isEmpty);
        await tester.tap(find.byTooltip('Close'));
        await _flush(tester);
        expect(posted, isEmpty);

        await tester.tap(tile);
        await _flush(tester);
        await tester.tap(find.byKey(const ValueKey('quick-check-in-edit')));
        await _flush(tester);
        expect(find.text('Edit quick check-in'), findsOneWidget);
        final nameField = tester.widget<TextField>(
          find.byKey(const ValueKey('quick-check-in-name')),
        );
        expect(nameField.controller!.text, 'Productive');
        expect(posted, isEmpty);
        expect(requests.where((request) => request.method != 'GET'), isEmpty);
        await tester.tap(find.byTooltip('Close'));
        await _flush(tester);

        await tester.tap(tile);
        await _flush(tester);
        await tester.tap(find.byKey(const ValueKey('quick-check-in-confirm')));
        await _flush(tester);
        expect(posted, hasLength(1));
        expect(
          find.byKey(const ValueKey('save-manual-as-quick-check-in')),
          findsNothing,
        );
        expect(posted.single['daily'], containsPair('sleep_hours', 7.5));
        expect(posted.single['daily'], containsPair('hydration_liters', 2.0));
        expect(
          posted.single['daily'],
          containsPair('daily_accomplishment_level', 5),
        );
        expect(
          find.byKey(const ValueKey('quick-check-in-confirmation')),
          findsNothing,
        );
        controller.showQuickPresets();
        await _flush(tester);
        await tester.tap(tile);
        await _flush(tester);
        expect(
          find.text(
            'Productive will replace the answers already saved for today.',
          ),
          findsOneWidget,
        );
        await tester.tap(find.byTooltip('Close'));
        await _flush(tester);
        expect(posted, hasLength(1));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await _flush(tester);
      }, () => client);
      controller.dispose();
    },
  );
}

Future<void> _openPreview(
  WidgetTester tester,
  QuickCheckInPreset preset, {
  bool dark = false,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? ThemeData.dark() : ThemeData.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showQuickCheckInConfirmationDialog(
              context: context,
              preset: preset,
            ),
            child: const Text('Preview'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Preview'));
  await tester.pumpAndSettle();
}

Future<void> _flush(WidgetTester tester) async {
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

const _draft = CheckInDraft(
  sleepHours: 7.5,
  sleepQuality: 3,
  moodIndex: 4,
  energyLevel: 4,
  hydrationLiters: 2,
  workloadHoursBand: '5-6 hours',
  exerciseNames: {'Walking'},
  symptomNames: {'None'},
  habitNames: {'Quiet break'},
  perceivedPressureLevel: 3,
  recoveryRestLevel: 4,
  detachmentLevel: 2,
  productivityFocusLevel: 4,
  accomplishmentLevel: 5,
);
const _preset = QuickCheckInPreset(
  presetId: 1,
  name: 'Productive',
  mode: CheckInMode.daily,
  avatarId: 'productive',
  draft: _draft,
);
