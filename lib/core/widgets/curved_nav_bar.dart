import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_colors.dart';
import 'curved_nav_geometry.dart';

class CurvedNavItem {
  const CurvedNavItem({required this.label, this.icon, this.glyph})
    : assert(icon != null || glyph != null);

  final IconData? icon;

  /// Huruf kana untuk tab Kana; null untuk tab berbasis ikon.
  final String? glyph;

  /// Hanya untuk aksesibilitas (pembaca layar) dan tooltip.
  final String label;
}

/// Navigasi bawah berbentuk busur melayang. Pil aktif memanjang ke tab yang
/// dipilih, lalu kembali ke ukuran pil biasa (lihat [CurvedNavGeometry.stretch]).
class CurvedNavBar extends StatefulWidget {
  const CurvedNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<CurvedNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  State<CurvedNavBar> createState() => _CurvedNavBarState();
}

class _CurvedNavBarState extends State<CurvedNavBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
  );

  CurvedNavGeometry? _geometry;
  double _l0 = 0, _r0 = 0, _l1 = 0, _r1 = 0;

  @override
  void didUpdateWidget(CurvedNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final g = _geometry;
    if (g == null || oldWidget.currentIndex == widget.currentIndex) return;
    // Mulai dari posisi pil saat ini (juga kalau pil masih bergerak).
    final (l, r) = _edges(g);
    final (nl, nr) = g.pillEdges(widget.currentIndex);
    _l0 = l;
    _r0 = r;
    _l1 = nl;
    _r1 = nr;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  (double, double) _edges(CurvedNavGeometry g) {
    if (!_controller.isAnimating) return g.pillEdges(widget.currentIndex);
    return CurvedNavGeometry.stretch(
      l0: _l0,
      r0: _r0,
      l1: _l1,
      r1: _r1,
      t: _controller.value,
    );
  }

  void _select(int i) {
    if (i == widget.currentIndex) return;
    HapticFeedback.selectionClick();
    widget.onTap(i);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final g = CurvedNavGeometry(
          maxWidth: constraints.maxWidth,
          count: widget.items.length,
        );
        _geometry = g;
        return Center(
          heightFactor: 1,
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
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _NavPainter(
                          geometry: g,
                          left: l,
                          right: r,
                          glass: AppColors.glass,
                          pill: AppColors.glassPill,
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
        );
      },
    );
  }

  Widget _buildItem(CurvedNavGeometry g, int i) {
    final item = widget.items[i];
    final s = g.slotCenter(i);
    final (x, y) = g.centerlinePoint(s);
    final selected = i == widget.currentIndex;
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
                  tween: ColorTween(
                    end: selected ? AppColors.glassIconOn : AppColors.glassIcon,
                  ),
                  duration: const Duration(milliseconds: 260),
                  builder: (context, color, _) => item.glyph != null
                      ? Text(
                          item.glyph!,
                          style: TextStyle(
                            fontFamily: 'Noto Sans JP',
                            fontSize: 21,
                            height: 1,
                            fontWeight: FontWeight.w500,
                            color: color,
                          ),
                        )
                      : Icon(item.icon, size: 25, color: color),
                ),
              ),
            ),
          ),
        ),
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
