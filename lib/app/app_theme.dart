import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

const vitalySyncPageTransitionsTheme = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
    TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
    TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
  },
);

ThemeData buildVitalySyncLightTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1EAD83),
      brightness: Brightness.light,
    ),
  );
  final poppinsTextTheme = GoogleFonts.poppinsTextTheme(base.textTheme);
  final poppinsPrimaryTextTheme = GoogleFonts.poppinsTextTheme(
    base.primaryTextTheme,
  );

  return base.copyWith(
    textTheme: poppinsTextTheme,
    primaryTextTheme: poppinsPrimaryTextTheme,
    scaffoldBackgroundColor: const Color(0xFFF3FBF8),
    pageTransitionsTheme: vitalySyncPageTransitionsTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF14324A),
      contentTextStyle: poppinsTextTheme.bodyMedium?.copyWith(
        color: Colors.white,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1EAD83),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white.withValues(alpha: 0.92),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );
}

ThemeData buildVitalySyncDarkTheme() {
  final colors =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF5BDEC1),
        brightness: Brightness.dark,
      ).copyWith(
        primary: const Color(0xFF67E8C3),
        onPrimary: const Color(0xFF062D25),
        secondary: const Color(0xFF90CDF4),
        onSecondary: const Color(0xFF082A42),
        surface: const Color(0xFF101D2D),
        onSurface: const Color(0xFFF4F7FC),
        onSurfaceVariant: const Color(0xFFCBD5E5),
        surfaceContainerLowest: const Color(0xFF091320),
        surfaceContainerLow: const Color(0xFF152236),
        surfaceContainer: const Color(0xFF1C2D44),
        surfaceContainerHigh: const Color(0xFF253952),
        surfaceContainerHighest: const Color(0xFF304762),
        outline: const Color(0xFF8193AD),
        outlineVariant: const Color(0xFF435773),
      );
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colors,
  );
  final poppinsTextTheme = GoogleFonts.poppinsTextTheme(base.textTheme);
  final poppinsPrimaryTextTheme = GoogleFonts.poppinsTextTheme(
    base.primaryTextTheme,
  );

  return base.copyWith(
    textTheme: poppinsTextTheme,
    primaryTextTheme: poppinsPrimaryTextTheme,
    scaffoldBackgroundColor: colors.surfaceContainerLowest,
    iconTheme: IconThemeData(color: colors.onSurfaceVariant),
    dividerTheme: DividerThemeData(color: colors.outlineVariant),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: colors.surfaceContainerLow,
      labelStyle: TextStyle(color: colors.onSurfaceVariant),
      hintStyle: TextStyle(color: colors.onSurfaceVariant),
      helperStyle: TextStyle(color: colors.onSurfaceVariant),
      prefixIconColor: colors.onSurfaceVariant,
      suffixIconColor: colors.onSurfaceVariant,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.error, width: 2),
      ),
    ),
    pageTransitionsTheme: vitalySyncPageTransitionsTheme,
    dialogTheme: DialogThemeData(
      backgroundColor: colors.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF142030),
      contentTextStyle: poppinsTextTheme.bodyMedium?.copyWith(
        color: Colors.white,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.primary,
        side: BorderSide(color: colors.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    cardTheme: CardThemeData(
      color: colors.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );
}
