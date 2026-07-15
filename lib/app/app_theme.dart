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
  final poppins = GoogleFonts.poppins();
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: poppins.fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1EAD83),
      brightness: Brightness.light,
    ),
  );
  final poppinsTextTheme = base.textTheme.apply(fontFamily: poppins.fontFamily);
  final poppinsPrimaryTextTheme = base.primaryTextTheme.apply(
    fontFamily: poppins.fontFamily,
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
      contentTextStyle: poppins.copyWith(color: Colors.white),
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
  final poppins = GoogleFonts.poppins();
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: poppins.fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF5BDEC1),
      brightness: Brightness.dark,
    ),
  );
  final poppinsTextTheme = base.textTheme.apply(fontFamily: poppins.fontFamily);
  final poppinsPrimaryTextTheme = base.primaryTextTheme.apply(
    fontFamily: poppins.fontFamily,
  );

  return base.copyWith(
    textTheme: poppinsTextTheme,
    primaryTextTheme: poppinsPrimaryTextTheme,
    scaffoldBackgroundColor: const Color(0xFF091320),
    pageTransitionsTheme: vitalySyncPageTransitionsTheme,
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF162338),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF142030),
      contentTextStyle: poppins.copyWith(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF26B590),
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
      color: const Color(0xFF162338),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );
}
