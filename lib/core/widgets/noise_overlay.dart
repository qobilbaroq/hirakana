import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

/// Titik-titik acak untuk efek noise. Dibuat sekali per ukuran layar.
class NoiseData {
  NoiseData._(this.whites, this.blacks, this.cell);

  /// Daftar koordinat (x0, y0, x1, y1, ...) per tingkat transparansi.
  final List<Float32List> whites;
  final List<Float32List> blacks;

  /// Ukuran satu butir noise (piksel logis).
  final double cell;

  /// Transparansi (0-255) tiap kelompok titik, sebelum dikali intensitas.
  /// Nilainya dipilih agar simpangan baku kecerahan noise (~1,4 dari 255 di
  /// latar gelap) sama dengan yang terukur pada gambar referensi.
  static const whiteAlphas = [4, 6, 8];
  static const blackAlphas = [7, 10, 13];

  /// Persentase butir yang diberi titik (putih dan hitam masing-masing).
  static const density = 0.07;

  factory NoiseData.generate(Size size, {double cell = 0.75, int seed = 7}) {
    final rng = math.Random(seed);
    final cells = (size.width / cell) * (size.height / cell);
    final perBucket = (cells * density / whiteAlphas.length).round();

    Float32List bucket() {
      final out = Float32List(perBucket * 2);
      for (var i = 0; i < perBucket; i++) {
        out[i * 2] = rng.nextDouble() * size.width;
        out[i * 2 + 1] = rng.nextDouble() * size.height;
      }
      return out;
    }

    return NoiseData._(
      [for (var i = 0; i < whiteAlphas.length; i++) bucket()],
      [for (var i = 0; i < blackAlphas.length; i++) bucket()],
      cell,
    );
  }
}

/// Lapisan noise halus di atas layar. Tidak memakai gambar apa pun: butiran
/// digambar dari titik acak (deterministik) lalu di-cache oleh Flutter.
/// Tidak menerima sentuhan.
class NoiseOverlay extends StatefulWidget {
  const NoiseOverlay({super.key, this.intensity = 1});

  /// 1 = kekuatan referensi (tema gelap). Tema terang memakai nilai lebih kecil.
  final double intensity;

  @override
  State<NoiseOverlay> createState() => _NoiseOverlayState();
}

class _NoiseOverlayState extends State<NoiseOverlay> {
  NoiseData? _data;
  Size? _size;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        if (!size.isFinite || size.isEmpty) return const SizedBox.shrink();
        if (_size != size) {
          _size = size;
          _data = NoiseData.generate(size);
        }
        return IgnorePointer(
          child: RepaintBoundary(
            child: CustomPaint(
              size: size,
              painter: _NoisePainter(_data!, widget.intensity),
              isComplex: true,
              willChange: false,
            ),
          ),
        );
      },
    );
  }
}

class _NoisePainter extends CustomPainter {
  _NoisePainter(this.data, this.intensity);

  final NoiseData data;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    void draw(List<Float32List> buckets, List<int> alphas, Color base) {
      for (var i = 0; i < buckets.length; i++) {
        final alpha = (alphas[i] * intensity).round().clamp(1, 255).toInt();
        final paint = Paint()
          ..color = base.withAlpha(alpha)
          ..strokeWidth = data.cell
          ..strokeCap = StrokeCap.square
          ..isAntiAlias = false;
        canvas.drawRawPoints(PointMode.points, buckets[i], paint);
      }
    }

    draw(data.whites, NoiseData.whiteAlphas, Colors.white);
    draw(data.blacks, NoiseData.blackAlphas, Colors.black);
  }

  @override
  bool shouldRepaint(_NoisePainter old) =>
      !identical(old.data, data) || old.intensity != intensity;
}
