import 'package:flutter/material.dart';

/// Satu set warna lengkap untuk tema terang atau gelap.
///
/// Palet netral dengan aksen sage yang diredam. Kartu memakai lapisan
/// tembus pandang tanpa border; efek kaca dipakai pada huruf kana dan
/// navigasi bawah.
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
    required this.card,
    required this.cardRaised,
    required this.divider,
    required this.bgTop,
    required this.glass,
    required this.glassPill,
    required this.glassIcon,
    required this.glassIconOn,
    required this.isDark,
  });

  final Color paper; // latar layar
  final Color ink; // teks utama
  final Color sage; // aksen netral (progress, ikon)
  final Color clay; // aksen hangat (salah / perlu dilihat lagi)
  final Color sand; // permukaan kedua (chip, kotak ikon)
  final Color white; // permukaan solid (dialog, elemen lama)
  final Color muted; // teks sekunder
  final Color line; // garis tipis
  final Color guide; // panduan huruf samar di kanvas menulis
  final Color action; // latar tombol utama
  final Color onAction; // teks/ikon di atas tombol utama
  final Color active; // latar pilihan aktif (abu-abu, bukan hitam)
  final Color onActive; // teks/ikon di atas pilihan aktif
  final Color card; // isi kartu: lapisan tembus pandang, tanpa border
  final Color cardRaised; // isi kartu di dalam kartu / elemen menonjol
  final Color divider; // garis pemisah di dalam kartu
  final Color bgTop; // warna atas gradasi latar layar
  final Color glass; // badan bar navigasi melengkung
  final Color glassPill; // pil tab aktif
  final Color glassIcon; // ikon tab tidak aktif
  final Color glassIconOn; // ikon tab aktif
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
    active: Color(0xFFB8B8B1),
    onActive: Color(0xFF242721),
    card: Color(0x99FFFFFF),
    cardRaised: Color(0xCCFFFFFF),
    divider: Color(0x14000000),
    bgTop: Color(0xFFDEDBD0),
    glass: Color(0x14000000),
    glassPill: Color(0x8C242721),
    glassIcon: Color(0x99242721),
    glassIconOn: Color(0xFFFFFFFF),
    isDark: false,
  );

  /// Gelap netral mengikuti referensi desain (abu-abu murni, tanpa rona
  /// hangat). Aksen sage diredam dan tombol utama berwarna sage gelap
  /// sehingga tidak ada blok terang yang menyilaukan.
  static const dark = AppPalette(
    paper: Color(0xFF111111),
    ink: Color(0xFFE6E6E6),
    sage: Color(0xFF95AA8B),
    clay: Color(0xFFCD9A86),
    sand: Color(0xFF262626),
    white: Color(0xFF1C1C1C),
    muted: Color(0xFFA0A0A0),
    line: Color(0xFF333333),
    guide: Color(0xFF2E2E2E),
    action: Color(0xFF5B7253),
    onAction: Color(0xFFF2F0E9),
    active: Color(0xFFC9C9C3),
    onActive: Color(0xFF111111),
    card: Color(0x0FFFFFFF),
    cardRaised: Color(0x1AFFFFFF),
    divider: Color(0x14FFFFFF),
    bgTop: Color(0xFF6A6A6A),
    glass: Color(0x1CFFFFFF),
    glassPill: Color(0x73FFFFFF),
    glassIcon: Color(0xA6FFFFFF),
    glassIconOn: Color(0xFFFFFFFF),
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
  static Color get card => _p.card;
  static Color get cardRaised => _p.cardRaised;
  static Color get divider => _p.divider;
  static Color get bgTop => _p.bgTop;
  static Color get glass => _p.glass;
  static Color get glassPill => _p.glassPill;
  static Color get glassIcon => _p.glassIcon;
  static Color get glassIconOn => _p.glassIconOn;

  static const _backgroundStops = [
    0.0,
    0.0625,
    0.125,
    0.1875,
    0.3125,
    0.4375,
    0.5625,
    1.0,
  ];
  static const _backgroundWeights = [
    1.0,
    0.93,
    0.78,
    0.60,
    0.31,
    0.11,
    0.01,
    0.0,
  ];

  /// Gradien latar halaman: warna `bgTop` di bagian atas, cepat menuju warna
  /// `paper`, lalu datar di separuh bawah layar. Keduanya mengikuti tema aktif.
  static LinearGradient get backgroundGradient {
    final base = _p.paper;
    final top = _p.bgTop;
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: _backgroundStops,
      colors: [for (final w in _backgroundWeights) Color.lerp(base, top, w)!],
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
