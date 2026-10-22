import 'package:flutter/material.dart';

/// Satu set warna lengkap untuk tema terang atau gelap.
///
/// Palet monokrom. Efek kaca hanya dipakai pada huruf kana; kartu, navigasi,
/// dan kontrol lain memakai permukaan biasa dengan border tipis.
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
    required this.active,
    required this.onActive,
    required this.isDark,
  });

  final Color paper; // latar layar
  final Color ink; // teks utama
  final Color sage; // aksen netral (progress, ikon)
  final Color clay; // aksen hangat (salah / perlu dilihat lagi)
  final Color sand; // permukaan kedua (chip, kotak ikon)
  final Color white; // permukaan kartu
  final Color muted; // teks sekunder
  final Color line; // garis tipis
  final Color guide; // panduan huruf samar di kanvas menulis
  final Color action; // latar tombol utama
  final Color onAction; // teks/ikon di atas tombol utama
  final Color active; // latar pilihan aktif (abu-abu, bukan hitam)
  final Color onActive; // teks/ikon di atas pilihan aktif
  final bool isDark;

  static const light = AppPalette(
    paper: Color(0xFFF3F3EF),
    ink: Color(0xFF151614),
    sage: Color(0xFF73786E),
    clay: Color(0xFFB56E5F),
    sand: Color(0xFFE7E7E1),
    white: Color(0xFFFFFFFF),
    muted: Color(0xFF6E716B),
    line: Color(0xFFD7D7D0),
    guide: Color(0xFFE2E2DA),
    action: Color(0xFF151614),
    onAction: Color(0xFFF7F7F3),
    active: Color(0xFFB8B8B1),
    onActive: Color(0xFF151614),
    isDark: false,
  );

  /// Gelap netral seperti aplikasi kamus: latar hampir hitam, kartu abu tua,
  /// teks off-white. Gradien latar memakai stop yang diberikan pengguna.
  static const dark = AppPalette(
    paper: Color(0xFF121311),
    ink: Color(0xFFE7E6E1),
    sage: Color(0xFFA9AEA5),
    clay: Color(0xFFC98A7C),
    sand: Color(0xFF272826),
    white: Color(0xFF1B1C1A),
    muted: Color(0xFFB0B3AB),
    line: Color(0xFF343532),
    guide: Color(0xFF2D2E2B),
    action: Color(0xFF2A2B28),
    onAction: Color(0xFFEDECE7),
    active: Color(0xFFC9C9C3),
    onActive: Color(0xFF121311),
    isDark: true,
  );
}

/// Warna yang dipakai widget. Nilainya mengikuti tema aktif ([isDark]),
/// jadi BUKAN konstanta: jangan dipakai di dalam ekspresi `const`.
abstract final class AppColors {
  static bool isDark = false;

  static AppPalette get _p => isDark ? AppPalette.dark : AppPalette.light;

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
  static Color get active => _p.active;
  static Color get onActive => _p.onActive;

  static const _backgroundStops = [
    0.0,
    0.15,
    0.28,
    0.37,
    0.44,
    0.53,
    0.84,
    1.0,
  ];
  static const _backgroundColors = [
    Color(0xFF868686),
    Color(0xFF4B4B4B),
    Color(0xFF2E2E2E),
    Color(0xFF201F1F),
    Color(0xFF181818),
    Color(0xFF151414),
    Color(0xFF111111),
    Color(0xFF111111),
  ];

  /// Gradien latar halaman. Stop persis dari referensi pengguna, dicampur
  /// sedikit dengan warna paper supaya teks terang di bagian atas tetap terbaca.
  static LinearGradient get backgroundGradient {
    if (!isDark) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF8F8F4), Color(0xFFE8E8E2)],
      );
    }
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: _backgroundStops,
      colors: [
        for (final c in _backgroundColors)
          Color.alphaBlend(c.withValues(alpha: 0.6), _p.paper),
      ],
    );
  }

  /// Border kaca: putih tipis di gelap, tinta tipis di terang.
  static Color get glassBorder => isDark
      ? Colors.white.withValues(alpha: 0.18)
      : Colors.black.withValues(alpha: 0.08);

  static Color get glassBorderStrong => isDark
      ? Colors.white.withValues(alpha: 0.34)
      : Colors.black.withValues(alpha: 0.16);

  /// Gradien kaca untuk **keadaan aktif/terpelajari**. Di gelap tintanya putih
  /// (bukan gradien permukaan gelap), supaya huruf dan pilihan terasa seperti
  /// kaca putih. Di terang tintanya abu-abu, bukan hitam.
  static LinearGradient activeGlassGradient({double intensity = 1}) {
    final t = intensity.clamp(0.0, 1.5);
    if (isDark) {
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: (0.36 * t).clamp(0.0, 0.58)),
          Colors.white.withValues(alpha: (0.16 * t).clamp(0.0, 0.26)),
        ],
      );
    }
    final gray = const Color(0xFFB8B8B1);
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        gray.withValues(alpha: (0.30 * t).clamp(0.0, 0.5)),
        gray.withValues(alpha: (0.20 * t).clamp(0.0, 0.36)),
      ],
    );
  }
}
