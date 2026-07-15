import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/features/settings/presentation/pages/settings_page.dart';
import 'package:vitalysync/features/tutorial/services/core_tutorial_replay_controller.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(configureTestAssets);
  tearDownAll(clearTestAssets);

  testWidgets('settings can request a tutorial replay', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final initialRequests =
        CoreTutorialReplayController.instance.requests.value;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsPage()),
                    );
                  },
                  child: const Text('Open settings'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.ensureVisible(find.text('Replay app tutorial'));
    await tester.pump();
    await tester.tap(find.text('Replay app tutorial'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Open settings'), findsOneWidget);
    expect(
      CoreTutorialReplayController.instance.requests.value,
      initialRequests + 1,
    );
  });
}
