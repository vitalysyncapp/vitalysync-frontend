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

  testWidgets('step 9 stays high enough to show the full assistant bubble', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var currentTab = MainTab.home;
    final targetKeys = {
      for (final target in CoreTutorialTarget.values)
        if (target != CoreTutorialTarget.none) target: GlobalKey(),
    };
    final supportingTargetKeys = targetKeys.entries
        .where((entry) => entry.key != CoreTutorialTarget.assistant)
        .map((entry) => entry.value)
        .toList();

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => MediaQuery(
            data: const MediaQueryData(size: Size(390, 844)),
            child: Scaffold(
              body: Stack(
                children: [
                  for (
                    var index = 0;
                    index < supportingTargetKeys.length;
                    index++
                  )
                    Positioned(
                      left: 24 + (index % 4) * 70,
                      bottom: 28 + (index ~/ 4) * 82,
                      width: 48,
                      height: 48,
                      child: SizedBox(key: supportingTargetKeys[index]),
                    ),
                  Positioned(
                    right: 16,
                    top: 150,
                    width: 54,
                    height: 54,
                    child: SizedBox(
                      key: targetKeys[CoreTutorialTarget.assistant],
                    ),
                  ),
                  Positioned.fill(
                    child: CoreTutorialOverlay(
                      currentTab: currentTab,
                      onTabSelected: (tab) {
                        setState(() => currentTab = tab);
                      },
                      targetKeys: targetKeys,
                      onRouteRequested: (_) async {},
                      onFinished: () async {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }

    for (var step = 1; step < 9; step++) {
      await tester.tap(find.byKey(const ValueKey('core-tutorial-next-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    expect(find.text('The assistant adapts to your day'), findsOneWidget);
    final targetRect = tester.getRect(
      find.byKey(targetKeys[CoreTutorialTarget.assistant]!),
    );
    final focusRect = tester.getRect(
      find.byKey(const ValueKey('core-tutorial-focus-frame')),
    );
    final panelRect = tester.getRect(
      find.byKey(const ValueKey('core-tutorial-panel')),
    );
    final bubbleRect = tester.getRect(
      find.byKey(const ValueKey('core-tutorial-bubble')),
    );
    final assistantRect = tester.getRect(
      find.byKey(const ValueKey('core-tutorial-assistant-avatar')),
    );

    expect(focusRect, targetRect.inflate(8));
    expect(panelRect.top, greaterThan(targetRect.bottom));
    expect(panelRect.top, lessThan(280));
    expect(assistantRect.top, lessThan(280));
    expect(bubbleRect.height, greaterThan(160));
    expect(bubbleRect.bottom, lessThanOrEqualTo(826));
    expect(tester.takeException(), isNull);
  });
}
