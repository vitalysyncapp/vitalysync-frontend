import 'dart:ui';
import 'package:flutter/material.dart';

Widget buildBottomNav({
  required BuildContext context,
  required int currentIndex,
  required ValueChanged<int> onTap,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return SafeArea(
    top: false,
    child: Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom > 0 ? 8 : 14,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.white.withOpacity(0.75),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.10)
                    : Colors.white.withOpacity(0.45),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.28 : 0.10),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: onTap,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor:
                  isDark ? Colors.lightBlueAccent : Colors.blue,
              unselectedItemColor:
                  isDark ? Colors.grey[400] : Colors.grey[600],
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 11,
              ),
              showUnselectedLabels: true,
              items: const [
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.home_outlined),
                  ),
                  activeIcon: Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.home_rounded),
                  ),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.monitor_heart_outlined),
                  ),
                  activeIcon: Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.monitor_heart_rounded),
                  ),
                  label: 'Log',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.camera_alt_outlined),
                  ),
                  activeIcon: Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.camera_alt_rounded),
                  ),
                  label: 'Nutrition',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.analytics_outlined),
                  ),
                  activeIcon: Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.analytics_rounded),
                  ),
                  label: 'Dashboard',
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}