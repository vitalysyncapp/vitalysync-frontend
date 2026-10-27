import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/features/log/data/log_api.dart';
import 'package:vitalysync/features/log/presentation/pages/log_page.dart';
import 'package:vitalysync/shared/notifications/notification_payload_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'user_id': 7,
      'app_token': 'test-token',
    });
  });

  testWidgets('full form opens first and a right swipe reveals quick presets', (
    tester,
  ) async {
    final today = LogApi.todayKey();
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/check-in/status')) {
        return http.Response(
          jsonEncode({
            'required_mode': 'daily',
            'has_today_log': false,
            'schedule': {'is_due': false, 'next_due_date': today},
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
        return http.Response(jsonEncode({'presets': []}), 200);
      }
      return http.Response('{}', 200);
    });
    final controller = LogPageController();
    await tester.binding.setSurfaceSize(const Size(390, 844));

    await http.runWithClient(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LogPage(controller: controller)),
        ),
      );
      await _flushWidgets(tester);

      expect(find.byKey(const ValueKey('log_form')), findsOneWidget);
      expect(find.text('Quick check-ins'), findsNothing);
      expect(controller.value.isFormVisible, isTrue);
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.byKey(const ValueKey('quick-check-in-swipe-hint')),
            )
            .opacity,
        1,
      );

      await tester.drag(
        find.byKey(const ValueKey('log-surface-page-view')),
        const Offset(320, 0),
      );
      await tester.pumpAndSettle();

      expect(find.text('Quick check-ins'), findsOneWidget);
      expect(find.byKey(const ValueKey('add-quick-check-in')), findsOneWidget);
      expect(controller.value.isFormVisible, isFalse);
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.byKey(const ValueKey('quick-check-in-swipe-hint')),
            )
            .opacity,
        0,
      );

      await tester.drag(
        find.byKey(const ValueKey('log-surface-page-view')),
        const Offset(-320, 0),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const ValueKey('log_form')), findsOneWidget);

      controller.showQuickPresets();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Quick check-ins'), findsOneWidget);
      expect(controller.value.isFormVisible, isFalse);
    }, () => client);

    await tester.binding.setSurfaceSize(null);
  });

  test('overlay quick check-in payload targets the preset catalog', () {
    expect(shouldOpenQuickCheckIns('quick_check_in'), isTrue);
    expect(shouldOpenQuickCheckIns('nutrition_log'), isFalse);
  });
}

Future<void> _flushWidgets(WidgetTester tester) async {
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
