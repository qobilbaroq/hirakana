import 'package:flutter/material.dart';

import '../../core/widgets/noise_overlay.dart';
import '../theme/app_colors.dart';

/// Latar global: gradien di belakang semua layar, dan noise halus di atasnya.
///
/// Scaffold dibuat transparan di tema supaya gradien terlihat saat konten
/// bergulir. Noise digambar dari titik acak (tanpa gambar) dan tidak menerima
/// sentuhan; lihat [NoiseOverlay].
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
        ),
        child,
        NoiseOverlay(intensity: AppColors.noiseIntensity),
      ],
    );
  }
}
