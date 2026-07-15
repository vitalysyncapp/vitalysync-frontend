import 'package:flutter/material.dart';

BoxDecoration buildPageDecoration(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return BoxDecoration(
    gradient: LinearGradient(
      colors: isDark
          ? const [Color(0xFF08111C), Color(0xFF0D1E2D), Color(0xFF10263A)]
          : const [Color(0xFFF1FBF6), Color(0xFFF3FBFF), Color(0xFFFFFFFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );
}

Color pagePrimaryTextColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFF8FAFC)
      : const Color(0xFF10334A);
}

Color pageSecondaryTextColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFB8C2D6)
      : const Color(0xFF5E7286);
}

Color pageSurfaceColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF162338).withValues(alpha: 0.9)
      : Colors.white.withValues(alpha: 0.84);
}

Color pageSubtleSurfaceColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.white.withValues(alpha: 0.055)
      : const Color(0xFFF8FAFC);
}

Color pageBorderColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.white.withValues(alpha: 0.1)
      : const Color(0xFFD4E9E2).withValues(alpha: 0.8);
}

List<BoxShadow> pageCardShadow(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.06),
      blurRadius: isDark ? 14 : 10,
      offset: const Offset(0, 5),
    ),
  ];
}

double pageBottomContentPadding(BuildContext context, {double extra = 36}) {
  return MediaQuery.paddingOf(context).bottom + extra;
}

double mainPageBottomContentPadding(BuildContext context) {
  return pageBottomContentPadding(context, extra: 48);
}
