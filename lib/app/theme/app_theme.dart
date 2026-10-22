import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_page_transitions.dart';
import 'app_spacing.dart';

/// Gaya teks yang dipakai berulang di banyak layar.
/// Berupa getter karena warnanya mengikuti tema terang/gelap.
abstract final class AppText {
  static TextStyle get overline => TextStyle(
        fontSize: 12,
        letterSpacing: 0.2,
        color: AppColors.muted,
        fontWeight: FontWeight.w500,
      );

  /// Judul layar. Besar dan tenang, seperti judul kamus.
  static TextStyle get title => TextStyle(
        fontSize: 32,
        height: 1.12,
        letterSpacing: -0.9,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      );

  static TextStyle get section => TextStyle(
        fontSize: 18,
        height: 1.25,
        letterSpacing: -0.25,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      );

  static TextStyle get cardTitle => TextStyle(
        fontSize: 20,
        height: 1.2,
        letterSpacing: -0.35,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      );

  static TextStyle get body => TextStyle(
        fontSize: 15,
        height: 1.42,
        color: AppColors.ink,
      );

  static TextStyle get bodyStrong => TextStyle(
        fontSize: 15,
        height: 1.42,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      );

  static TextStyle get muted => TextStyle(
        fontSize: 13.5,
        height: 1.42,
        color: AppColors.muted,
      );

  static TextStyle get caption => TextStyle(
        fontSize: 12,
        height: 1.35,
        color: AppColors.muted,
      );
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

ThemeData buildAppTheme(Brightness brightness) {
  final p = brightness == Brightness.dark
      ? AppPalette.dark
      : AppPalette.light;
  final roundShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.button),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    // Latar digambar oleh AppBackground (gradien) di akar aplikasi.
    scaffoldBackgroundColor: Colors.transparent,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: AppPageTransitionsBuilder(),
        TargetPlatform.iOS: AppPageTransitionsBuilder(),
        TargetPlatform.linux: AppPageTransitionsBuilder(),
        TargetPlatform.macOS: AppPageTransitionsBuilder(),
        TargetPlatform.windows: AppPageTransitionsBuilder(),
        TargetPlatform.fuchsia: AppPageTransitionsBuilder(),
      },
    ),
    colorScheme: _schemeFor(p, brightness),
    textTheme: ThemeData(brightness: brightness).textTheme.apply(
          bodyColor: p.ink,
          displayColor: p.ink,
        ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: p.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: p.ink,
      ),
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
        // Tombol utama tetap inverted: terang di tema gelap.
        backgroundColor: p.ink,
        foregroundColor: p.paper,
        disabledBackgroundColor: p.sand,
        disabledForegroundColor: p.muted,
        minimumSize: const Size.fromHeight(52),
        shape: roundShape,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.ink,
        side: BorderSide(color: p.line),
        shape: roundShape,
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.ink,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        foregroundColor: p.muted,
        selectedForegroundColor: p.onActive,
        selectedBackgroundColor: p.active,
        side: BorderSide(
          color: p.isDark
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.black.withValues(alpha: 0.08),
        ),
        shape: const StadiumBorder(),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? p.onActive : p.muted),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? p.active : p.sand),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? Colors.transparent : p.line),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: p.ink,
      inactiveTrackColor: p.sand,
      thumbColor: p.ink,
      overlayColor: p.ink.withValues(alpha: 0.12),
      valueIndicatorColor: p.ink,
      valueIndicatorTextStyle: TextStyle(color: p.paper),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: p.ink,
      linearTrackColor: p.sand,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: p.sand,
      selectedColor: p.active,
      labelStyle: TextStyle(color: p.ink),
      secondaryLabelStyle: TextStyle(color: p.onActive),
      side: BorderSide.none,
      shape: const StadiumBorder(),
    ),
    dividerTheme: DividerThemeData(color: p.line, thickness: 1, space: 1),
    dialogTheme: DialogThemeData(
      backgroundColor: p.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.paper,
      modalBackgroundColor: p.paper,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.sand,
      contentTextStyle: TextStyle(color: p.ink),
      actionTextColor: p.ink,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      indicatorColor: p.active,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? p.onActive : p.muted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(color: selected ? p.onActive : p.muted);
      }),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: p.muted,
      textColor: p.ink,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    ),
  );
}
