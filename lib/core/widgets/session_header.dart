import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';

/// Baris atas layar sesi: pill Dismiss/Back, judul kecil, aksi, dan progress
/// tersegmentasi seperti aplikasi kamus.
class SessionHeader extends StatelessWidget {
  const SessionHeader({
    super.key,
    required this.title,
    required this.progress,
    required this.onLeading,
    this.leadingIcon = Icons.close,
    this.leadingLabel = 'Dismiss',
    this.trailing,
    this.segments = 6,
  });

  final String title;
  final double progress;
  final VoidCallback onLeading;
  final IconData leadingIcon;
  final String leadingLabel;
  final Widget? trailing;
  final int segments;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _DismissPill(
              icon: leadingIcon,
              label: leadingLabel,
              onTap: onLeading,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption.copyWith(
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 44,
              height: 44,
              child: Center(child: trailing),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm + 2),
        _SegmentedProgress(value: progress, segments: segments),
      ],
    );
  }
}

class _DismissPill extends StatelessWidget {
  const _DismissPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.only(left: 10, right: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 17, color: AppColors.ink),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppText.bodyStrong.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SegmentedProgress extends StatelessWidget {
  const _SegmentedProgress({required this.value, required this.segments});

  final double value;
  final int segments;

  @override
  Widget build(BuildContext context) {
    final progress = value.clamp(0.0, 1.0);
    return Row(
      children: List.generate(segments, (i) {
        final fill = (progress * segments - i).clamp(0.0, 1.0);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == segments - 1 ? 0 : 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: Container(
                height: 4,
                color: AppColors.sand,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: fill,
                  child: Container(color: AppColors.button),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
