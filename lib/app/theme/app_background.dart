import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Latar global: gradien, di belakang semua layar.
///
/// Scaffold dibuat transparan di tema supaya lapisan ini terlihat saat konten
/// bergulir. Tidak ada tekstur noise; latar dibiarkan bersih.
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
      ],
    );
  }
}
