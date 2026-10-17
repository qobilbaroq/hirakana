import 'package:flutter/material.dart';

/// Satu set warna lengkap (terang, gelap, atau AMOLED).
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
    required this.action,
    required this.onAction,
    required this.isDark,
  });

  final Color paper; // latar layar
  final Color ink; // teks utama
  final Color sage; // aksen (progress, pilihan terpilih)
  final Color clay; // aksen hangat (salah / perlu dilihat lagi)
  final Color sand; // permukaan kedua (kartu kategori, chip)
  final Color white; // permukaan kartu
  final Color muted; // teks sekunder
  final Color line; // garis tipis
  final Color guide; // panduan huruf samar di kanvas menulis
  final Color action; // latar tombol utama
  final Color onAction; // teks/ikon di atas tombol utama
  final bool isDark;

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
    action: Color(0xFF242721),
    onAction: Color(0xFFFFFFFF),
    isDark: false,
  );

  /// Gelap hangat yang senada dengan tema terang. Teks krem lembut (bukan
  /// putih), aksen sage diredam, dan tombol utama berwarna sage gelap
  /// sehingga tidak ada blok terang yang menyilaukan.
  static const dark = AppPalette(
    paper: Color(0xFF181A17),
    ink: Color(0xFFE2DFD6),
    sage: Color(0xFF95AA8B),
    clay: Color(0xFFCD9A86),
    sand: Color(0xFF2B2F29),
    white: Color(0xFF222520),
    muted: Color(0xFFA1A598),
    line: Color(0xFF3A3F37),
    guide: Color(0xFF353A31),
    action: Color(0xFF5B7253),
    onAction: Color(0xFFF2F0E9),
    isDark: true,
  );

  /// Mode AMOLED: latar hitam sejati, tetapi permukaan lain tetap hangat
  /// (sedikit kehijauan) supaya selaras dengan hitamnya, bukan abu netral.
  static const amoled = AppPalette(
    paper: Color(0xFF000000),
    ink: Color(0xFFD8D5CC),
    sage: Color(0xFF8DA384),
    clay: Color(0xFFC4937F),
    sand: Color(0xFF171A15),
    white: Color(0xFF0E100D),
    muted: Color(0xFF96998E),
    line: Color(0xFF262A23),
    guide: Color(0xFF1B1E18),
    action: Color(0xFF52684B),
    onAction: Color(0xFFEFEDE5),
    isDark: true,
  );
}

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
  static Color get action => _p.action;
  static Color get onAction => _p.onAction;
}
