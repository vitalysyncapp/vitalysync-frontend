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
      ? Theme.of(context).colorScheme.onSurface
      : const Color(0xFF10334A);
}

Color pageSecondaryTextColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Theme.of(context).colorScheme.onSurfaceVariant
      : const Color(0xFF5E7286);
}

Color pageSurfaceColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Theme.of(context).colorScheme.surfaceContainer.withValues(alpha: 0.96)
      : Colors.white.withValues(alpha: 0.84);
}

Color pageSubtleSurfaceColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Theme.of(context).colorScheme.surfaceContainerHigh
      : const Color(0xFFF8FAFC);
}

Color pageBorderColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Theme.of(context).colorScheme.outlineVariant
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

/// Keeps semantic accent colors readable on dark cards and tinted controls.
Color pageAccentColor(BuildContext context, Color color) {
  return Theme.of(context).brightness == Brightness.dark
      ? Color.lerp(color, Colors.white, 0.48)!
      : color;
}

double pageBottomContentPadding(BuildContext context, {double extra = 36}) {
  return MediaQuery.paddingOf(context).bottom + extra;
}

double mainPageBottomContentPadding(BuildContext context) {
  return pageBottomContentPadding(context, extra: 96);
}
