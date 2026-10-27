import 'package:flutter/material.dart';

/// Warna aksen yang bisa dipilih pengguna. [mono] = tampilan hitam-putih
/// bawaan (tanpa warna).
enum AppAccent {
  mono(
    label: 'Mono',
    color: Color(0xFF8E8E93),
    deep: Color(0xFF8E8E93),
    swatch: Color(0xFF8E8E93),
  ),
  blue(
    label: 'Blue',
    color: Color(0xFF0A6CE0),
    deep: Color(0xFF0A4FC4),
    swatch: Color(0xFF0A84FF),
  ),
  green(
    label: 'Green',
    color: Color(0xFF1E8E3E),
    deep: Color(0xFF1B7A38),
    swatch: Color(0xFF34C759),
  ),
  orange(
    label: 'Orange',
    color: Color(0xFFC25E00),
    deep: Color(0xFFB35A00),
    swatch: Color(0xFFFF9500),
  ),
  purple(
    label: 'Purple',
    color: Color(0xFF5754D6),
    deep: Color(0xFF433FB5),
    swatch: Color(0xFF5E5CE6),
  ),
  red(
    label: 'Red',
    color: Color(0xFFE0254B),
    deep: Color(0xFFB01A3C),
    swatch: Color(0xFFFF2D55),
  );

  const AppAccent({
    required this.label,
    required this.color,
    required this.deep,
    required this.swatch,
  });

  final String label;

  /// Isi tombol, pil aktif, dan bar progress (putih terbaca di atasnya).
  final Color color;

  /// Warna pangkal gradien latar di bagian atas layar.
  final Color deep;

  /// Warna cerah untuk contoh warna di Settings dan kaca huruf.
  final Color swatch;

  bool get isMono => this == mono;

  static AppAccent byName(String? name) => AppAccent.values.firstWhere(
    (a) => a.name == name,
    orElse: () => AppAccent.mono,
  );
}

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
    this.accent = AppAccent.mono,
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

  /// Aksen yang sedang dipakai ([AppAccent.mono] = tanpa warna).
  final AppAccent accent;

  bool get hasAccent => !accent.isMono;

  /// Latar tombol utama: ink (hitam/putih) di mono, warna aksen di tema berwarna.
  Color get button => hasAccent ? accent.color : ink;
  Color get onButton => hasAccent ? Colors.white : paper;

  /// Salinan palet ini dengan warna aksen terpasang. Mono = palet apa adanya.
  AppPalette withAccent(AppAccent a) {
    if (a.isMono) return this;
    return AppPalette(
      paper: paper,
      ink: ink,
      sage: a.color,
      clay: clay,
      sand: sand,
      white: white,
      muted: muted,
      line: line,
      guide: guide,
      action: a.color,
      onAction: Colors.white,
      active: a.color,
      onActive: Colors.white,
      isDark: isDark,
      accent: a,
    );
  }

  /// Terang netral-dingin, diukur dari screenshot mode terang referensi:
  /// latar abu muda, teks hampir hitam, tanpa rona hijau.
  static const light = AppPalette(
    paper: Color(0xFFEBECEE),
    ink: Color(0xFF1B1B1D),
    sage: Color(0xFF6B6D72),
    clay: Color(0xFF9C4D48),
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

  /// Aksen pilihan pengguna. Diisi oleh `AppSettings`.
  static AppAccent accent = AppAccent.mono;

  static bool get hasAccent => !accent.isMono;

  static final _paletteCache = <String, AppPalette>{};

  /// Palet untuk tema [dark] dengan aksen [a] (di-cache).
  static AppPalette paletteFor(bool dark, AppAccent a) =>
      _paletteCache.putIfAbsent(
        '${dark ? 'd' : 'l'}-${a.name}',
        () => (dark ? AppPalette.dark : AppPalette.light).withAccent(a),
      );

  static AppPalette get _p => paletteFor(isDark, accent);

  static Color get button => _p.button;
  static Color get onButton => _p.onButton;

  static Color get paper => _p.paper;
  static Color get ink => _p.ink;
  static Color get sage => _p.sage;
  static Color get clay => _p.clay;
  static Color get sand => _p.sand;
  static Color get white => _p.white;
  static Color get muted => _p.muted;

  /// Teks sekunder di atas gradient latar (judul layar, body onboarding,
  /// label kecil). Di terang `muted` hanya 2,2:1 pada abu bagian atas, jadi
  /// dipakai warna yang lebih gelap (4,8:1 di #979898). Di gelap `muted`
  /// sudah cukup.
  static Color get onGradientMuted =>
      isDark ? _p.muted : const Color(0xFF2B2C30);

  /// Label kecil di bar kaca (navigasi): lebih pekat dari ikon supaya teks
  /// 11sp tetap terbaca (>= 4,5:1).
  static Color get glassLabel =>
      isDark ? const Color(0xE6FFFFFF) : const Color(0xCC000000);
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
  // Dibuat lebih pekat dan gelap dari versi sebelumnya (dulu terlalu
  // tembus pandang sehingga konten di belakang bar terlihat jelas).
  static Color get glass =>
      isDark ? const Color(0xD21F2023) : const Color(0xCCC4C6CA);
  static Color get glassPill => hasAccent
      ? accent.color.withValues(alpha: 0.94)
      : isDark
      ? const Color(0x5EFFFFFF)
      : const Color(0x75000000);
  static Color get glassIcon =>
      isDark ? const Color(0xA6FFFFFF) : const Color(0x80000000);
  static Color get glassIconOn => const Color(0xFFFFFFFF);
  static Color get segPill => hasAccent
      ? accent.color.withValues(alpha: 0.82)
      : isDark
      ? const Color(0x3DFFFFFF)
      : const Color(0x40000000);
  static Color get segText =>
      isDark ? const Color(0xB3FFFFFF) : const Color(0xB8000000);
  static Color get segTextOn => hasAccent || isDark
      ? const Color(0xFFFFFFFF)
      : const Color(0xE6000000);

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
    final mono = _monoGradient;
    if (!hasAccent) return mono;
    // Tema berwarna: bagian atas layar diwarnai aksen, lalu memudar ke warna
    // netral yang sama seperti mono (bawah layar tetap gelap/terang).
    final tint = isDark ? _darkTint : _lightTint;
    final source = isDark ? accent.deep : accent.swatch;
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: mono.stops,
      colors: [
        for (var i = 0; i < mono.colors.length; i++)
          Color.lerp(mono.colors[i], source, tint[i])!,
      ],
    );
  }

  // Seberapa kuat aksen mewarnai tiap stop (panjang = jumlah stop gradien).
  static const _darkTint = [1.0, 0.62, 0.36, 0.2, 0.1, 0.04, 0.0, 0.0];
  static const _lightTint = [
    0.55,
    0.46,
    0.4,
    0.34,
    0.27,
    0.2,
    0.12,
    0.06,
    0.0,
    0.0,
  ];

  static LinearGradient get _monoGradient {
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

  /// Border tipis kotak huruf: bertinta aksen di tema berwarna.
  static Color get tileBorder => hasAccent
      ? accent.swatch.withValues(alpha: isDark ? 0.5 : 0.55)
      : glassBorder;

  static Color get tileBorderStrong => hasAccent
      ? accent.swatch.withValues(alpha: 0.95)
      : glassBorderStrong;

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
    if (hasAccent) {
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accent.swatch.withValues(alpha: (0.72 * t).clamp(0.0, 0.9)),
          accent.swatch.withValues(alpha: (0.30 * t).clamp(0.0, 0.5)),
        ],
      );
    }
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
    // Mode terang: abu tua (bukan abu muda) supaya huruf terpilih jelas
    // berbeda dari latar abu terang.
    const gray = Color(0xFF4A4C52);
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        gray.withValues(alpha: (0.34 * t).clamp(0.0, 0.62)),
        gray.withValues(alpha: (0.24 * t).clamp(0.0, 0.46)),
      ],
    );
  }
}
