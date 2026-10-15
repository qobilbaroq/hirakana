import 'package:flutter/material.dart';

/// Satu set warna lengkap (terang atau gelap).
class AppPalette {
  const AppPalette({
    required this.paper,
    required this.ink,
    required this.sage,
    required this.clay,
    required this.sand,
    required this.white,
    required this.muted,
    required this.line,
    required this.guide,
  });

  final Color paper; // latar layar
  final Color ink; // teks utama / tombol utama
  final Color sage;
  final Color clay;
  final Color sand;
  final Color white; // permukaan kartu
  final Color muted;
  final Color line; // garis tipis
  final Color guide; // panduan huruf samar di kanvas menulis

  static const light = AppPalette(
    paper: Color(0xFFF7F5EF),
    ink: Color(0xFF242721),
    sage: Color(0xFF82947A),
    clay: Color(0xFFD8A08B),
    sand: Color(0xFFE9E5DA),
    white: Color(0xFFFFFFFF),
    muted: Color(0xFF777B71),
    line: Color(0xFFDDD9CC),
    guide: Color(0xFFE3DFD2),
  );

  static const dark = AppPalette(
    paper: Color(0xFF171916),
    ink: Color(0xFFECE9E0),
    sage: Color(0xFF9DB093),
    clay: Color(0xFFE0A992),
    sand: Color(0xFF2A2D27),
    white: Color(0xFF22251F),
    muted: Color(0xFF9FA395),
    line: Color(0xFF3A3E36),
    guide: Color(0xFF383C33),
  );

  /// Mode AMOLED: hitam sejati, hemat baterai di layar OLED.
  static const amoled = AppPalette(
    paper: Color(0xFF000000),
    ink: Color(0xFFECE9E0),
    sage: Color(0xFF9DB093),
    clay: Color(0xFFE0A992),
    sand: Color(0xFF181818),
    white: Color(0xFF0B0B0B),
    muted: Color(0xFF9FA395),
    line: Color(0xFF262626),
    guide: Color(0xFF1A1A1A),
  );
}

/// Warna yang dipakai widget. Nilainya mengikuti tema aktif ([isDark]),
/// jadi BUKAN konstanta: jangan dipakai di dalam ekspresi `const`.
/// Warna yang dipakai widget. Nilainya mengikuti tema aktif ([isDark]),
/// jadi BUKAN konstanta: jangan dipakai di dalam ekspresi `const`.
abstract final class AppColors {
  static bool isDark = false;

  /// Hanya berpengaruh kalau [isDark] juga true.
  static bool isAmoled = false;

  static AppPalette get _p {
    if (!isDark) return AppPalette.light;
    return isAmoled ? AppPalette.amoled : AppPalette.dark;
  }

  static Color get paper => _p.paper;
  static Color get ink => _p.ink;
  static Color get sage => _p.sage;
  static Color get clay => _p.clay;
  static Color get sand => _p.sand;
  static Color get white => _p.white;
  static Color get muted => _p.muted;
  static Color get line => _p.line;
  static Color get guide => _p.guide;
}
