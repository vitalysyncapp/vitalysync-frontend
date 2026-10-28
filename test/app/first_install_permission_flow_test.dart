import 'dart:async';

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

    await coordinator.run();
    await coordinator.run();

    expect(order, [
      'notification',
      'location',
      'activity',
      'schedule',
      'complete',
    ]);
  });

  test('overlapping requests share one native permission flow', () async {
    final order = <String>[];
    final notificationResponse = Completer<void>();
    final coordinator = _coordinator(
      order: order,
      notificationResponse: () => notificationResponse.future,
    );

    final firstRun = coordinator.run();
    final secondRun = coordinator.run();
    expect(identical(firstRun, secondRun), isTrue);
    notificationResponse.complete();
    await Future.wait([firstRun, secondRun]);

    expect(order, [
      'notification',
      'location',
      'activity',
      'schedule',
      'complete',
    ]);
  });

  testWidgets(
    'native prompts keep the main app visible without a setup screen',
    (tester) async {
      final order = <String>[];
      final notificationResponse = Completer<void>();
      final coordinator = _coordinator(
        order: order,
        notificationResponse: () => notificationResponse.future,
      );

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

      expect(find.text('Main app ready'), findsOneWidget);
      expect(find.text('Preparing your device permissions...'), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      expect(order, ['notification']);

      notificationResponse.complete();
      await tester.pumpAndSettle();

      expect(find.text('Main app ready'), findsOneWidget);
      expect(order, [
        'notification',
        'location',
        'activity',
        'schedule',
        'complete',
      ]);
    },
  );

  testWidgets('permissions wait until enabled and do not repeat on rebuild', (
    tester,
  ) async {
    final order = <String>[];
    final coordinator = _coordinator(order: order);
    Widget buildApp({required bool enabled}) => MaterialApp(
      home: FirstInstallPermissionGate(
        enabled: enabled,
        coordinator: coordinator,
        child: const Text('Main app ready'),
      ),
    );

    await tester.pumpWidget(buildApp(enabled: false));
    await tester.pumpAndSettle();
    expect(order, isEmpty);
    expect(find.text('Main app ready'), findsOneWidget);

    await tester.pumpWidget(buildApp(enabled: true));
    await tester.pumpAndSettle();
    expect(order, [
      'notification',
      'location',
      'activity',
      'schedule',
      'complete',
    ]);

    await tester.pumpWidget(buildApp(enabled: false));
    await tester.pumpWidget(buildApp(enabled: true));
    await tester.pumpAndSettle();
    expect(order.where((step) => step == 'notification'), hasLength(1));
  });

  testWidgets('permission errors leave the main app usable', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FirstInstallPermissionGate(
          coordinator: _coordinator(
            order: <String>[],
            notificationResponse: () async => throw StateError('Unavailable'),
          ),
          child: const Text('Main app ready'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Main app ready'), findsOneWidget);
  });

  testWidgets('notification page exposes the Android sound shortcut', (
    tester,
  ) async {
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(notificationSettingsChannel, (call) async {
          calls.add(call.method);
          return true;
        });
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
    await tester.ensureVisible(
      find.byKey(const ValueKey('open-system-notification-settings')),
    );
    await tester.tap(
      find.byKey(const ValueKey('open-system-notification-settings')),
    );
    await tester.pumpAndSettle();
    expect(calls, ['openNotificationSettings']);
  });
}

FirstInstallPermissionCoordinator _coordinator({
  required List<String> order,
  Future<bool> Function()? isCompleted,
  Future<void> Function()? markCompleted,
  Future<void> Function()? notificationResponse,
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
      await notificationResponse?.call();
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
