import 'package:flutter/material.dart';

import '../../core/widgets/noise_overlay.dart';
import 'app_colors.dart';

/// Latar global: gradasi dari atas yang lebih terang ke warna dasar, ditambah
/// noise halus. Dipasang di akar aplikasi, di belakang semua layar.
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
        NoiseOverlay(intensity: AppColors.isDark ? 1 : 0.6),
      ],
    );
  }
}
