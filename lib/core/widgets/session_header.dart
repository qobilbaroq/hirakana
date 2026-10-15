import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import 'progress_bar.dart';

/// Baris atas layar sesi: tombol kembali/tutup, judul, aksi, dan progress bar.
class SessionHeader extends StatelessWidget {
  const SessionHeader({
    super.key,
    required this.title,
    required this.progress,
    required this.onLeading,
    this.leadingIcon = Icons.close,
    this.trailing,
  });

  final String title;
  final double progress;
  final VoidCallback onLeading;
  final IconData leadingIcon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Back',
              icon: Icon(leadingIcon),
              onPressed: onLeading,
            ),
            Expanded(
              child: Text(title, textAlign: TextAlign.center, style: AppText.overline),
            ),
            trailing ?? const SizedBox(width: 48, height: 48),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ProgressBar(value: progress),
      ],
    );
  }
}
