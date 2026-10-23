import 'dart:math' as math;

/// Geometri bar navigasi melengkung seperti di referensi desain.
///
/// Bar berbentuk kapsul yang dibengkokkan jadi busur (tengah lebih tinggi,
/// ujung lebih rendah). Semua posisi memakai "panjang busur" `s` yang diukur
/// dari titik tengah bar (negatif = kiri, positif = kanan). Berkas ini tidak
/// bergantung pada Flutter supaya bisa diuji sendirian.
class CurvedNavGeometry {
  CurvedNavGeometry({
    required double maxWidth,
    required this.count,
    double? thickness,
  }) : assert(count > 0),
       thickness = thickness ?? (maxWidth * 0.135).clamp(48.0, 58.0) {
    // Lebar satu slot dibatasi supaya bar tidak melebar kalau itemnya sedikit.
    slot = ((maxWidth - this.thickness) / count)
        .clamp(0.0, maxWidth * 0.2)
        .toDouble();
    halfArc = count * slot / 2;
    width = count * slot + this.thickness;
    final sag = width * sagFactor;
    radius = halfArc <= 0 ? 1.0 : (halfArc * halfArc) / (2 * sag) + sag / 2;
    phi = halfArc / radius;
    height = this.thickness + radius * (1 - math.cos(phi));
    pillLength = slot * 1.06;
    pillThickness = this.thickness * 0.7;
  }

  /// Seberapa melengkung bar: tinggi lengkungan = lebar bar × nilai ini.
  static const sagFactor = 0.052;

  final int count;

  /// Tebal bar (diameter ujung bulatnya).
  final double thickness;

  late final double slot;
  late final double halfArc;

  /// Lebar total bar.
  late final double width;

  /// Tinggi total widget (tebal bar + turunnya ujung).
  late final double height;

  /// Jari-jari busur garis tengah bar.
  late final double radius;

  /// Sudut (radian) dari tengah ke ujung garis tengah.
  late final double phi;

  /// Panjang dan tebal pil aktif.
  late final double pillLength;
  late final double pillThickness;

  /// Panjang busur dari tengah bar ke pusat slot ke-[i].
  double slotCenter(int i) => (i - (count - 1) / 2) * slot;

  /// Titik pada garis tengah bar (koordinat dari pojok kiri atas widget).
  (double, double) centerlinePoint(double s) {
    final a = s / radius;
    return (
      width / 2 + radius * math.sin(a),
      thickness / 2 + radius * (1 - math.cos(a)),
    );
  }

  /// Sudut putar (radian, searah jarum jam) agar item sejajar dengan busur.
  double tangentAngle(double s) => s / radius;

  /// Tepi kiri dan kanan pil aktif (panjang busur) saat berada di slot [i].
  (double, double) pillEdges(int i) {
    final c = slotCenter(i);
    return (c - pillLength / 2, c + pillLength / 2);
  }

  /// Tepi pil di tengah animasi pindah tab: sisi depan berlari lebih dulu
  /// sehingga pil memanjang ke tujuan, lalu sisi belakang menyusul dan pil
  /// kembali ke ukuran semula. [t] dari 0 sampai 1.
  static (double, double) stretch({
    required double l0,
    required double r0,
    required double l1,
    required double r1,
    required double t,
  }) {
    double lead(double x) => _easeOutCubic(_interval(x, 0.0, 0.6));
    double trail(double x) => _easeInOutCubic(_interval(x, 0.22, 1.0));
    final movingRight = (l1 + r1) >= (l0 + r0);
    if (movingRight) {
      return (l0 + (l1 - l0) * trail(t), r0 + (r1 - r0) * lead(t));
    }
    return (l0 + (l1 - l0) * lead(t), r0 + (r1 - r0) * trail(t));
  }

  static double _interval(double t, double begin, double end) =>
      ((t - begin) / (end - begin)).clamp(0.0, 1.0).toDouble();

  static double _easeOutCubic(double x) => 1 - math.pow(1 - x, 3).toDouble();

  static double _easeInOutCubic(double x) =>
      x < 0.5 ? 4 * x * x * x : 1 - math.pow(-2 * x + 2, 3).toDouble() / 2;
}
