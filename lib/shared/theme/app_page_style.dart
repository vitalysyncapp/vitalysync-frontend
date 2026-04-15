import 'package:flutter/material.dart';

BoxDecoration buildPageDecoration(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return BoxDecoration(
    gradient: LinearGradient(
      colors: isDark
          ? const [
              Color(0xFF0E1726),
              Color(0xFF131D31),
              Color(0xFF0F1420),
            ]
          : const [
              Color.fromARGB(255, 229, 241, 255),
              Color(0xFFFFFFFF),
            ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );
}

Color pagePrimaryTextColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFF8FAFC)
      : const Color(0xFF0B1F44);
}

Color pageSecondaryTextColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFB8C2D6)
      : const Color(0xFF6B7280);
}

Color pageSurfaceColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF172235).withOpacity(0.92)
      : Colors.white.withOpacity(0.92);
}

Color pageBorderColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.white.withOpacity(0.10)
      : Colors.grey.withOpacity(0.12);
}
