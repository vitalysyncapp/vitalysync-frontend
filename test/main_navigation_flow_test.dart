import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalysync/app/main_navigation.dart';
import 'package:vitalysync/features/activity/data/activity_service.dart';
import 'package:vitalysync/features/auth/presentation/pages/auth_start_page.dart';
import 'package:vitalysync/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:vitalysync/features/home/presentation/pages/home_page.dart';
import 'package:vitalysync/features/log/presentation/pages/log_page.dart';
import 'package:vitalysync/features/nutrition/presentation/pages/nutrition_page.dart';
import 'package:vitalysync/features/profile/presentation/pages/profile_page.dart';
import 'package:vitalysync/features/settings/presentation/pages/settings_page.dart';
import 'package:vitalysync/shared/navigation/main_tab.dart';
import 'package:vitalysync/shared/widgets/app_bar.dart';
import 'package:vitalysync/shared/widgets/bottom_nav.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(configureTestAssets);
  tearDownAll(clearTestAssets);

  Future<void> pumpMainNavigation(
    WidgetTester tester, {
    MainTab initialTab = MainTab.home,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en', 'US'),
        home: MainNavigation(initialTab: initialTab),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump();
  }

  Future<void> disposeNavigation(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await ActivityService.instance.disposeTracking();
  }

  MainNavigationController controller(WidgetTester tester) {
    return tester.widget<MainNavigationController>(
      find.byType(MainNavigationController),
    );
  }

  testWidgets('five destinations stay mounted and switch through typed tabs', (
    tester,
  ) async {
    configureLoggedInSession();
    await pumpMainNavigation(tester);

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(NutritionPage), findsOneWidget);
    expect(find.byType(LogPage), findsOneWidget);
    expect(find.byType(Dashboard), findsOneWidget);
    expect(find.byType(ProfilePage), findsOneWidget);
    expect(controller(tester).currentTab, MainTab.home);

    await tester.tap(find.byKey(const ValueKey('home-header-avatar')));
    await tester.pump(const Duration(milliseconds: 420));
    expect(controller(tester).currentTab, MainTab.profile);

    await tester.tap(find.byKey(const ValueKey('main-nav-home')));
    await tester.pump(const Duration(milliseconds: 420));
    expect(controller(tester).currentTab, MainTab.home);

    final homeX = tester
        .getCenter(find.byKey(const ValueKey('main-nav-home')))
        .dx;
    final nutritionX = tester
        .getCenter(find.byKey(const ValueKey('main-nav-nutrition')))
        .dx;
    final logX = tester
        .getCenter(find.byKey(const ValueKey('main-nav-log')))
        .dx;
    final dashboardX = tester
        .getCenter(find.byKey(const ValueKey('main-nav-dashboard')))
        .dx;
    final profileX = tester
        .getCenter(find.byKey(const ValueKey('main-nav-profile')))
        .dx;

    expect(homeX, lessThan(nutritionX));
    expect(nutritionX, lessThan(logX));
    expect(logX, lessThan(dashboardX));
    expect(dashboardX, lessThan(profileX));

    await tester.tap(find.byKey(const ValueKey('main-nav-nutrition')));
    await tester.pump(const Duration(milliseconds: 420));
    expect(controller(tester).currentTab, MainTab.nutrition);

    await tester.tap(find.byKey(const ValueKey('main-nav-log')));
    await tester.pump(const Duration(milliseconds: 420));
    expect(controller(tester).currentTab, MainTab.log);

    await tester.tap(find.byKey(const ValueKey('main-nav-dashboard')));
    await tester.pump(const Duration(milliseconds: 420));
    expect(controller(tester).currentTab, MainTab.dashboard);

    await tester.tap(find.byKey(const ValueKey('main-nav-profile')));
    await tester.pump(const Duration(milliseconds: 420));
    expect(controller(tester).currentTab, MainTab.profile);

    expect(find.byType(PopupMenuButton<int>), findsNothing);
    expect(find.byType(AppBar), findsNothing);
    expect(find.byKey(const ValueKey('home-header-avatar')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await disposeNavigation(tester);
  });

  testWidgets('notched bar fits compact dark reduced-motion layout', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: const MediaQuery(
          data: MediaQueryData(size: Size(320, 640), disableAnimations: true),
          child: _BottomNavHarness(),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('main-bottom-navigation')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('main-nav-home')), findsOneWidget);
    expect(find.byKey(const ValueKey('main-nav-nutrition')), findsOneWidget);
    expect(find.byKey(const ValueKey('main-nav-log')), findsOneWidget);
    expect(find.byKey(const ValueKey('main-nav-dashboard')), findsOneWidget);
    expect(find.byKey(const ValueKey('main-nav-profile')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('main-nav-log')));
    await tester.pump();

    final state = tester.state<_BottomNavHarnessState>(
      find.byType(_BottomNavHarness),
    );
    expect(state.currentTab, MainTab.log);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selected log notch reuses save action and shows completion', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: _LogNotchHarness()));
    await tester.pump();

    expect(find.byIcon(Icons.save_rounded), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('main-nav-log')));
    await tester.pump();

    final state = tester.state<_LogNotchHarnessState>(
      find.byType(_LogNotchHarness),
    );
    expect(state.saveCount, 1);
    expect(state.navigationCount, 0);

    state.markLoggedToday();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('log-nav-complete-badge')),
      findsOneWidget,
    );
    expect(find.text('Done'), findsOneWidget);

    final circle = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byKey(const ValueKey('main-nav-log')),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final gradient = (circle.decoration as BoxDecoration).gradient;
    expect(gradient, isA<LinearGradient>());
    expect((gradient! as LinearGradient).colors, const [
      Color(0xFF119B68),
      Color(0xFF62D98D),
    ]);
    expect(tester.takeException(), isNull);
  });

  test(
    'log page controller only invokes save while the form is ready',
    () async {
      final logController = LogPageController();
      var saveCount = 0;
      Future<void> save() async => saveCount++;
      logController.bindSaveAction(save);

      await logController.save();
      expect(saveCount, 0);

      logController.updateState(
        isLoading: false,
        hasLoggedToday: false,
        isSaving: false,
        isFormVisible: true,
      );
      await logController.save();
      expect(saveCount, 1);

      logController.updateState(
        isLoading: false,
        hasLoggedToday: true,
        isSaving: false,
        isFormVisible: false,
      );
      await logController.save();
      expect(saveCount, 1);

      logController.dispose();
    },
  );

  testWidgets('profile owns the settings navigation action', (tester) async {
    configureLoggedInSession();
    await pumpMainNavigation(tester, initialTab: MainTab.profile);

    for (var i = 0; i < 5; i++) {
      if (find
          .byKey(const ValueKey('profile-account-card'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 500));
    }

    expect(find.byKey(const ValueKey('profile-account-card')), findsOneWidget);
    expect(find.byType(PopupMenuButton<int>), findsNothing);

    final settingsAction = find.byKey(
      const ValueKey('profile-settings-action'),
    );
    await tester.ensureVisible(settingsAction);
    await tester.pump();
    final settingsLabel = find.descendant(
      of: settingsAction,
      matching: find.text('Settings'),
    );
    expect(settingsLabel.hitTestable(), findsOneWidget);
    await tester.tap(settingsLabel.hitTestable());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.byType(SettingsPage), findsOneWidget);

    await disposeNavigation(tester);
  });

  testWidgets('profile can cancel and confirm logout', (tester) async {
    configureLoggedInSession();
    await pumpMainNavigation(tester, initialTab: MainTab.profile);

    for (var i = 0; i < 5; i++) {
      if (find
          .byKey(const ValueKey('profile-account-card'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 500));
    }

    final logoutAction = find.byKey(const ValueKey('profile-logout-action'));
    await Scrollable.ensureVisible(
      tester.element(logoutAction),
      alignment: 0.35,
    );
    await tester.pump();
    final logoutLabel = find.descendant(
      of: logoutAction,
      matching: find.text('Log out'),
    );
    await tester.tap(logoutLabel);
    await tester.pump();
    expect(find.byType(LogoutConfirmationDialog), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('logout-stay-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(LogoutConfirmationDialog), findsNothing);

    await tester.tap(logoutLabel);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('logout-confirm-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }

    expect(find.byType(AuthStartPage), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('auth_access_token'), isNull);

    await disposeNavigation(tester);
  });
}

class _BottomNavHarness extends StatefulWidget {
  const _BottomNavHarness();

  @override
  State<_BottomNavHarness> createState() => _BottomNavHarnessState();
}

class _BottomNavHarnessState extends State<_BottomNavHarness> {
  MainTab currentTab = MainTab.home;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(currentTab.name)),
      floatingActionButton: buildLogNavigationButton(
        context: context,
        isSelected: currentTab == MainTab.log,
        onTap: () => setState(() => currentTab = MainTab.log),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: buildBottomNav(
        context: context,
        currentTab: currentTab,
        onTap: (tab) => setState(() => currentTab = tab),
      ),
    );
  }
}

class _LogNotchHarness extends StatefulWidget {
  const _LogNotchHarness();

  @override
  State<_LogNotchHarness> createState() => _LogNotchHarnessState();
}

class _LogNotchHarnessState extends State<_LogNotchHarness> {
  int saveCount = 0;
  int navigationCount = 0;
  bool hasLoggedToday = false;
  bool canSave = true;

  void markLoggedToday() {
    setState(() {
      hasLoggedToday = true;
      canSave = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: buildLogNavigationButton(
        context: context,
        isSelected: true,
        hasLoggedToday: hasLoggedToday,
        canSave: canSave,
        onTap: () => navigationCount++,
        onSave: () => setState(() => saveCount++),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: buildBottomNav(
        context: context,
        currentTab: MainTab.log,
        onTap: (_) {},
        logLabel: hasLoggedToday ? 'Done' : 'Save',
        hasLoggedToday: hasLoggedToday,
      ),
    );
  }
}
