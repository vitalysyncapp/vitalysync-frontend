import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/features/adaptive/data/nudge_alternative_controller.dart';
import 'package:vitalysync/features/adaptive/data/nudge_selection.dart';
import 'package:vitalysync/features/adaptive/data/adaptive_nudge_api.dart';
import 'package:vitalysync/shared/notifications/smart_nudge_delivery_service.dart';
import 'package:vitalysync/l10n/app_copy.dart';
import 'package:flutter/widgets.dart';

const firstId = '1234567890abcdef1234567890abcdef';
const nextId = '234567890abcdef1234567890abcdef1';
Map<String, dynamic> nudge({
  String id = firstId,
  String? schedule,
  List<String> cancelled = const [],
}) => {
  'title': 'Make room for a pause',
  'message':
      'Before your next task, take a two-minute break away from your screen.\n\nThere is no need to rush.',
  'nudge_type': 'maintenance',
  'metadata': {
    'content_id': id,
    'action_id': 'screen_break',
    'context_hash': 'week_one',
    'locale': 'en',
    'delivery': {
      'state': 'pending',
      'scheduled_for': schedule ?? '2026-01-01T08:00:00+08:00',
      'trigger': 'context_update',
      'cancelled_content_ids': cancelled,
    },
  },
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'user_id': 1,
      'app_language': 'english',
    }),
  );

  test('new flow states have Filipino localization', () {
    for (final text in [
      'Finding another idea…',
      'Review earlier ideas',
      'You’ve explored the ideas that fit right now.',
      'Couldn’t load another idea. Your current one is still here.',
    ]) {
      expect(localizeAppCopy(text, const Locale('fil')), isNot(text));
    }
  });

  test(
    'another idea retains current content, blocks duplicate taps, and only swaps after success',
    () async {
      final controller = NudgeAlternativeController();
      addTearDown(controller.dispose);
      var current = 'original';
      var saves = 0;
      var fetches = 0;
      final result = Completer<NudgeSelection<String>>();
      Future<void> request() => controller.request<String>(
        metadata: Map.from(nudge()['metadata']),
        save: () async {
          saves++;
        },
        fetch: (excluded, mode) {
          fetches++;
          expect(excluded, ['screen_break']);
          expect(mode, 'next');
          return result.future;
        },
        replace: (value) => current = value,
      );
      final pending = request();
      await request();
      await Future<void>.delayed(Duration.zero);
      expect(controller.loading, true);
      expect(current, 'original');
      expect(saves, 1);
      expect(fetches, 1);
      result.complete(const NudgeSelection(item: 'replacement'));
      await pending;
      expect(current, 'replacement');
      expect(controller.loading, false);
    },
  );

  test(
    'retry does not save skip twice; exhaustion offers explicit review and resets visited pass',
    () async {
      final controller = NudgeAlternativeController();
      addTearDown(controller.dispose);
      var saves = 0;
      var attempts = 0;
      final modes = <String>[];
      Future<void> request({bool review = false}) => controller.request<String>(
        metadata: Map.from(nudge()['metadata']),
        reviewEarlier: review,
        save: () async {
          saves++;
        },
        fetch: (excluded, mode) async {
          modes.add(mode);
          if (attempts++ == 0) throw Exception('offline');
          return const NudgeSelection(canRevisit: true);
        },
        replace: (_) => fail('There is no replacement'),
      );
      await request();
      expect(controller.hasError, true);
      await request();
      expect(saves, 1);
      expect(controller.canRevisit, true);
      await request(review: true);
      expect(modes, ['next', 'next', 'revisit']);
      controller.contextChanged('new_day');
      expect(controller.hasInteracted, false);
      expect(controller.canRevisit, false);
    },
  );

  test(
    'a stale alternative cannot replace content after context changes',
    () async {
      final controller = NudgeAlternativeController();
      addTearDown(controller.dispose);
      final response = Completer<NudgeSelection<String>>();
      var replacements = 0;
      final pending = controller.request<String>(
        metadata: Map.from(nudge()['metadata']),
        save: () async {},
        fetch: (_, _) => response.future,
        replace: (_) => replacements++,
      );
      await Future<void>.delayed(Duration.zero);
      controller.contextChanged('changed');
      response.complete(const NudgeSelection(item: 'stale'));
      await pending;
      expect(replacements, 0);
      expect(controller.loading, false);
    },
  );

  test(
    'strict alternative requests reject cached or generic responses',
    () async {
      await http.runWithClient(
        () async {
          await expectLater(
            AdaptiveNudgeApi.anotherIdea(excludeActionIds: ['screen_break']),
            throwsException,
          );
        },
        () => MockClient(
          (_) async => http.Response(
            jsonEncode({
              'recommendations': [nudge()],
            }),
            200,
          ),
        ),
      );
    },
  );

  for (final scheduled in [false, true]) {
    test(
      'notification reuses exact copy and ${scheduled ? 'scheduled' : 'immediate'} timestamp across engines and restarts',
      () async {
        var alerts = 0;
        var claims = 0;
        var serverClaimed = false;
        final canonical = nudge(
          schedule: scheduled ? '2030-01-01T08:15:00+08:00' : null,
        );
        final actual = <Map<String, dynamic>>[];
        Future<String> show({
          required int id,
          required String title,
          required String body,
          required String payload,
          DateTime? scheduledFor,
        }) async {
          alerts++;
          actual.add({
            'id': id,
            'title': title,
            'body': body,
            'payload': payload,
            'date': scheduledFor,
          });
          return scheduled ? 'scheduled' : 'sent';
        }

        SmartNudgeDeliveryService engine() =>
            SmartNudgeDeliveryService.forTesting(
              show: show,
              cancel: (_) async {},
            );
        await http.runWithClient(
          () async {
            await Future.wait([
              engine().deliver(canonical),
              engine().deliver(canonical),
            ]);
            await engine().deliver(
              canonical,
            ); // A new service instance simulates restart.
            expect(alerts, 1);
            expect(claims, greaterThanOrEqualTo(1));
            expect(actual.single['title'], canonical['title']);
            expect(actual.single['body'], canonical['message']);
            expect(
              actual.single['date'],
              DateTime.parse(
                (canonical['metadata'] as Map)['delivery']['scheduled_for'],
              ),
            );
            final opened = await engine().readNotification(
              actual.single['payload'] as String,
            );
            expect(opened, canonical);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('user_id', 2);
            expect(
              await engine().readNotification(
                actual.single['payload'] as String,
              ),
              isNull,
            );
          },
          () => MockClient((request) async {
            final body = jsonDecode(request.body) as Map;
            if (body['operation'] == 'claim') {
              claims++;
              final granted = !serverClaimed;
              serverClaimed = true;
              return http.Response(
                jsonEncode({
                  'claimed': granted,
                  'token': 'lease',
                  'recommendation': canonical,
                }),
                200,
              );
            }
            return http.Response(
              jsonEncode({'recommendation': canonical}),
              200,
            );
          }),
        );
      },
    );
  }

  test(
    'an acknowledgment failure retries the acknowledgment without another alert',
    () async {
      var alerts = 0;
      var acks = 0;
      var claims = 0;
      final service = SmartNudgeDeliveryService.forTesting(
        show:
            ({
              required id,
              required title,
              required body,
              required payload,
              scheduledFor,
            }) async {
              alerts++;
              return 'sent';
            },
        cancel: (_) async {},
      );
      await http.runWithClient(
        () async {
          await service.deliver(nudge());
          await service.deliver(nudge());
          expect(alerts, 1);
          expect(claims, 1);
          expect(acks, 2);
        },
        () => MockClient((request) async {
          final operation = (jsonDecode(request.body) as Map)['operation'];
          if (operation == 'claim') {
            claims++;
            return http.Response(
              jsonEncode({
                'claimed': true,
                'token': 'lease',
                'recommendation': nudge(),
              }),
              200,
            );
          }
          expect(operation, 'sent');
          return ++acks == 1
              ? http.Response('{}', 503)
              : http.Response('{}', 200);
        }),
      );
    },
  );

  test(
    'permission denial keeps saved content and records suppression',
    () async {
      final operations = <String>[];
      final service = SmartNudgeDeliveryService.forTesting(
        show:
            ({
              required id,
              required title,
              required body,
              required payload,
              scheduledFor,
            }) async => 'suppressed',
        cancel: (_) async {},
      );
      await http.runWithClient(
        () async {
          await service.deliver(nudge());
          expect(operations, ['claim', 'suppressed']);
          expect(
            (await service.readNotification(
              SmartNudgeDeliveryService.payload(1, firstId),
            ))?['message'],
            nudge()['message'],
          );
        },
        () => MockClient((request) async {
          operations.add(
            (jsonDecode(request.body) as Map)['operation'] as String,
          );
          return http.Response(
            jsonEncode({
              'claimed': true,
              'token': 'lease',
              'recommendation': nudge(),
            }),
            200,
          );
        }),
      );
    },
  );

  test(
    'device delivery failures retry; replacement and snooze cancel the same notification ID',
    () async {
      var alerts = 0;
      final cancelled = <int>[];
      final operations = <String>[];
      final service = SmartNudgeDeliveryService.forTesting(
        show:
            ({
              required id,
              required title,
              required body,
              required payload,
              scheduledFor,
            }) async {
              if (++alerts == 1) throw Exception('device unavailable');
              return 'scheduled';
            },
        cancel: (id) async {
          cancelled.add(id);
        },
      );
      await http.runWithClient(
        () async {
          await service.deliver(nudge());
          await service.deliver(nudge());
          expect(operations, ['claim', 'failed', 'claim', 'scheduled']);
          await service.deliver(nudge(id: nextId, cancelled: [firstId]));
          expect(
            cancelled,
            contains(SmartNudgeDeliveryService.notificationId(firstId)),
          );
          await service.cancel(nudge(id: nextId));
          final count = alerts;
          await service.deliver(nudge(id: nextId));
          expect(alerts, count);
          expect(
            cancelled,
            contains(SmartNudgeDeliveryService.notificationId(nextId)),
          );
        },
        () => MockClient((request) async {
          operations.add(
            (jsonDecode(request.body) as Map)['operation'] as String,
          );
          final id =
              request.url.pathSegments[request.url.pathSegments.length - 2];
          return http.Response(
            jsonEncode({
              'claimed': true,
              'token': 'lease',
              'recommendation': nudge(id: id),
            }),
            200,
          );
        }),
      );
    },
  );

  test('notification payload validation isolates content identity', () {
    expect(
      SmartNudgeDeliveryService.parsePayload('smart_nudge:1:invalid'),
      isNull,
    );
    expect(
      SmartNudgeDeliveryService.parsePayload(
        SmartNudgeDeliveryService.payload(1, firstId),
      )?.contentId,
      firstId,
    );
  });

  test(
    'disabled notifications and account changes suppress device delivery',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', false);
      final operations = <String>[];
      final service = SmartNudgeDeliveryService.forTesting(
        show:
            ({
              required id,
              required title,
              required body,
              required payload,
              scheduledFor,
            }) async {
              fail('Preferences must prevent an alert');
            },
        cancel: (_) async {},
      );
      await http.runWithClient(
        () async {
          await service.deliver(nudge());
          expect(operations, ['claim', 'suppressed']);
          await prefs.setInt('user_id', 2);
          await service.deliver(nudge(), expectedUserId: 1);
          expect(operations, ['claim', 'suppressed']);
        },
        () => MockClient((request) async {
          operations.add(
            (jsonDecode(request.body) as Map)['operation'] as String,
          );
          return http.Response(
            jsonEncode({
              'claimed': true,
              'token': 'lease',
              'recommendation': nudge(),
            }),
            200,
          );
        }),
      );
    },
  );
}
