import 'package:flutter/material.dart';

import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/log/presentation/pages/log_page.dart';
import '../features/nutrition/presentation/pages/nutrition_page.dart';
import '../shared/widgets/bottom_nav.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;

  const MainNavigation({
    Key? key,
    this.initialIndex = 0, // default
  }) : super(key: key);
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;

  @override
    void initState() {
      super.initState();
      _currentIndex = widget.initialIndex; 
    }

  final List<Widget> _pages = const [
    HomePage(),
    LogPage(),
    NutritionPage(),
    Dashboard(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, 
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: buildBottomNav(
        context: context,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
