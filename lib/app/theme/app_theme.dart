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

/// ColorScheme dibuat eksplisit dari palet (bukan dari seed) supaya semua
/// komponen Material (chip, switch, dialog, snackbar, dst.) memakai warna
/// yang sama dengan widget kita, tanpa warna pastel/terang yang nyasar.
ColorScheme _schemeFor(AppPalette p, Brightness brightness) {
  final onAccent = p.isDark ? p.paper : Colors.white;
  return ColorScheme(
    brightness: brightness,
    primary: p.action,
    onPrimary: p.onAction,
    primaryContainer: p.sand,
    onPrimaryContainer: p.ink,
    secondary: p.sage,
    onSecondary: onAccent,
    secondaryContainer: p.sand,
    onSecondaryContainer: p.ink,
    tertiary: p.clay,
    onTertiary: onAccent,
    tertiaryContainer: p.sand,
    onTertiaryContainer: p.ink,
    error: p.isDark ? const Color(0xFFD08A80) : const Color(0xFFB3261E),
    onError: onAccent,
    surface: p.paper,
    onSurface: p.ink,
    onSurfaceVariant: p.muted,
    outline: p.line,
    outlineVariant: p.line,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: p.isDark ? p.sand : p.ink,
    onInverseSurface: p.isDark ? p.ink : p.paper,
    inversePrimary: p.sage,
    surfaceTint: Colors.transparent,
    surfaceContainerLowest: p.paper,
    surfaceContainerLow: p.paper,
    surfaceContainer: p.white,
    surfaceContainerHigh: p.sand,
    surfaceContainerHighest: p.sand,
  );
}

ThemeData buildAppTheme(
  Brightness brightness, {
  bool amoled = false,
}) {
  final p = brightness == Brightness.dark
      ? (amoled ? AppPalette.amoled : AppPalette.dark)
      : AppPalette.light;
  final roundShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.button),
  );
  // Teks tombol sekunder: di tema gelap pakai sage (lebih terbaca daripada
  // warna tombol utama yang gelap), di tema terang pakai ink.
  final linkColor = p.isDark ? p.sage : p.ink;

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: p.paper,
    colorScheme: _schemeFor(p, brightness),
    textTheme: ThemeData(brightness: brightness).textTheme.apply(
          bodyColor: p.ink,
          displayColor: p.ink,
        ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.paper,
      foregroundColor: p.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: p.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.action,
        foregroundColor: p.onAction,
        disabledBackgroundColor: p.action.withValues(alpha: 0.35),
        disabledForegroundColor: p.onAction.withValues(alpha: 0.7),
        minimumSize: const Size.fromHeight(48),
        shape: roundShape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.ink,
        side: BorderSide(color: p.line),
        shape: roundShape,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: linkColor),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        foregroundColor: p.muted,
        selectedForegroundColor: p.ink,
        selectedBackgroundColor: p.sage.withValues(alpha: 0.28),
        side: BorderSide(color: p.line),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? p.onAction : p.muted),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? p.action : p.sand),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? Colors.transparent : p.line),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: p.sage,
      inactiveTrackColor: p.sand,
      thumbColor: p.sage,
      overlayColor: p.sage.withValues(alpha: 0.15),
      valueIndicatorColor: p.action,
      valueIndicatorTextStyle: TextStyle(color: p.onAction),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: p.sage,
      linearTrackColor: p.sand,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: p.sand,
      selectedColor: p.sage.withValues(alpha: 0.3),
      labelStyle: TextStyle(color: p.ink),
      side: BorderSide.none,
    ),
    dividerTheme: DividerThemeData(color: p.line),
    dialogTheme: DialogThemeData(
      backgroundColor: p.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.paper,
      modalBackgroundColor: p.paper,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.isDark ? p.sand : p.ink,
      contentTextStyle: TextStyle(color: p.isDark ? p.ink : p.paper),
      actionTextColor: p.sage,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.paper,
      indicatorColor: p.sand,
      surfaceTintColor: Colors.transparent,
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
