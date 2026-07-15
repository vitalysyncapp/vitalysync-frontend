import 'dart:async';

import 'package:flutter/material.dart';

import '../features/activity/data/activity_service.dart';
import '../features/dashboard/data/burnout_score_api.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/exercise/data/exercise_goal_service.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/log/data/log_api.dart';
import '../features/log/presentation/pages/log_page.dart';
import '../features/nutrition/data/nutrition_reminder_engine.dart';
import '../features/nutrition/presentation/pages/nutrition_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/recovery/data/recovery_mode_service.dart';
import '../features/recovery/presentation/pages/recovery_mode_page.dart';
import '../features/settings/presentation/pages/assistant_settings.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/tutorial/presentation/widgets/core_tutorial_overlay.dart';
import '../features/tutorial/services/core_tutorial_replay_controller.dart';
import '../features/tutorial/services/core_tutorial_service.dart';
import '../shared/widgets/bottom_nav.dart';
import '../shared/assistant/floating_smart_nudge_assistant.dart';
import '../shared/navigation/main_tab.dart';
import '../shared/widgets/app_bar.dart';

class MainNavigationController extends InheritedWidget {
  final MainTab currentTab;
  final ValueChanged<MainTab> onTabSelected;
  final int nutritionLogFocusRequest;
  final VoidCallback onNutritionLogRequested;
  final VoidCallback onLogRequested;

  const MainNavigationController({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
    required this.nutritionLogFocusRequest,
    required this.onNutritionLogRequested,
    required this.onLogRequested,
    required super.child,
  });

  static MainNavigationController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<MainNavigationController>();
  }

  @override
  bool updateShouldNotify(MainNavigationController oldWidget) {
    return currentTab != oldWidget.currentTab ||
        nutritionLogFocusRequest != oldWidget.nutritionLogFocusRequest;
  }
}

class MainNavigation extends StatefulWidget {
  final MainTab initialTab;
  final bool openNutritionLogOnStart;
  final int? tutorialUserId;
  final bool showTutorialOnStart;

  const MainNavigation({
    super.key,
    this.initialTab = MainTab.home,
    this.openNutritionLogOnStart = false,
    this.tutorialUserId,
    this.showTutorialOnStart = false,
  });
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with WidgetsBindingObserver {
  static const _pageTransitionDuration = Duration(milliseconds: 360);
  static const _offlineSyncInterval = Duration(seconds: 30);
  static const _tutorialSettingsRouteName = 'core_tutorial/settings';
  static const _tutorialAssistantRouteName = 'core_tutorial/assistant_settings';

  late MainTab _currentTab;
  late int _nutritionLogFocusRequest;
  late final LogPageController _logPageController;
  late final List<Widget> _pages;
  late final Map<CoreTutorialTarget, GlobalKey> _tutorialTargetKeys;
  Timer? _offlineSyncTimer;
  OverlayEntry? _tutorialOverlayEntry;
  CoreTutorialRoute _tutorialRoute = CoreTutorialRoute.main;
  bool _isSyncingOfflineLogs = false;
  bool _isRecoveryRouteOpen = false;
  bool _recoveryDismissedThisNavigation = false;
  bool _isTutorialActive = false;
  bool _tutorialSettingsRouteOpen = false;
  bool _tutorialAssistantRouteOpen = false;
  int _recoveryCheckToken = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentTab = widget.initialTab;
    _nutritionLogFocusRequest = widget.openNutritionLogOnStart ? 1 : 0;
    _logPageController = LogPageController();
    _pages = [
      HomePage(onProfileTap: () => _selectTab(MainTab.profile)),
      const NutritionPage(),
      LogPage(controller: _logPageController),
      const Dashboard(),
      const ProfilePage(),
    ];
    _tutorialTargetKeys = {
      CoreTutorialTarget.navigation: GlobalKey(
        debugLabel: 'tutorial_navigation',
      ),
      CoreTutorialTarget.home: GlobalKey(debugLabel: 'tutorial_home'),
      CoreTutorialTarget.log: GlobalKey(debugLabel: 'tutorial_log'),
      CoreTutorialTarget.nutrition: GlobalKey(debugLabel: 'tutorial_nutrition'),
      CoreTutorialTarget.dashboard: GlobalKey(debugLabel: 'tutorial_dashboard'),
      CoreTutorialTarget.profile: GlobalKey(debugLabel: 'tutorial_profile'),
      CoreTutorialTarget.assistant: GlobalKey(debugLabel: 'tutorial_assistant'),
      CoreTutorialTarget.settingsAssistantTile: GlobalKey(
        debugLabel: 'tutorial_settings_assistant_tile',
      ),
      CoreTutorialTarget.assistantOverlaySwitch: GlobalKey(
        debugLabel: 'tutorial_assistant_overlay_switch',
      ),
    };
    _isTutorialActive =
        widget.showTutorialOnStart && widget.tutorialUserId != null;
    CoreTutorialReplayController.instance.requests.addListener(
      _handleCoreTutorialReplayRequested,
    );
    BurnoutScoreApi.refreshSignal.addListener(_handleBurnoutInputsChanged);
    ActivityService.instance.startTracking();
    ExerciseGoalService.instance.start();
    _syncPendingLogs();
    _evaluateNutritionReminder();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isTutorialActive) {
        _showTutorialOverlay();
      }
      _checkRecoveryMode();
    });
    _offlineSyncTimer = Timer.periodic(
      _offlineSyncInterval,
      (_) => _syncPendingLogs(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    CoreTutorialReplayController.instance.requests.removeListener(
      _handleCoreTutorialReplayRequested,
    );
    BurnoutScoreApi.refreshSignal.removeListener(_handleBurnoutInputsChanged);
    _offlineSyncTimer?.cancel();
    _removeTutorialOverlay();
    _logPageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncPendingLogs();
      _evaluateNutritionReminder();
      _checkRecoveryMode();
    } else if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _recoveryDismissedThisNavigation = false;
    }
  }

  void _handleBurnoutInputsChanged() {
    _recoveryDismissedThisNavigation = false;
    _checkRecoveryMode(forceShow: true);
  }

  void _handleCoreTutorialReplayRequested() {
    if (!mounted || _isTutorialActive) {
      return;
    }

    setState(() {
      _isTutorialActive = true;
    });
    _tutorialRoute = CoreTutorialRoute.main;
    _showTutorialOverlay();
  }

  void _selectTab(MainTab tab) {
    if (tab == _currentTab) return;

    setState(() {
      _currentTab = tab;
    });
    _tutorialOverlayEntry?.markNeedsBuild();

    _syncPendingLogs();
  }

  void _openNutritionLog() {
    setState(() {
      _currentTab = MainTab.nutrition;
      _nutritionLogFocusRequest++;
    });

    _syncPendingLogs();
  }

  void _openLogPage() {
    setState(() {
      _currentTab = MainTab.log;
    });

    _syncPendingLogs();
  }

  Future<void> _syncPendingLogs() async {
    if (_isSyncingOfflineLogs) {
      return;
    }

    _isSyncingOfflineLogs = true;
    try {
      final syncedCount = await LogApi.syncPendingLogs();
      await ActivityService.instance.syncPendingActivityLogs();
      if (syncedCount > 0) {
        await refreshAppBarStreak();
      }
    } catch (_) {
      // Keep the queue for the next retry.
    } finally {
      _isSyncingOfflineLogs = false;
    }
  }

  void _evaluateNutritionReminder() {
    unawaited(NutritionReminderEngine.instance.evaluate());
  }

  Future<void> _checkRecoveryMode({bool forceShow = false}) async {
    if (_isTutorialActive ||
        _isRecoveryRouteOpen ||
        (_recoveryDismissedThisNavigation && !forceShow) ||
        !mounted) {
      return;
    }

    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent != true) {
      return;
    }

    final checkToken = ++_recoveryCheckToken;
    final snapshot = await RecoveryModeService.instance.evaluate();

    if (!mounted ||
        checkToken != _recoveryCheckToken ||
        snapshot == null ||
        _isRecoveryRouteOpen ||
        (_recoveryDismissedThisNavigation && !forceShow)) {
      return;
    }

    _isRecoveryRouteOpen = true;
    unawaited(
      Navigator.of(context)
          .push<void>(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => RecoveryModePage(
                snapshot: snapshot,
                onLogRequested: _openLogPage,
              ),
            ),
          )
          .whenComplete(() {
            if (!mounted) {
              return;
            }

            _isRecoveryRouteOpen = false;
            _recoveryDismissedThisNavigation = true;
          }),
    );
  }

  Future<void> _completeCoreTutorial() async {
    final userId = widget.tutorialUserId;
    if (userId != null) {
      await CoreTutorialService.instance.completeForUser(userId);
    }

    if (!mounted) {
      return;
    }

    await _routeCoreTutorial(CoreTutorialRoute.main);

    if (!mounted) {
      return;
    }

    _removeTutorialOverlay();
    setState(() => _isTutorialActive = false);
    unawaited(_checkRecoveryMode());
  }

  void _showTutorialOverlay() {
    if (_tutorialOverlayEntry != null) {
      _tutorialOverlayEntry?.markNeedsBuild();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isTutorialActive || _tutorialOverlayEntry != null) {
        return;
      }

      final overlay = Overlay.of(context, rootOverlay: true);
      _tutorialOverlayEntry = OverlayEntry(
        builder: (_) => CoreTutorialOverlay(
          currentTab: _currentTab,
          onTabSelected: _selectTab,
          targetKeys: _tutorialTargetKeys,
          onRouteRequested: _routeCoreTutorial,
          onFinished: _completeCoreTutorial,
        ),
      );
      overlay.insert(_tutorialOverlayEntry!);
    });
  }

  void _removeTutorialOverlay() {
    _tutorialOverlayEntry?.remove();
    _tutorialOverlayEntry?.dispose();
    _tutorialOverlayEntry = null;
  }

  void _bringTutorialOverlayToFront({Duration delay = Duration.zero}) {
    Future<void>.delayed(delay, () {
      if (!mounted || !_isTutorialActive || _tutorialOverlayEntry == null) {
        return;
      }

      final overlay = Overlay.of(context, rootOverlay: true);
      final entry = _tutorialOverlayEntry!;
      if (entry.mounted) {
        entry.remove();
      }
      overlay.insert(entry);
      entry.markNeedsBuild();
    });
  }

  Future<void> _routeCoreTutorial(CoreTutorialRoute route) async {
    if (!mounted || !_isTutorialActive) {
      return;
    }

    if (_tutorialRoute == route) {
      _bringTutorialOverlayToFront();
      return;
    }

    _tutorialRoute = route;
    switch (route) {
      case CoreTutorialRoute.main:
        _closeTutorialRoutes();
        break;
      case CoreTutorialRoute.settings:
        if (_tutorialAssistantRouteOpen) {
          Navigator.of(context, rootNavigator: true).pop();
          _tutorialAssistantRouteOpen = false;
          await Future<void>.delayed(const Duration(milliseconds: 220));
        }
        _openTutorialSettingsRoute();
        break;
      case CoreTutorialRoute.assistantSettings:
        if (!_tutorialSettingsRouteOpen) {
          _openTutorialSettingsRoute();
          await Future<void>.delayed(const Duration(milliseconds: 360));
        }
        if (!mounted ||
            !_isTutorialActive ||
            _tutorialRoute != CoreTutorialRoute.assistantSettings) {
          return;
        }
        _openTutorialAssistantRoute();
        break;
    }

    _tutorialOverlayEntry?.markNeedsBuild();
  }

  void _openTutorialSettingsRoute() {
    if (_tutorialSettingsRouteOpen) {
      _bringTutorialOverlayToFront();
      return;
    }

    _tutorialSettingsRouteOpen = true;
    final navigator = Navigator.of(context, rootNavigator: true);
    unawaited(
      navigator
          .push<void>(
            MaterialPageRoute(
              settings: const RouteSettings(name: _tutorialSettingsRouteName),
              builder: (_) => SettingsPage(
                tutorialAssistantTileKey:
                    _tutorialTargetKeys[CoreTutorialTarget
                        .settingsAssistantTile],
              ),
            ),
          )
          .whenComplete(() {
            _tutorialSettingsRouteOpen = false;
            if (mounted &&
                _isTutorialActive &&
                _tutorialRoute != CoreTutorialRoute.main) {
              _tutorialRoute = CoreTutorialRoute.main;
              _tutorialOverlayEntry?.markNeedsBuild();
            }
          }),
    );

    _bringTutorialOverlayToFront(delay: const Duration(milliseconds: 90));
    _bringTutorialOverlayToFront(delay: const Duration(milliseconds: 430));
  }

  void _openTutorialAssistantRoute() {
    if (_tutorialAssistantRouteOpen) {
      _bringTutorialOverlayToFront();
      return;
    }

    _tutorialAssistantRouteOpen = true;
    final navigator = Navigator.of(context, rootNavigator: true);
    unawaited(
      navigator
          .push<void>(
            MaterialPageRoute(
              settings: const RouteSettings(name: _tutorialAssistantRouteName),
              builder: (_) => AssistantSettings(
                tutorialOverlaySwitchKey:
                    _tutorialTargetKeys[CoreTutorialTarget
                        .assistantOverlaySwitch],
              ),
            ),
          )
          .whenComplete(() {
            _tutorialAssistantRouteOpen = false;
            if (mounted &&
                _isTutorialActive &&
                _tutorialRoute == CoreTutorialRoute.assistantSettings) {
              _tutorialRoute = CoreTutorialRoute.settings;
              _tutorialOverlayEntry?.markNeedsBuild();
            }
          }),
    );

    _bringTutorialOverlayToFront(delay: const Duration(milliseconds: 90));
    _bringTutorialOverlayToFront(delay: const Duration(milliseconds: 430));
  }

  void _closeTutorialRoutes() {
    final navigator = Navigator.of(context, rootNavigator: true);
    navigator.popUntil((route) {
      final name = route.settings.name;
      return name != _tutorialSettingsRouteName &&
          name != _tutorialAssistantRouteName;
    });
    _tutorialSettingsRouteOpen = false;
    _tutorialAssistantRouteOpen = false;
    _bringTutorialOverlayToFront(delay: const Duration(milliseconds: 90));
  }

  CoreTutorialTarget _tutorialTargetForPage(MainTab tab) {
    return switch (tab) {
      MainTab.home => CoreTutorialTarget.home,
      MainTab.nutrition => CoreTutorialTarget.nutrition,
      MainTab.log => CoreTutorialTarget.log,
      MainTab.dashboard => CoreTutorialTarget.dashboard,
      MainTab.profile => CoreTutorialTarget.profile,
    };
  }

  @override
  Widget build(BuildContext context) {
    return MainNavigationController(
      currentTab: _currentTab,
      onTabSelected: _selectTab,
      nutritionLogFocusRequest: _nutritionLogFocusRequest,
      onNutritionLogRequested: _openNutritionLog,
      onLogRequested: _openLogPage,
      child: ValueListenableBuilder<LogNavigationState>(
        valueListenable: _logPageController,
        builder: (context, logNavigationState, _) {
          final isLogSelected = _currentTab == MainTab.log;
          final logLabel = !isLogSelected
              ? 'Log'
              : logNavigationState.isSaving
              ? 'Saving'
              : logNavigationState.canSave
              ? logNavigationState.hasLoggedToday
                    ? 'Update'
                    : 'Save'
              : logNavigationState.hasLoggedToday
              ? 'Done'
              : 'Log';

          return Stack(
            fit: StackFit.expand,
            children: [
              Scaffold(
                extendBody: false,
                body: Stack(
                  fit: StackFit.expand,
                  children: [
                    ...List.generate(_pages.length, (index) {
                      final tab = MainTab.values[index];
                      final isActive = tab == _currentTab;
                      final hiddenOffset = index < _currentTab.index
                          ? const Offset(-0.05, 0.02)
                          : const Offset(0.05, 0.02);

                      return IgnorePointer(
                        ignoring: !isActive,
                        child: AnimatedSlide(
                          duration: _pageTransitionDuration,
                          curve: Curves.easeOutCubic,
                          offset: isActive ? Offset.zero : hiddenOffset,
                          child: AnimatedScale(
                            duration: _pageTransitionDuration,
                            curve: Curves.easeOutCubic,
                            scale: isActive ? 1 : 0.985,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeOut,
                              opacity: isActive ? 1 : 0,
                              child: ExcludeSemantics(
                                excluding: !isActive,
                                child: TickerMode(
                                  enabled: isActive,
                                  child: KeyedSubtree(
                                    key:
                                        _tutorialTargetKeys[_tutorialTargetForPage(
                                          tab,
                                        )]!,
                                    child: _pages[index],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    KeyedSubtree(
                      key: _tutorialTargetKeys[CoreTutorialTarget.assistant],
                      child: FloatingSmartNudgeAssistant(
                        message:
                            "You're doing well today. Log sleep and hydration to keep your streak going.",
                        buttonSize: _currentTab == MainTab.log ? 46 : 54,
                        onLogMealRequested: _openNutritionLog,
                        onLogPageRequested: _openLogPage,
                      ),
                    ),
                  ],
                ),
                floatingActionButton: buildLogNavigationButton(
                  context: context,
                  isSelected: isLogSelected,
                  hasLoggedToday: logNavigationState.hasLoggedToday,
                  canSave: logNavigationState.canSave,
                  isSaving: logNavigationState.isSaving,
                  onTap: () => _selectTab(MainTab.log),
                  onSave: () {
                    unawaited(_logPageController.save());
                  },
                ),
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.centerDocked,
                bottomNavigationBar: buildBottomNav(
                  context: context,
                  currentTab: _currentTab,
                  onTap: _selectTab,
                  logLabel: logLabel,
                  hasLoggedToday: logNavigationState.hasLoggedToday,
                  tutorialKey:
                      _tutorialTargetKeys[CoreTutorialTarget.navigation],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
