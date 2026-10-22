import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    this.height = 6,
    this.color,
  });

  final double value; // 0..1
  final double height;
  final Color? color; // null = warna ink dari tema aktif

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: AppColors.sand,
        valueColor: AlwaysStoppedAnimation<Color>(color ?? AppColors.ink),
      ),
    );
  }
}
