import 'package:flutter/material.dart';

abstract final class NalviumColors {
  static const background = Color(0xFF07111F);
  static const surface = Color(0xFF0B1728);
  static const surfaceAlternative = Color(0xFF101F34);
  static const surfaceElevated = Color(0xFF14263E);
  static const primary = Color(0xFF2864FF);
  static const primaryLight = Color(0xFF72A0FF);
  static const info = Color(0xFFAFC6FF);
  static const ink = Color(0xFFF7F9FC);
  static const primaryDark = Color(0xFFB8C8E6);
  static const textSecondary = Color(0xFFA6B1C2);
  static const textTertiary = Color(0xFF6F7D91);
  static const border = Color(0x14FFFFFF);
  static const divider = Color(0x0FFFFFFF);
  static const success = Color(0xFF72A0FF);
  static const warning = Color(0xFFF2B35D);
  static const danger = Color(0xFFFF6B6B);
}

abstract final class NalviumSpacing {
  static const xs = 6.0;
  static const sm = 12.0;
  static const md = 18.0;
  static const lg = 26.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

abstract final class NalviumRadii {
  static const sm = 16.0;
  static const md = 22.0;
  static const lg = 30.0;
  static const pill = 100.0;
}

ThemeData nalviumTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: NalviumColors.primary,
        brightness: Brightness.dark,
      ).copyWith(
        primary: NalviumColors.primary,
        onPrimary: Colors.white,
        secondary: NalviumColors.primaryLight,
        surface: NalviumColors.surface,
        onSurface: NalviumColors.ink,
        error: NalviumColors.danger,
      );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: NalviumColors.background,
    fontFamily: 'sans',
    visualDensity: VisualDensity.standard,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: NalviumColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: NalviumColors.ink,
        fontSize: 19,
        fontWeight: FontWeight.w700,
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: NalviumColors.ink,
        fontSize: 36,
        height: 1.05,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.1,
      ),
      headlineMedium: TextStyle(
        color: NalviumColors.ink,
        fontSize: 28,
        height: 1.1,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
      ),
      titleLarge: TextStyle(
        color: NalviumColors.ink,
        fontSize: 21,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: TextStyle(
        color: NalviumColors.textSecondary,
        fontSize: 16,
        height: 1.45,
      ),
      bodyMedium: TextStyle(
        color: NalviumColors.textSecondary,
        fontSize: 14,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        color: NalviumColors.ink,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: NalviumColors.divider,
      thickness: 1,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: NalviumColors.surface,
      indicatorColor: NalviumColors.primary.withValues(alpha: .18),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? NalviumColors.ink
              : NalviumColors.textTertiary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? NalviumColors.ink
              : NalviumColors.textTertiary,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: NalviumColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NalviumRadii.md),
        side: const BorderSide(color: NalviumColors.border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        backgroundColor: NalviumColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: NalviumColors.surfaceElevated,
        disabledForegroundColor: NalviumColors.textTertiary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NalviumRadii.md),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: NalviumColors.info,
        side: const BorderSide(color: NalviumColors.border, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NalviumRadii.md),
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: NalviumColors.surfaceAlternative,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NalviumRadii.md),
        borderSide: const BorderSide(color: NalviumColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NalviumRadii.md),
        borderSide: const BorderSide(color: NalviumColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(NalviumRadii.md),
        borderSide: const BorderSide(color: NalviumColors.primary, width: 2),
      ),
      labelStyle: const TextStyle(color: NalviumColors.textSecondary),
      hintStyle: const TextStyle(color: NalviumColors.textTertiary),
    ),
  );
}
