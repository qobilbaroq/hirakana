import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../utils/motion.dart';
import 'app_card.dart';

/// Baris mode latihan: ikon dalam kotak lembut, judul, keterangan, chevron.
///
/// Kartu masuk dengan fade + geser tipis sekali saat pertama dibangun, supaya
/// perpindahan ke daftar menu terasa halus tanpa mengganggu konten.
class ModeCard extends StatefulWidget {
  const ModeCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailingText,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? trailingText;

  @override
  State<ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<ModeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.025),
      end: Offset.zero,
    ).animate(_fade);
  }

  bool _entered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Mulai sekali. Durasi nol kalau pengguna mematikan animasi (Reduce
    // Motion), jadi kartu langsung tampil tanpa gerak.
    if (_entered) return;
    _entered = true;
    _controller.duration =
        motionDuration(context, const Duration(milliseconds: 240));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: AppCard(
          onTap: widget.onTap,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              IconTile(icon: widget.icon),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: AppText.bodyStrong.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(widget.subtitle, style: AppText.caption),
                  ],
                ),
              ),
              if (widget.trailingText != null) ...[
                const SizedBox(width: 8),
                Text(widget.trailingText!, style: AppText.caption),
              ],
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.muted.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
