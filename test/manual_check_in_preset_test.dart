import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/features/log/data/log_api.dart';
import 'package:vitalysync/features/log/data/quick_check_in_preset.dart';
import 'package:vitalysync/features/log/data/quick_check_in_preset_api.dart';
import 'package:vitalysync/features/log/presentation/pages/log_page.dart';
import 'package:vitalysync/features/log/presentation/widgets/log_widgets.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(configureTestAssets);
  tearDownAll(clearTestAssets);

  testWidgets('manual result saves its completed answers as a quick check-in', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'user_id': 7,
      'app_token': 'test-token',
    });
    final presetPosts = <Map<String, dynamic>>[];
    final stalePresetFetch = Completer<http.Response>();
    final client = MockClient((request) async {
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
      if (request.method == 'POST' &&
          request.url.path.endsWith('/check-in-presets')) {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        presetPosts.add(body);
        return http.Response(
          jsonEncode({
            'preset': {'preset_id': 8 + presetPosts.length, ...body},
          }),
          201,
        );
      }
      if (request.url.path.endsWith('/check-in-presets')) {
        return stalePresetFetch.future;
      }
      if (request.method == 'POST' && request.url.path.endsWith('/check-in')) {
        return http.Response(
          jsonEncode({
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
    addTearDown(controller.dispose);

    await http.runWithClient(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LogPage(controller: controller)),
        ),
      );
      await _flush(tester);

      final form = tester.widget<LogWidgets>(find.byType(LogWidgets));
      form.onEnergyChanged(4);
      form.onExerciseToggle('Walking');
      form.onSymptomToggle('None');
      form.onHabitToggle('Quiet break');
      form.onPerceivedStressChanged(3);
      form.onBreakQualityChanged(4);
      form.onDailyDetachmentChanged(2);
      form.onDailyFocusChanged(4);
      form.onDailyAccomplishmentChanged(5);
      await tester.pump();
      await controller.save();
      await _flush(tester);

      final saveAction = find.byKey(
        const ValueKey('save-manual-as-quick-check-in'),
      );
      expect(saveAction, findsOneWidget);
      await tester.ensureVisible(saveAction);
      await tester.tap(saveAction);
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('saved-check-in-preset-name')),
        'Restful morning',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('quick-avatar-calm')),
      );
      await tester.tap(find.byKey(const ValueKey('quick-avatar-calm')));
      final confirm = find.byKey(
        const ValueKey('confirm-saved-check-in-preset'),
      );
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await _flush(tester);

      expect(presetPosts, hasLength(1));
      expect(presetPosts.single['name'], 'Restful morning');
      expect(presetPosts.single['avatar_id'], 'calm');
      final daily = presetPosts.single['daily'] as Map<String, dynamic>;
      expect(daily['energy_level'], 4);
      expect(daily['exercise_names'], ['Walking']);
      expect(daily['daily_accomplishment_level'], 5);
      expect(saveAction, findsNothing);
      controller.showQuickPresets();
      await _flush(tester);
      expect(find.text('Restful morning'), findsOneWidget);

      // A request started before the save must not remove the new tile.
      stalePresetFetch.complete(
        http.Response(jsonEncode({'presets': []}), 200),
      );
      await _flush(tester);
      expect(find.text('Restful morning'), findsOneWidget);
      expect(
        (await QuickCheckInPresetApi.instance.readCache()).single.name,
        'Restful morning',
      );

      // Saving from another surface should update the mounted Log catalog too.
      await QuickCheckInPresetApi.instance.create(
        QuickCheckInPreset.fromJson({
          'preset_id': 0,
          ...presetPosts.single,
          'name': 'From assistant',
        }),
      );
      await tester.pump();
      expect(find.text('From assistant'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }, () => client);
  });
}

Future<void> _flush(WidgetTester tester) async {
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
