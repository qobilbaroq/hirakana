import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../data/seed/stroke_data.dart';

class TracingController extends ChangeNotifier {
  final List<List<Offset>> strokes = [];

  bool get isEmpty => strokes.isEmpty;

  void start(Offset p) {
    strokes.add([p]);
    notifyListeners();
  }

  void extend(Offset p) {
    if (strokes.isEmpty) return;
    strokes.last.add(p);
    notifyListeners();
  }

  void undo() {
    if (strokes.isEmpty) return;
    strokes.removeLast();
    notifyListeners();
  }

  void clear() {
    if (strokes.isEmpty) return;
    strokes.clear();
    notifyListeners();
  }
}

/// Area menulis dengan jari. Panduan goresan (bernomor) tampil samar;
/// setelah "Check", panduan ditebalkan di atas goresan untuk dibandingkan.
/// [replay] (0..1) menganimasikan urutan goresan yang benar.
class KanaTracingCanvas extends StatelessWidget {
  const KanaTracingCanvas({
    super.key,
    required this.character,
    required this.strokes,
    required this.controller,
    required this.comparing,
    this.replay,
  });

  final String character;
  final List<Path>? strokes;
  final TracingController controller;
  final bool comparing;
  final Animation<double>? replay;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Writing area for $character. Draw with your finger.',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          color: AppColors.white,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: comparing
                      ? null
                      : (d) => controller.start(d.localPosition),
                  onPanUpdate: comparing
                      ? null
                      : (d) => controller.extend(d.localPosition),
                  child: CustomPaint(
                    painter: _TracingPainter(
                      character: character,
                      strokes: strokes,
                      controller: controller,
                      comparing: comparing,
                      replay: replay,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: AppSpacing.md,
                child: IgnorePointer(
                  child: Text(
                    'Follow the stroke guide',
                    textAlign: TextAlign.center,
                    style: AppText.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TracingPainter extends CustomPainter {
  _TracingPainter({
    required this.character,
    required this.strokes,
    required this.controller,
    required this.comparing,
    required this.replay,
  }) : super(repaint: Listenable.merge([controller, replay]));

  final String character;
  final List<Path>? strokes;
  final TracingController controller;
  final bool comparing;
  final Animation<double>? replay;

  @override
  void paint(Canvas canvas, Size size) {
    final guides = strokes;
    if (guides != null) {
      _paintStrokeGuide(canvas, size, guides);
    } else {
      _paintFontGuide(canvas, size);
    }

    // Goresan pengguna.
    final paint = Paint()
      ..color = comparing ? AppColors.ink.withValues(alpha: 0.7) : AppColors.ink
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final dot = Paint()..color = paint.color;

    for (final stroke in controller.strokes) {
      if (stroke.length == 1) {
        canvas.drawCircle(stroke.first, 5, dot);
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final p in stroke.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  void _paintStrokeGuide(Canvas canvas, Size size, List<Path> guides) {
    final side = min(size.width, size.height) * 0.9;
    final k = side / StrokeRepository.box;
    final dx = (size.width - side) / 2;
    final dy = (size.height - side) / 2;

    final guidePaint = Paint()
      ..color = comparing
          ? AppColors.clay.withValues(alpha: 0.75)
          : AppColors.guide
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 6.5;

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(k);
    for (final p in guides) {
      canvas.drawPath(p, guidePaint);
    }

    // Animasi urutan goresan (Replay).
    final r = replay;
    if (r != null && r.value > 0) {
      final replayPaint = Paint()
        ..color = AppColors.sage
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 6.5;
      final t = r.value * guides.length;
      for (var i = 0; i < guides.length; i++) {
        final frac = (t - i).clamp(0.0, 1.0);
        if (frac <= 0) break;
        for (final m in guides[i].computeMetrics()) {
          canvas.drawPath(m.extractPath(0, m.length * frac), replayPaint);
        }
      }
    }
    canvas.restore();

    // Nomor urutan goresan (hanya saat belajar, bukan saat membandingkan).
    if (!comparing) {
      for (var i = 0; i < guides.length; i++) {
        final metrics = guides[i].computeMetrics().toList();
        if (metrics.isEmpty) continue;
        final start = metrics.first.getTangentForOffset(0)?.position;
        if (start == null) continue;
        final at = Offset(dx + start.dx * k, dy + start.dy * k);
        canvas.drawCircle(at, 9, Paint()..color = AppColors.white);
        final tp = TextPainter(
          text: TextSpan(
            text: '${i + 1}',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.muted),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
      }
    }
  }

  // Cadangan kalau data goresan huruf tidak tersedia.
  void _paintFontGuide(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: TextSpan(
        text: character,
        style: TextStyle(
          fontFamily: 'Noto Sans JP',
          fontSize: min(size.width / character.length, size.shortestSide) * 0.8,
          color: comparing
              ? AppColors.clay.withValues(alpha: 0.75)
              : AppColors.guide,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _TracingPainter old) =>
      old.character != character ||
      old.comparing != comparing ||
      old.strokes != strokes ||
      old.replay != replay;
}
