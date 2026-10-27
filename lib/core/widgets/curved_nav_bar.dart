import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_fonts.dart';
import '../utils/motion.dart';
import 'curved_nav_geometry.dart';

/// Satu item pada bar melengkung: ikon, huruf (mis. `あ`), atau teks pendek.
class CurvedNavItem {
  const CurvedNavItem({
    required this.label,
    this.icon,
    this.selectedIcon,
    this.glyph,
    this.text,
  }) : assert(icon != null || glyph != null || text != null);

  /// Untuk aksesibilitas (pembaca layar), tooltip, dan label terlihat saat
  /// [CurvedNavBar.showLabels] menyala.
  final String label;
  final IconData? icon;

  /// Ikon terisi yang dipakai saat item ini terpilih (bukan hanya warna).
  final IconData? selectedIcon;
  final String? glyph;
  final String? text;
}

/// Bar berbentuk busur melayang. Pil aktif memanjang ke item yang dipilih,
/// lalu kembali ke ukuran pil biasa (lihat [CurvedNavGeometry.stretch]).
///
/// Dipakai untuk navigasi bawah dan, dengan item teks, untuk toggle
/// Hiragana/Katakana. Warna bawaan = warna navigasi.
class CurvedNavBar extends StatefulWidget {
  const CurvedNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.thickness,
    this.slotWidth,
    this.sagFactor = CurvedNavGeometry.defaultSagFactor,
    this.iconSize = 26,
    this.glassColor,
    this.pillColor,
    this.idleColor,
    this.activeColor,
    this.haptics = true,
    this.showLabels = false,
  });

  final List<CurvedNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final double? thickness;
  final double? slotWidth;
  final double sagFactor;
  final double iconSize;
  final Color? glassColor;
  final Color? pillColor;
  final Color? idleColor;
  final Color? activeColor;
  final bool haptics;

  /// Tampilkan label teks kecil di bawah ikon (navigasi bawah). Toggle teks
  /// tidak memakainya karena itemnya sudah berupa teks.
  final bool showLabels;

  @override
  State<CurvedNavBar> createState() => _CurvedNavBarState();
}

class _CurvedNavBarState extends State<CurvedNavBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _duration,
  );

  /// Durasi animasi pil dan warna ikon dibuat sama di semua bar (navigasi
  /// bawah dan toggle) supaya geraknya konsisten.
  static const _duration = Duration(milliseconds: 420);

  CurvedNavGeometry? _geometry;
  double _l0 = 0, _r0 = 0, _l1 = 0, _r1 = 0;

  /// Item yang sedang ditampilkan sebagai aktif. Diubah langsung saat disentuh
  /// (sebelum halaman di belakangnya dibangun ulang), supaya animasi tidak
  /// tersendat oleh pembangunan halaman yang berat.
  late int _shown = widget.currentIndex;

  /// Jumlah sentuhan yang sudah menggerakkan pil tetapi belum diteruskan ke
  /// [CurvedNavBar.onTap]. Selama > 0, perubahan indeks dari luar diabaikan
  /// supaya pil tidak melompat balik saat disentuh cepat berturut-turut.
  int _pending = 0;

  void _animateTo(int index) {
    final g = _geometry;
    // Reduce Motion: pil langsung pindah tanpa animasi.
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (g == null || reduce) {
      _shown = index;
      return;
    }
    // Mulai dari posisi pil saat ini (juga kalau pil masih bergerak).
    final (l, r) = _edges(g);
    final (nl, nr) = g.pillEdges(index);
    _l0 = l;
    _r0 = r;
    _l1 = nl;
    _r1 = nr;
    _shown = index;
    _controller.forward(from: 0);
  }

  @override
  void didUpdateWidget(CurvedNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Perubahan dari luar (bukan dari sentuhan di bar ini).
    if (_pending == 0 && widget.currentIndex != _shown) {
      _animateTo(widget.currentIndex);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  (double, double) _edges(CurvedNavGeometry g) {
    if (!_controller.isAnimating) return g.pillEdges(_shown);
    return CurvedNavGeometry.stretch(
      l0: _l0,
      r0: _r0,
      l1: _l1,
      r1: _r1,
      t: _controller.value,
    );
  }

  void _select(int i) {
    if (i == _shown) return;
    if (widget.haptics) HapticFeedback.selectionClick();
    // Animasi pil mulai dulu; perpindahan halaman dijalankan di frame
    // berikutnya supaya frame pertama animasi tidak ikut tertahan.
    setState(() => _animateTo(i));
    _pending++;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pending = _pending > 0 ? _pending - 1 : 0;
      if (mounted) widget.onTap(i);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final g = CurvedNavGeometry(
          maxWidth: constraints.maxWidth,
          count: widget.items.length,
          thickness: widget.thickness,
          slotWidth: widget.slotWidth,
          sagFactor: widget.sagFactor,
        );
        _geometry = g;
        return Center(
          heightFactor: 1,
          child: RepaintBoundary(
            child: SizedBox(
            width: g.width,
            height: g.height,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final (l, r) = _edges(g);
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Buram latar di belakang bar (dipotong sesuai bentuk bar)
                    // supaya teks yang bergulir di belakangnya tidak tampak
                    // tajam seperti hantu.
                    Positioned.fill(
                      child: ClipPath(
                        clipper: _BarClipper(g),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _NavPainter(
                          geometry: g,
                          left: l,
                          right: r,
                          glass: _glass(context),
                          pill: widget.pillColor ?? AppColors.glassPill,
                        ),
                      ),
                    ),
                    for (var i = 0; i < widget.items.length; i++)
                      _buildItem(g, i),
                  ],
                );
              },
            ),
          ),
          ),
        );
      },
    );
  }

  /// Warna kaca bar. Saat pengguna meminta kontras tinggi, bar dibuat pekat.
  Color _glass(BuildContext context) {
    final base = widget.glassColor ?? AppColors.glass;
    if (MediaQuery.maybeHighContrastOf(context) ?? false) {
      return base.withValues(alpha: 1);
    }
    return base;
  }

  Widget _buildItem(CurvedNavGeometry g, int i) {
    final item = widget.items[i];
    final s = g.slotCenter(i);
    final (x, y) = g.centerlinePoint(s);
    final selected = i == _shown;
    final idle = widget.idleColor ?? AppColors.glassIcon;
    final active = widget.activeColor ?? AppColors.glassIconOn;
    return Positioned(
      left: x - g.slot / 2,
      top: y - g.thickness / 2,
      width: g.slot,
      height: g.thickness,
      child: Tooltip(
        message: item.label,
        child: Semantics(
          button: true,
          selected: selected,
          label: item.label,
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _select(i),
            child: Transform.rotate(
              angle: g.tangentAngle(s),
              child: Center(
                child: TweenAnimationBuilder<Color?>(
                  tween: ColorTween(end: selected ? active : idle),
                  duration: motionDuration(context, _duration),
                  builder: (context, color, _) =>
                      _content(context, item, color, selected),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    CurvedNavItem item,
    Color? color,
    bool selected,
  ) {
    if (item.icon != null || item.glyph != null) {
      final Widget mark = item.icon != null
          ? Icon(
              selected ? (item.selectedIcon ?? item.icon) : item.icon,
              size: widget.iconSize,
              color: color,
            )
          : MediaQuery.withClampedTextScaling(
              // Huruf di bar dibatasi skalanya (seperti ikon) supaya tidak
              // mendorong label keluar dari pil saat teks 200%.
              maxScaleFactor: 1.2,
              child: Text(
                item.glyph!,
                style: TextStyle(
                  fontFamily: AppFonts.kana,
                  fontSize: widget.iconSize - 2,
                  height: 1,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            );
      if (!widget.showLabels) return mark;
      // Label dibatasi skala 1,2 supaya tidak keluar dari pil; teks lengkap
      // tetap tersedia lewat Semantics dan tooltip.
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          mark,
          const SizedBox(height: 1),
          MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.2,
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontSize: 11,
                height: 1,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? color : AppColors.glassLabel,
              ),
            ),
          ),
        ],
      );
    }
    return Text(
      item.text!,
      maxLines: 1,
      overflow: TextOverflow.visible,
      style: TextStyle(
        fontSize: 13,
        height: 1,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }
}

class _NavPainter extends CustomPainter {
  _NavPainter({
    required this.geometry,
    required this.left,
    required this.right,
    required this.glass,
    required this.pill,
  });

  final CurvedNavGeometry geometry;
  final double left;
  final double right;
  final Color glass;
  final Color pill;

  @override
  void paint(Canvas canvas, Size size) {
    final g = geometry;
    final center = Offset(size.width / 2, g.thickness / 2 + g.radius);
    final rect = Rect.fromCircle(center: center, radius: g.radius);

    // Bar: busur tebal dengan ujung bulat.
    final bar = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = g.thickness
      ..color = glass;
    canvas.drawArc(rect, -math.pi / 2 - g.phi, 2 * g.phi, false, bar);

    // Pil aktif: potongan busur yang tepi kiri/kanannya dianimasikan.
    final half = g.pillThickness / 2;
    final start = -math.pi / 2 + (left + half) / g.radius;
    final end = -math.pi / 2 + (right - half) / g.radius;
    final active = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = g.pillThickness
      ..color = pill;
    canvas.drawArc(rect, start, end - start, false, active);
  }

  @override
  bool shouldRepaint(_NavPainter old) =>
      old.left != left ||
      old.right != right ||
      old.glass != glass ||
      old.pill != pill ||
      old.geometry.width != geometry.width ||
      old.geometry.thickness != geometry.thickness ||
      old.geometry.radius != geometry.radius;
}

/// Bentuk bar (busur tebal berujung bulat) sebagai [Path], dipakai untuk
/// memotong buram latar. Ukurannya sama dengan yang digambar [_NavPainter].
class _BarClipper extends CustomClipper<Path> {
  _BarClipper(this.g);

  final CurvedNavGeometry g;

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, g.thickness / 2 + g.radius);
    final t = g.thickness;
    final a0 = -math.pi / 2 - g.phi;
    final sweep = 2 * g.phi;
    final a1 = a0 + sweep;
    Offset onArc(double a) =>
        center + Offset(math.cos(a), math.sin(a)) * g.radius;
    return Path()
      ..arcTo(
        Rect.fromCircle(center: center, radius: g.radius + t / 2),
        a0,
        sweep,
        true,
      )
      // Ujung kanan bulat: dari tepi luar ke tepi dalam.
      ..arcTo(Rect.fromCircle(center: onArc(a1), radius: t / 2), a1, math.pi, false)
      ..arcTo(
        Rect.fromCircle(center: center, radius: g.radius - t / 2),
        a1,
        -sweep,
        false,
      )
      // Ujung kiri bulat: dari tepi dalam kembali ke tepi luar.
      ..arcTo(
        Rect.fromCircle(center: onArc(a0), radius: t / 2),
        a0 + math.pi,
        math.pi,
        false,
      )
      ..close();
  }

  @override
  bool shouldReclip(_BarClipper old) =>
      old.g.width != g.width ||
      old.g.thickness != g.thickness ||
      old.g.radius != g.radius ||
      old.g.phi != g.phi;
}
