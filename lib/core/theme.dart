import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HColors {
  static const forest = Color(0xFF1B5A3A);
  static const lime = Color(0xFFE2F0CB);
  static const limeStrong = Color(0xFFB4D95C);
  static const cream = Color(0xFFF9F5E5);
  static const card = Color(0xFFFFFFFF);
  static const orange = Color(0xFFE8863A);
  static const orangeSoft = Color(0xFFFDEBD9);
  static const ink = Color(0xFF1C2A22);
  static const muted = Color(0xFF6A7468);
  static const line = Color(0xFFE6E1CC);
  static const danger = Color(0xFFC0392B);
  static const dangerSoft = Color(0xFFFADBD8);
  static const mint = Color(0xFFE3F2E6);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: HColors.forest,
      primary: HColors.forest,
      surface: HColors.cream,
    ),
  );
  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: HColors.line),
  );
  return base.copyWith(
    scaffoldBackgroundColor: HColors.cream,
    textTheme: GoogleFonts.interTextTheme(base.textTheme)
        .apply(bodyColor: HColors.ink, displayColor: HColors.ink),
    appBarTheme: const AppBarTheme(
      backgroundColor: HColors.cream,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: HColors.ink,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: const TextStyle(color: HColors.muted, fontSize: 13),
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: HColors.forest, width: 1.5),
      ),
      errorBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: HColors.danger),
      ),
      focusedErrorBorder: inputBorder.copyWith(
        borderSide: const BorderSide(color: HColors.danger, width: 1.5),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: HColors.forest,
      height: 64,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected)
              ? Colors.white
              : HColors.muted,
          size: 22,
        ),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: HColors.forest,
      unselectedLabelColor: HColors.muted,
      indicatorColor: HColors.forest,
      labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? HColors.forest : HColors.line,
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
