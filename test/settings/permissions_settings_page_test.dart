import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/features/settings/presentation/pages/permissions_settings_page.dart';
import 'package:vitalysync/features/settings/presentation/pages/settings_page.dart';
import 'package:vitalysync/shared/preferences/app_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'location_permission_choice': 'allowed',
      'activity_permission_choice': 'denied',
    });
    await AppPreferencesController.instance.load();
  });

  test('permission preferences load and persist independently', () async {
    final controller = AppPreferencesController.instance;

    expect(
      controller.notifier.value.locationPermissionChoice,
      AppPermissionChoice.allowed,
    );
    expect(
      controller.notifier.value.activityPermissionChoice,
      AppPermissionChoice.denied,
    );

    await controller.updateActivityPermissionChoice(
      AppPermissionChoice.allowed,
    );

    final storedPreferences = await SharedPreferences.getInstance();
    expect(
      storedPreferences.getString('activity_permission_choice'),
      'allowed',
    );
    expect(controller.notifier.value.isActivityAccessEnabled, isTrue);
    expect(controller.notifier.value.activityPermissionLabel, 'Allowed');
  });

  testWidgets('permissions page shows location and activity controls', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PermissionsSettingsPage()));

    expect(find.text('Permissions settings'), findsOneWidget);
    expect(find.text('Location access'), findsOneWidget);
    expect(find.text('Activity access'), findsOneWidget);

    final locationSwitch = tester.widget<Switch>(
      find.byKey(const ValueKey('location-permission-switch')),
    );
    final activitySwitch = tester.widget<Switch>(
      find.byKey(const ValueKey('activity-permission-switch')),
    );
    expect(locationSwitch.value, isTrue);
    expect(activitySwitch.value, isFalse);
    expect(find.text('Notifications'), findsNothing);
  });

  testWidgets('activity access can be disabled independently', (tester) async {
    await AppPreferencesController.instance.updateActivityPermissionChoice(
      AppPermissionChoice.allowed,
    );
    await tester.pumpWidget(const MaterialApp(home: PermissionsSettingsPage()));

    await tester.tap(find.byKey(const ValueKey('activity-permission-switch')));
    await tester.pumpAndSettle();

    final state = AppPreferencesController.instance.notifier.value;
    expect(state.activityPermissionChoice, AppPermissionChoice.denied);
    expect(state.locationPermissionChoice, AppPermissionChoice.allowed);
    expect(
      tester
          .widget<Switch>(
            find.byKey(const ValueKey('activity-permission-switch')),
          )
          .value,
      isFalse,
    );
  });

  testWidgets(
    'settings keeps notifications separate from privacy permissions',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await AppPreferencesController.instance.load();

      await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
      await tester.pumpAndSettle();

      expect(find.text('App settings'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Privacy and security'), findsOneWidget);
      expect(find.text('Permissions settings'), findsOneWidget);
      expect(find.text('Location settings'), findsNothing);
    },
  );
}
