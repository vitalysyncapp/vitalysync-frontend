import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/shared/preferences/app_preferences.dart';
import 'package:vitalysync/shared/widgets/sensitive_content_guard.dart';
import 'package:vitalysync/shared/privacy/biometric_lock_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SensitiveContentGuard', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders child when hideSensitiveContent is false', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'hide_sensitive_content': false});
      await AppPreferencesController.instance.load();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SensitiveContentGuard(
              child: SizedBox(
                width: 200,
                height: 150,
                child: Text('Score: 72'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Score: 72'), findsOneWidget);
      expect(find.text('Content hidden'), findsNothing);
    });

    testWidgets('hides child when hideSensitiveContent is true', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'hide_sensitive_content': true});
      await AppPreferencesController.instance.load();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SensitiveContentGuard(
              child: SizedBox(
                width: 200,
                height: 150,
                child: Text('Score: 72'),
              ),
            ),
          ),
        ),
      );

      // The child should be hidden behind the overlay.
      expect(find.text('Content hidden'), findsOneWidget);
      expect(find.text('Tap to view'), findsOneWidget);
    });

    testWidgets('hides "Hold to peek" when allowPeek is false', (tester) async {
      SharedPreferences.setMockInitialValues({'hide_sensitive_content': true});
      await AppPreferencesController.instance.load();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SensitiveContentGuard(
              allowPeek: false,
              child: SizedBox(
                width: 200,
                height: 150,
                child: Text('Secret data'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Content hidden'), findsOneWidget);
      expect(find.text('Tap to view'), findsNothing);
    });

    testWidgets('responds to preference changes dynamically', (tester) async {
      SharedPreferences.setMockInitialValues({'hide_sensitive_content': false});
      await AppPreferencesController.instance.load();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SensitiveContentGuard(
              child: SizedBox(
                width: 200,
                height: 150,
                child: Text('Visible data'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Visible data'), findsOneWidget);
      expect(find.text('Content hidden'), findsNothing);

      // Toggle the preference on.
      await AppPreferencesController.instance.updateHideSensitiveContent(true);
      await tester.pump();

      expect(find.text('Content hidden'), findsOneWidget);
    });
  });

  group('BiometricLockService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      BiometricLockService.instance.resetForTesting();
    });

    test(
      'does not lock on cold start when biometric preference is disabled',
      () async {
        SharedPreferences.setMockInitialValues({
          'biometric_lock_enabled': false,
        });
        await AppPreferencesController.instance.load();

        final service = BiometricLockService.instance;
        service.lockOnColdStart();

        expect(service.isLocked.value, isFalse);
      },
    );

    test('locks on cold start when biometric preference is enabled', () async {
      SharedPreferences.setMockInitialValues({'biometric_lock_enabled': true});
      await AppPreferencesController.instance.load();

      final service = BiometricLockService.instance;
      final didLock = service.lockOnColdStart();

      expect(didLock, isTrue);
      expect(service.isLocked.value, isTrue);
    });
  });

  group('AppPreferencesState new privacy fields', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults have expected values', () {
      const defaults = AppPreferencesState.defaults();
      expect(defaults.pauseWellnessInsights, isFalse);
      expect(defaults.hideProfileFromLeaderboard, isFalse);
      expect(defaults.dataRetentionDays, 0);
    });

    test('copyWith preserves new privacy fields', () {
      const defaults = AppPreferencesState.defaults();

      final modified = defaults.copyWith(
        pauseWellnessInsights: true,
        hideProfileFromLeaderboard: true,
        dataRetentionDays: 30,
      );

      expect(modified.pauseWellnessInsights, isTrue);
      expect(modified.hideProfileFromLeaderboard, isTrue);
      expect(modified.dataRetentionDays, 30);
    });

    test('load reads new privacy fields from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'pause_wellness_insights': true,
        'hide_profile_from_leaderboard': true,
        'data_retention_days': 60,
      });

      await AppPreferencesController.instance.load();

      final state = AppPreferencesController.instance.notifier.value;
      expect(state.pauseWellnessInsights, isTrue);
      expect(state.hideProfileFromLeaderboard, isTrue);
      expect(state.dataRetentionDays, 60);
    });

    test('update methods persist and notify for new fields', () async {
      SharedPreferences.setMockInitialValues({});
      await AppPreferencesController.instance.load();

      await AppPreferencesController.instance.updateHideProfileFromLeaderboard(
        true,
      );
      expect(
        AppPreferencesController
            .instance
            .notifier
            .value
            .hideProfileFromLeaderboard,
        isTrue,
      );

      await AppPreferencesController.instance.updateDataRetentionDays(90);
      expect(
        AppPreferencesController.instance.notifier.value.dataRetentionDays,
        90,
      );
    });
  });
}
