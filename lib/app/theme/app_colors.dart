import 'package:flutter/material.dart';

/// Satu set warna lengkap untuk tema terang atau gelap.
///
/// Palet monokrom netral tanpa aksen hijau. Efek kaca dipakai pada huruf kana,
/// navigasi, toggle, dan tombol bulat; kartu memakai permukaan tembus pandang
/// tanpa border. Border hanya untuk status pilihan/jawaban.
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

  /// Terang netral-dingin, diukur dari screenshot mode terang referensi:
  /// latar abu muda, teks hampir hitam, tanpa rona hijau.
  static const light = AppPalette(
    paper: Color(0xFFEBECEE),
    ink: Color(0xFF1B1B1D),
    sage: Color(0xFF6B6D72),
    clay: Color(0xFFB0605A),
    sand: Color(0xFFE0E1E4),
    white: Color(0xFFF7F7F9),
    muted: Color(0xFF5E6066),
    line: Color(0xFFD0D1D5),
    guide: Color(0xFFDCDDE0),
    action: Color(0xFF1B1B1D),
    onAction: Color(0xFFF4F4F6),
    active: Color(0xFFB6B7BB),
    onActive: Color(0xFF1B1B1D),
    isDark: false,
  );

  /// Gelap netral seperti aplikasi kamus: latar hampir hitam, kartu abu tua,
  /// teks off-white. Gradien latar memakai stop yang diberikan pengguna.
  static const dark = AppPalette(
    paper: Color(0xFF121311),
    ink: Color(0xFFE7E6E1),
    sage: Color(0xFFAAAAAA),
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

  // Permukaan tembus pandang: menyatu dengan gradasi latar, tanpa border.
  // Sengaja dibuat sedikit lebih gelap dari versi awal.
  static Color get card =>
      isDark ? const Color(0x0AFFFFFF) : const Color(0xA8FFFFFF);
  static Color get cardRaised =>
      isDark ? const Color(0x12FFFFFF) : const Color(0xD0FFFFFF);
  static Color get divider =>
      isDark ? const Color(0x14FFFFFF) : const Color(0x12000000);

  // Bar melengkung (navigasi, toggle, tombol bulat).
  static Color get glass =>
      isDark ? const Color(0x16FFFFFF) : const Color(0x1C000000);
  static Color get glassPill =>
      isDark ? const Color(0x5EFFFFFF) : const Color(0x75000000);
  static Color get glassIcon =>
      isDark ? const Color(0xA6FFFFFF) : const Color(0x80000000);
  static Color get glassIconOn => const Color(0xFFFFFFFF);
  static Color get segPill =>
      isDark ? const Color(0x3DFFFFFF) : const Color(0x40000000);
  static Color get segText =>
      isDark ? const Color(0xB3FFFFFF) : const Color(0x8C000000);
  static Color get segTextOn =>
      isDark ? const Color(0xFFFFFFFF) : const Color(0xE6000000);

  /// Kekuatan noise: terang butuh lebih kuat (simpangan baku ±2,7–3,3 pada
  /// referensi) daripada gelap (±1,4).
  static double get noiseIntensity => isDark ? 1.0 : 1.1;

  // Mode terang: diukur dari screenshot referensi (abu sedang di atas, cepat
  // memudar, lalu datar #EBECEE di separuh bawah layar).
  static const _lightStops = [
    0.0,
    0.083,
    0.125,
    0.167,
    0.208,
    0.25,
    0.333,
    0.417,
    0.5,
    1.0,
  ];
  static const _lightColors = [
    Color(0xFF979898),
    Color(0xFFA0A2A1),
    Color(0xFFA8A9AA),
    Color(0xFFB2B3B5),
    Color(0xFFBDBEC0),
    Color(0xFFCACBCD),
    Color(0xFFD6D7D9),
    Color(0xFFDFE0E2),
    Color(0xFFEBECEE),
    Color(0xFFEFF0F2),
  ];

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
        stops: _lightStops,
        colors: _lightColors,
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
