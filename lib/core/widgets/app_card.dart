import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

/// Permukaan kartu: tembus pandang tanpa border supaya menyatu dengan
/// gradasi latar (lihat [AppColors.card]).
///
/// [color] dipakai untuk kartu yang butuh latar berbeda (misalnya kartu
/// peringatan); default-nya permukaan kartu tema.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.color,
    this.border,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final BorderSide? border;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.card),
      side: border ?? BorderSide.none,
    );
    final content = Padding(padding: padding, child: child);

    return Material(
      color: color ?? AppColors.card,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(
              onTap: onTap,
              splashColor: AppColors.ink.withValues(alpha: 0.05),
              highlightColor: AppColors.ink.withValues(alpha: 0.03),
              child: content,
            ),
    );
  }
}

/// Kotak ikon kecil dengan tint warna di atas kartu biasa.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    this.size = 46,
    this.radius = 12,
    this.tint,
  });

  final IconData icon;
  final double size;
  final double radius;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final color = tint ?? AppColors.sage;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppColors.isDark ? 0.26 : 0.34),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, size: size * 0.48, color: AppColors.ink),
    );
  }
}
