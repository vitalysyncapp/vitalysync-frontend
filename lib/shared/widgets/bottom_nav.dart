import 'dart:ui';

import 'package:flutter/material.dart';

class _BottomNavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _BottomNavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

const _navItems = [
  _BottomNavItemData(
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
    label: 'Home',
  ),
  _BottomNavItemData(
    icon: Icons.monitor_heart_outlined,
    activeIcon: Icons.monitor_heart_rounded,
    label: 'Log',
  ),
  _BottomNavItemData(
    icon: Icons.camera_alt_outlined,
    activeIcon: Icons.camera_alt_rounded,
    label: 'Nutrition',
  ),
  _BottomNavItemData(
    icon: Icons.analytics_outlined,
    activeIcon: Icons.analytics_rounded,
    label: 'Dashboard',
  ),
];

Widget buildBottomNav({
  required BuildContext context,
  required int currentIndex,
  required ValueChanged<int> onTap,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final bottomInset = MediaQuery.paddingOf(context).bottom;
  final screenWidth = MediaQuery.sizeOf(context).width;
  final isCompact = screenWidth < 390;

  return SafeArea(
    top: false,
    child: Padding(
      padding: EdgeInsets.only(
        left: isCompact ? 8 : 12,
        right: isCompact ? 8 : 12,
        bottom: bottomInset > 0 ? 8 : 12,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 6 : 8,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        const Color(0xFF132134).withValues(alpha: 0.94),
                        const Color(0xFF0C1726).withValues(alpha: 0.92),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.95),
                        const Color(0xFFF0FBF7).withValues(alpha: 0.92),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.85),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.12),
                  blurRadius: 32,
                  offset: const Offset(0, 18),
                ),
                BoxShadow(
                  color: isDark
                      ? const Color(0xFF5DB8F0).withValues(alpha: 0.08)
                      : const Color.fromARGB(
                          255,
                          29,
                          140,
                          168,
                        ).withValues(alpha: 0.22),
                  blurRadius: 26,
                  spreadRadius: -8,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isVeryCompact = constraints.maxWidth < 350;

                return Row(
                  children: List.generate(_navItems.length, (index) {
                    final item = _navItems[index];
                    return Expanded(
                      child: _FloatingNavItem(
                        item: item,
                        isDark: isDark,
                        isSelected: currentIndex == index,
                        isCompact: isVeryCompact,
                        onTap: () => onTap(index),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}

class _FloatingNavItem extends StatelessWidget {
  final _BottomNavItemData item;
  final bool isDark;
  final bool isSelected;
  final bool isCompact;
  final VoidCallback onTap;

  const _FloatingNavItem({
    required this.item,
    required this.isDark,
    required this.isSelected,
    required this.isCompact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inactiveIconColor = isDark
        ? Colors.white.withValues(alpha: 0.68)
        : const Color(0xFF5F7288);
    final inactiveLabelColor = isDark
        ? Colors.white.withValues(alpha: 0.72)
        : const Color(0xFF587081);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 1 : 2),
      child: Semantics(
        button: true,
        selected: isSelected,
        label: item.label,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            constraints: const BoxConstraints(minHeight: 58),
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 4 : 6,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [
                        Color.fromARGB(255, 29, 140, 168),
                        Color(0xFF59B7EF),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              border: Border.all(
                color: isSelected
                    ? Colors.white.withValues(alpha: isDark ? 0.12 : 0.56)
                    : Colors.transparent,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(
                          0xFF3BB8C7,
                        ).withValues(alpha: isDark ? 0.26 : 0.22),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSlide(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  offset: isSelected ? const Offset(0, -0.04) : Offset.zero,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutBack,
                    scale: isSelected ? 1.08 : 1,
                    child: Icon(
                      isSelected ? item.activeIcon : item.icon,
                      size: isCompact ? 20 : 22,
                      color: isSelected ? Colors.white : inactiveIconColor,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  style: TextStyle(
                    color: isSelected ? Colors.white : inactiveLabelColor,
                    fontSize: isCompact ? 10 : 10.8,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    letterSpacing: 0,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(item.label, maxLines: 1, softWrap: false),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
