import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/app/permissions/first_install_permission_coordinator.dart';
import 'package:vitalysync/app/permissions/first_install_permission_gate.dart';
import 'package:vitalysync/features/settings/presentation/pages/notification_settings_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const notificationSettingsChannel = MethodChannel(
    'vitalysync/notification_settings',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(notificationSettingsChannel, null);
  });

  test('first-install permissions run once in the required order', () async {
    final order = <String>[];
    var completed = false;
    final coordinator = _coordinator(
      order: order,
      isCompleted: () async => completed,
      markCompleted: () async {
        order.add('complete');
        completed = true;
      },
    );

    await coordinator.run(
      notificationSoundStep: () async => order.add('sound'),
    );
    await coordinator.run(
      notificationSoundStep: () async => order.add('unexpected sound'),
    );

    expect(order, [
      'notification',
      'sound',
      'location',
      'activity',
      'schedule',
      'complete',
    ]);
  });

  testWidgets('permission gate waits for the sound step before location', (
    tester,
  ) async {
    final order = <String>[];
    final coordinator = _coordinator(order: order);

    await tester.pumpWidget(
      MaterialApp(
        home: FirstInstallPermissionGate(
          coordinator: coordinator,
          child: const Text('Main app ready'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Turn on notification sound'), findsOneWidget);
    expect(order, ['notification']);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(find.text('Main app ready'), findsOneWidget);
    expect(order, [
      'notification',
      'location',
      'activity',
      'schedule',
      'complete',
    ]);
  });

  testWidgets('sound step opens Android notification settings', (tester) async {
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(notificationSettingsChannel, (call) async {
          calls.add(call.method);
          return true;
        });

    await tester.pumpWidget(
      MaterialApp(
        home: FirstInstallPermissionGate(
          coordinator: _coordinator(order: <String>[]),
          child: const Text('Main app ready'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(
      find.byKey(const ValueKey('open-notification-sound-settings')),
    );
    await tester.pumpAndSettle();

    expect(calls, ['openNotificationSettings']);
    expect(find.text('Main app ready'), findsOneWidget);
  });

  testWidgets('notification page exposes the Android sound shortcut', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: NotificationSettingsPage()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Notification sound'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('open-system-notification-settings')),
      findsOneWidget,
    );
  });
}

FirstInstallPermissionCoordinator _coordinator({
  required List<String> order,
  Future<bool> Function()? isCompleted,
  Future<void> Function()? markCompleted,
}) {
  return FirstInstallPermissionCoordinator(
    isAndroid: () => true,
    isCompleted: isCompleted ?? () async => false,
    markCompleted:
        markCompleted ??
        () async {
          order.add('complete');
        },
    requestNotificationPermission: () async {
      order.add('notification');
    },
    requestLocationPermission: () async {
      order.add('location');
    },
    requestActivityPermission: () async {
      order.add('activity');
    },
    refreshNotificationSchedule: () async {
      order.add('schedule');
    },
  );
}
