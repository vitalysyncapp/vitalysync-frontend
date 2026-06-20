import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/features/tutorial/services/core_tutorial_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'pending tutorial is account-scoped and completion clears pending',
    () async {
      final service = CoreTutorialService.instance;

      expect(await service.shouldShowForUser(1), isFalse);

      await service.markPendingForUser(1);

      expect(await service.shouldShowForUser(1), isTrue);
      expect(await service.shouldShowForUser(2), isFalse);

      await service.completeForUser(1);

      final prefs = await SharedPreferences.getInstance();
      expect(await service.shouldShowForUser(1), isFalse);
      expect(
        prefs.getBool('${CoreTutorialService.storageKeyPrefix}completed_1'),
        isTrue,
      );
      expect(
        prefs.containsKey('${CoreTutorialService.storageKeyPrefix}pending_1'),
        isFalse,
      );
    },
  );

  test('marking pending does not reopen a completed tutorial', () async {
    final service = CoreTutorialService.instance;

    await service.completeForUser(7);
    await service.markPendingForUser(7);

    expect(await service.shouldShowForUser(7), isFalse);
  });
}
