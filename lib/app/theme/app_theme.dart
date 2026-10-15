import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Gaya teks yang dipakai berulang di banyak layar.
/// Berupa getter karena warnanya mengikuti tema terang/gelap.
abstract final class AppText {
  static TextStyle get overline => TextStyle(
        fontSize: 12,
        letterSpacing: 0.8,
        color: AppColors.muted,
        fontWeight: FontWeight.w500,
      );
  static TextStyle get title => TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      );
  static TextStyle get section => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      );
  static TextStyle get body => TextStyle(fontSize: 14, color: AppColors.ink);
  static TextStyle get muted => TextStyle(fontSize: 13, color: AppColors.muted);
}

ThemeData buildAppTheme(
  Brightness brightness, {
  bool amoled = false,
}) {
  final p = brightness == Brightness.dark
      ? (amoled ? AppPalette.amoled : AppPalette.dark)
      : AppPalette.light;
  final isBlack = p == AppPalette.amoled;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: p.paper,
    colorScheme: ColorScheme.fromSeed(
      seedColor: p.sage,
      brightness: brightness,
      surface: p.paper,
      primary: p.ink,
      onPrimary: p.white,
      // Tanpa ini, permukaan colorScheme di AMOLED tetap abu kehijauan
      // (hasil dari seed sage) dan panel/dialog terlihat seperti tema gelap biasa.
      onSurface: p.ink,
      surfaceContainerLowest: p.paper,
      surfaceContainerLow: isBlack ? p.white : null,
      surfaceContainer: p.white,
      surfaceContainerHigh: p.sand,
      surfaceContainerHighest: p.sand,
      outlineVariant: p.line,
    ),
    textTheme: ThemeData(brightness: brightness).textTheme.apply(
          bodyColor: p.ink,
          displayColor: p.ink,
        ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.paper,
      foregroundColor: p.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: p.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.ink,
        foregroundColor: p.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.paper,
      indicatorColor: p.sand,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? p.ink : p.muted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(color: selected ? p.ink : p.muted);
      }),
    ),
  );
}
