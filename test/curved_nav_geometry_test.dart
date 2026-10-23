import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:kana_quest/core/widgets/curved_nav_geometry.dart';

void main() {
  group('CurvedNavGeometry', () {
    final g = CurvedNavGeometry(maxWidth: 328, count: 4);

    test('muat di lebar yang tersedia dan tap target >= 48', () {
      for (final w in [288.0, 328.0, 400.0]) {
        for (final n in [3, 4, 5]) {
          final geo = CurvedNavGeometry(maxWidth: w, count: n);
          expect(geo.width, lessThanOrEqualTo(w + 1e-9));
          expect(geo.thickness, greaterThanOrEqualTo(48));
        }
      }
      expect(g.slot, greaterThanOrEqualTo(48));
    });

    test('lengkungan simetris: tengah lebih tinggi daripada ujung', () {
      for (var i = 0; i < 4; i++) {
        final a = g.centerlinePoint(g.slotCenter(i));
        final b = g.centerlinePoint(g.slotCenter(3 - i));
        expect(a.$1 + b.$1, closeTo(g.width, 1e-6));
        expect(a.$2, closeTo(b.$2, 1e-6));
      }
      expect(
        g.centerlinePoint(0).$2,
        lessThan(g.centerlinePoint(g.slotCenter(0)).$2),
      );
    });

    test('sudut putar item: kiri negatif, kanan positif', () {
      expect(g.tangentAngle(g.slotCenter(0)), lessThan(0));
      expect(g.tangentAngle(g.slotCenter(3)), greaterThan(0));
      expect(g.tangentAngle(0), 0);
    });

    test('pil memanjang ke tujuan lalu kembali ke ukuran pil', () {
      final (l0, r0) = g.pillEdges(0);
      final (l1, r1) = g.pillEdges(3);
      var (l, r) = CurvedNavGeometry.stretch(
        l0: l0,
        r0: r0,
        l1: l1,
        r1: r1,
        t: 0,
      );
      expect(l, closeTo(l0, 1e-9));
      expect(r, closeTo(r0, 1e-9));
      (l, r) = CurvedNavGeometry.stretch(l0: l0, r0: r0, l1: l1, r1: r1, t: 1);
      expect(l, closeTo(l1, 1e-9));
      expect(r, closeTo(r1, 1e-9));

      var longest = 0.0;
      for (var k = 0; k <= 40; k++) {
        final (a, b) = CurvedNavGeometry.stretch(
          l0: l0,
          r0: r0,
          l1: l1,
          r1: r1,
          t: k / 40,
        );
        expect(b - a, greaterThanOrEqualTo(g.pillLength - 1e-6));
        longest = math.max(longest, b - a);
      }
      expect(longest, greaterThan(g.pillLength * 1.8));
    });

    test('memanjang juga ke arah kiri', () {
      final (l0, r0) = g.pillEdges(3);
      final (l1, r1) = g.pillEdges(0);
      final (a, b) = CurvedNavGeometry.stretch(
        l0: l0,
        r0: r0,
        l1: l1,
        r1: r1,
        t: 0.3,
      );
      expect(b - a, greaterThan(g.pillLength));
    });
  });
}
