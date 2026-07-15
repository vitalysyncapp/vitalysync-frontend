import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';

import '../navigation/main_tab.dart';

class _BottomNavItemData {
  final MainTab tab;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _BottomNavItemData({
    required this.tab,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

const _sideNavItems = [
  _BottomNavItemData(
    tab: MainTab.home,
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
    label: 'Home',
  ),
  _BottomNavItemData(
    tab: MainTab.nutrition,
    icon: Icons.restaurant_menu_outlined,
    activeIcon: Icons.restaurant_menu_rounded,
    label: 'Nutrition',
  ),
  _BottomNavItemData(
    tab: MainTab.dashboard,
    icon: Icons.analytics_outlined,
    activeIcon: Icons.analytics_rounded,
    label: 'Dashboard',
  ),
  _BottomNavItemData(
    tab: MainTab.profile,
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
    label: 'Profile',
  ),
];

Widget buildBottomNav({
  required BuildContext context,
  required MainTab currentTab,
  required ValueChanged<MainTab> onTap,
  Key? tutorialKey,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  final screenWidth = MediaQuery.sizeOf(context).width;
  final bottomInset = MediaQuery.paddingOf(context).bottom;
  final isCompact = screenWidth < 390;
  final activeSideIndex = _sideNavItems.indexWhere(
    (item) => item.tab == currentTab,
  );
  final surfaceColor = isDark
      ? const Color(0xFF101E30).withValues(alpha: 0.98)
      : Colors.white.withValues(alpha: 0.98);

  return KeyedSubtree(
    key: tutorialKey,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedBottomNavigationBar.builder(
          key: const ValueKey('main-bottom-navigation'),
          itemCount: _sideNavItems.length,
          activeIndex: activeSideIndex,
          gapLocation: GapLocation.center,
          gapWidth: isCompact ? 62 : 68,
          notchMargin: 4,
          notchSmoothness: NotchSmoothness.smoothEdge,
          height: isCompact ? 68 : 72,
          leftCornerRadius: 0,
          rightCornerRadius: 0,
          elevation: 0,
          backgroundColor: surfaceColor,
          splashColor: const Color(0xFF1D8CA8).withValues(alpha: 0.2),
          splashRadius: 24,
          splashSpeedInMilliseconds: reduceMotion ? 1 : 260,
          scaleFactor: reduceMotion ? 0 : 0.12,
          borderColor: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFDCE7ED),
          borderWidth: 0.8,
          shadow: Shadow(
            color: Colors.black.withValues(alpha: isDark ? 0.34 : 0.14),
            blurRadius: 18,
            offset: const Offset(0, -3),
          ),
          blurEffect: true,
          safeAreaValues: const SafeAreaValues(bottom: true),
          onTap: (index) => onTap(_sideNavItems[index].tab),
          tabBuilder: (index, isActive) {
            final item = _sideNavItems[index];
            return _NavigationItem(
              key: ValueKey('main-nav-${item.tab.name}'),
              item: item,
              isActive: isActive,
              isDark: isDark,
              isCompact: isCompact,
              reduceMotion: reduceMotion,
            );
          },
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: bottomInset + (isCompact ? 20 : 21),
          child: ExcludeSemantics(
            child: IgnorePointer(
              child: AnimatedDefaultTextStyle(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 220),
                style: TextStyle(
                  color: currentTab == MainTab.log
                      ? const Color(0xFF1D8CA8)
                      : isDark
                      ? Colors.white.withValues(alpha: 0.7)
                      : const Color(0xFF718295),
                  fontSize: isCompact ? 9.5 : 10.4,
                  fontWeight: currentTab == MainTab.log
                      ? FontWeight.w800
                      : FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                child: const Text('Log'),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget buildLogNavigationButton({
  required BuildContext context,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  final isCompact = MediaQuery.sizeOf(context).width < 390;
  final size = isCompact ? 54.0 : 60.0;
  final accent = const Color(0xFF1D8CA8);

  return Semantics(
    key: const ValueKey('main-nav-log'),
    container: true,
    button: true,
    selected: isSelected,
    label: 'Log',
    child: AnimatedScale(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      scale: isSelected ? 1.06 : 1,
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF1D8CA8), Color(0xFF5DB8F0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected
                ? null
                : isDark
                ? const Color(0xFF15283D)
                : Colors.white,
            border: Border.all(
              color: isSelected ? Colors.white.withValues(alpha: 0.78) : accent,
              width: isSelected ? 2.5 : 3.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: isDark ? 0.32 : 0.26),
                blurRadius: isSelected ? 20 : 15,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Center(
                child: AnimatedSwitcher(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 220),
                  child: Icon(
                    isSelected
                        ? Icons.monitor_heart_rounded
                        : Icons.monitor_heart_outlined,
                    key: ValueKey(isSelected),
                    color: isSelected ? Colors.white : accent,
                    size: isCompact ? 24 : 26,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _NavigationItem extends StatelessWidget {
  final _BottomNavItemData item;
  final bool isActive;
  final bool isDark;
  final bool isCompact;
  final bool reduceMotion;

  const _NavigationItem({
    super.key,
    required this.item,
    required this.isActive,
    required this.isDark,
    required this.isCompact,
    required this.reduceMotion,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFF1D8CA8);
    final inactiveColor = isDark
        ? Colors.white.withValues(alpha: 0.68)
        : const Color(0xFF718295);
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 240);

    return Semantics(
      button: true,
      selected: isActive,
      label: item.label,
      child: ExcludeSemantics(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            isCompact ? 2 : 4,
            isCompact ? 7 : 8,
            isCompact ? 2 : 4,
            isCompact ? 16 : 17,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                duration: duration,
                curve: Curves.easeOutBack,
                scale: isActive ? 1.12 : 1,
                child: Icon(
                  isActive ? item.activeIcon : item.icon,
                  color: isActive ? activeColor : inactiveColor,
                  size: isCompact ? 22 : 24,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: duration,
                style: TextStyle(
                  color: isActive ? activeColor : inactiveColor,
                  fontSize: isCompact ? 9.5 : 10.4,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(item.label, maxLines: 1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
