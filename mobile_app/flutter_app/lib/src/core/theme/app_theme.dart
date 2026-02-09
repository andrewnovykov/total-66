import 'package:flutter/material.dart';

class AppTheme {
  static const Color brandIndigo = Color(0xFF6366F1);
  static const Color brandIndigoDark = Color(0xFF4F46E5);
  static const Color brandIndigoLight = Color(0xFFEEF2FF);
  static const Color textPrimary = Color(0xFF0D141C);
  static const Color textSecondary = Color(0xFF49739C);
  static const Color background = Color(0xFFE9EDF7);

  static ThemeData build() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandIndigo,
        primary: brandIndigo,
        secondary: const Color(0xFF14B8A6),
      ),
      scaffoldBackgroundColor: background,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: textSecondary, fontWeight: FontWeight.w600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: brandIndigo),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brandIndigo,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: brandIndigoLight,
        labelStyle: const TextStyle(
          color: brandIndigoDark,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            );
          }

          return const TextStyle(
            color: Color(0xFF90A0B9),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          );
        }),
      ),
    );
  }
}
