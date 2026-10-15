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
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
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
            backgroundColor: AppColors.paper,
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
            backgroundColor: AppColors.sage,
            foregroundColor: AppColors.white,
            disabledBackgroundColor: AppColors.sage.withValues(alpha: 0.45),
            disabledForegroundColor: AppColors.white.withValues(alpha: 0.8),
          ),
          child: child,
        );
      case ButtonKind.primary:
        return FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            minimumSize: size,
            shape: shape,
            disabledBackgroundColor: AppColors.ink.withValues(alpha: 0.25),
            disabledForegroundColor: AppColors.white.withValues(alpha: 0.8),
          ),
          child: child,
        );
    }
  }
}
