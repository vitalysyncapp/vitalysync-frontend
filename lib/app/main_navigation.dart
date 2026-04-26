import 'dart:async';

import 'package:flutter/material.dart';

import '../features/activity/data/activity_service.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/exercise/data/exercise_goal_service.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/log/data/log_api.dart';
import '../features/log/presentation/pages/log_page.dart';
import '../features/nutrition/presentation/pages/nutrition_page.dart';
import '../shared/widgets/bottom_nav.dart';
import '../shared/widgets/floating_smart_nudge_assistant.dart';
import '../shared/widgets/app_bar.dart';

class MainNavigationController extends InheritedWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final int nutritionLogFocusRequest;
  final VoidCallback onNutritionLogRequested;

  const MainNavigationController({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.nutritionLogFocusRequest,
    required this.onNutritionLogRequested,
    required super.child,
  });

  static MainNavigationController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<MainNavigationController>();
  }

  @override
  bool updateShouldNotify(MainNavigationController oldWidget) {
    return currentIndex != oldWidget.currentIndex ||
        nutritionLogFocusRequest != oldWidget.nutritionLogFocusRequest;
  }
}

class MainNavigation extends StatefulWidget {
  final int initialIndex;
  final bool openNutritionLogOnStart;

  const MainNavigation({
    super.key,
    this.initialIndex = 0, // default
    this.openNutritionLogOnStart = false,
  });
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with WidgetsBindingObserver {
  static const _pageTransitionDuration = Duration(milliseconds: 360);
  static const _offlineSyncInterval = Duration(seconds: 30);

  late int _currentIndex;
  late int _nutritionLogFocusRequest;
  late final List<Widget> _pages;
  Timer? _offlineSyncTimer;
  bool _isSyncingOfflineLogs = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentIndex = widget.initialIndex;
    _nutritionLogFocusRequest = widget.openNutritionLogOnStart ? 1 : 0;
    _pages = const [HomePage(), LogPage(), NutritionPage(), Dashboard()];
    ActivityService.instance.startTracking();
    ExerciseGoalService.instance.start();
    _syncPendingLogs();
    _offlineSyncTimer = Timer.periodic(
      _offlineSyncInterval,
      (_) => _syncPendingLogs(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _offlineSyncTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncPendingLogs();
    }
  }

  void _selectTab(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });

    _syncPendingLogs();
  }

  void _openNutritionLog() {
    setState(() {
      _currentIndex = 2;
      _nutritionLogFocusRequest++;
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

  @override
  Widget build(BuildContext context) {
    return MainNavigationController(
      currentIndex: _currentIndex,
      onTabSelected: _selectTab,
      nutritionLogFocusRequest: _nutritionLogFocusRequest,
      onNutritionLogRequested: _openNutritionLog,
      child: Scaffold(
        extendBody: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            ...List.generate(_pages.length, (index) {
              final isActive = index == _currentIndex;
              final hiddenOffset = index < _currentIndex
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
                            key: ValueKey('main_nav_page_$index'),
                            child: _pages[index],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
            const FloatingSmartNudgeAssistant(
              message:
                  "You're doing well today. Log sleep and hydration to keep your streak going.",
            ),
          ],
        ),
        bottomNavigationBar: buildBottomNav(
          context: context,
          currentIndex: _currentIndex,
          onTap: _selectTab,
        ),
      ),
    );
  }
}
