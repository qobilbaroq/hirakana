/// Satu pilihan font untuk huruf Jepang.
class AppFontOption {
  const AppFontOption({
    required this.id,
    required this.label,
    required this.family,
    required this.note,
  });

  /// Disimpan di pengaturan.
  final String id;

  /// Nama yang tampil di Settings.
  final String label;

  /// Nama `family` di pubspec.yaml.
  final String family;

  /// Keterangan singkat gayanya.
  final String note;
}

/// Font huruf Jepang yang dipilih pengguna. Teks Latin tidak ikut berubah.
///
/// Nilai [selectedId] diisi oleh `AppSettings`; widget cukup memakai
/// [AppFonts.kana]. Karena nilainya bisa berubah, jangan dipakai di dalam
/// ekspresi `const`.
abstract final class AppFonts {
  static const defaultId = 'noto';

  static const options = [
    AppFontOption(
      id: defaultId,
      label: 'Standard',
      family: 'Noto Sans JP',
      note: 'Clean and neutral',
    ),
    AppFontOption(
      id: 'klee',
      label: 'Textbook',
      family: 'Klee One',
      note: 'Pen style, like a school textbook',
    ),
    AppFontOption(
      id: 'maru',
      label: 'Rounded',
      family: 'Zen Maru Gothic',
      note: 'Soft and friendly',
    ),
    AppFontOption(
      id: 'mincho',
      label: 'Brush',
      family: 'Yuji Syuku',
      note: 'Calligraphy feel, very Japanese',
    ),
    AppFontOption(
      id: 'kurenaido',
      label: 'Handwritten',
      family: 'Zen Kurenaido',
      note: 'Casual handwriting',
    ),
  ];

  static String selectedId = defaultId;

  static AppFontOption byId(String? id) => options.firstWhere(
    (o) => o.id == id,
    orElse: () => options.first,
  );

  static AppFontOption get current => byId(selectedId);

  /// Nama family untuk `TextStyle.fontFamily`.
  static String get kana => current.family;
}
