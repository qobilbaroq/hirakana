import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

enum ButtonKind { primary, secondary, sage }

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = ButtonKind.primary,
    this.trailing,
  });

  final String label;
  final VoidCallback? onPressed;
  final ButtonKind kind;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.button),
    );
    const size = Size.fromHeight(52);
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Icon(trailing, size: 18),
        ],
      ],
    );

    switch (kind) {
      case ButtonKind.secondary:
        return OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: size,
            shape: shape,
            foregroundColor: AppColors.ink,
            disabledForegroundColor: AppColors.muted.withValues(alpha: 0.6),
            backgroundColor: Colors.transparent,
            side: BorderSide(color: AppColors.line),
          ),
          child: child,
        );
      case ButtonKind.sage:
        return FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            minimumSize: size,
            shape: shape,
            backgroundColor: AppColors.active,
            foregroundColor: AppColors.onActive,
            disabledBackgroundColor: AppColors.sand,
            disabledForegroundColor: AppColors.muted,
          ),
          child: child,
        );
      case ButtonKind.primary:
        // Tombol utama dibalik: terang di tema gelap, gelap di tema terang.
        // Ini memberi satu titik fokus tanpa memakai warna aksen.
        return FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            minimumSize: size,
            shape: shape,
            backgroundColor: AppColors.ink,
            foregroundColor: AppColors.paper,
            disabledBackgroundColor: AppColors.sand,
            disabledForegroundColor: AppColors.muted,
          ),
          child: child,
        );
    }
  }
}
