import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitalysync/features/tutorial/presentation/widgets/core_tutorial_overlay.dart';
import 'package:vitalysync/shared/navigation/main_tab.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(configureTestAssets);
  tearDownAll(clearTestAssets);

  testWidgets('keeps the assistant panel beside the active spotlight', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final navigationTargetKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  height: 68,
                  child: SizedBox(key: navigationTargetKey),
                ),
                Positioned.fill(
                  child: CoreTutorialOverlay(
                    currentTab: MainTab.home,
                    onTabSelected: (_) {},
                    targetKeys: {
                      CoreTutorialTarget.navigation: navigationTargetKey,
                    },
                    onRouteRequested: (_) async {},
                    onFinished: () async {},
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }

    final targetRect = tester.getRect(find.byKey(navigationTargetKey));
    final panelRect = tester.getRect(
      find.byKey(const ValueKey('core-tutorial-panel')),
    );
    final assistantRect = tester.getRect(
      find.byKey(const ValueKey('core-tutorial-assistant-avatar')),
    );

    expect(panelRect.bottom, lessThan(targetRect.top));
    expect(targetRect.top - panelRect.bottom, inInclusiveRange(16, 24));
    expect(targetRect.top - assistantRect.bottom, inInclusiveRange(12, 28));
    expect(tester.takeException(), isNull);
  });
}
