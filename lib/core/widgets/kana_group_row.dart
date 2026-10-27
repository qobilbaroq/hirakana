import 'package:flutter/material.dart';

import '../../data/models/kana.dart';

/// Mengelompokkan huruf menurut barisnya (a, ka, sa, ...), urutan dataset.
List<List<Kana>> groupKana(List<Kana> list) {
  final groups = <String, List<Kana>>{};
  for (final k in list) {
    groups.putIfAbsent(k.group, () => []).add(k);
  }
  return groups.values.toList();
}

/// Slot satu baris tabel gojuon: baris penuh selebar layar. Baris ya/yu/yo
/// dan wa/wo diberi celah di tempat yang sama seperti tabel gojuon asli,
/// sehingga kolomnya tetap sejajar dengan baris lain.
List<Kana?> _slots(List<Kana> g) {
  switch (g.first.group) {
    case 'y':
      return [g[0], null, g[1], null, g[2]];
    case 'w':
      return [g[0], null, null, null, g[1]];
    case 'n-final':
      return [g[0], null, null, null, null];
    default:
      // Baris kontraksi (きゃ きゅ きょ) tetap memakai lima kolom supaya
      // sejajar dengan baris gojuon lainnya.
      if (g.length == 3) return [g[0], null, g[1], null, g[2]];
      return g; // 5 huruf (vowels, ka, ...)
  }
}

/// Jumlah kolom grid kana yang masih muat di [width] (lebar area grid) pada
/// skala teks [textScale]. Satu sel perlu sekitar `42 * skala` untuk dua huruf
/// kontraksi (きゃ) ditambah sedikit ruang. 5 kolom dipertahankan selama muat;
/// saat teks membesar (mis. 200%) kolom dikurangi sampai minimal 3, bukan
/// mengecilkan huruf.
int kanaGridColumns({
  required double width,
  required double textScale,
  double gap = 8,
}) {
  final cellNeed = 42 * textScale + 4;
  final fit = ((width + gap) / (cellNeed + gap)).floor();
  return fit.clamp(3, 5).toInt();
}

/// Satu baris huruf yang mengisi seluruh lebar, kolom sama lebar.
/// [tile] membuat satu huruf; tinggi diatur oleh [tile] sendiri.
///
/// Dengan [columns] = 5 (bawaan) baris mengikuti tabel gojuon, lengkap dengan
/// celah. Kalau [columns] lebih kecil (teks besar), huruf di baris itu dibagi
/// ke beberapa baris pendek tanpa celah supaya tiap sel tetap lebar.
Widget kanaGroupRow(
  List<Kana> group,
  Widget Function(Kana) tile, {
  double gap = 8,
  int columns = 5,
}) {
  if (columns >= 5) {
    final slots = _slots(group);
    return _slotRow(slots, tile, gap);
  }
  final letters = group.toList();
  return Column(
    children: [
      for (var start = 0; start < letters.length; start += columns) ...[
        if (start > 0) SizedBox(height: gap),
        _slotRow(
          [
            for (var i = 0; i < columns; i++)
              start + i < letters.length ? letters[start + i] : null,
          ],
          tile,
          gap,
        ),
      ],
    ],
  );
}

Widget _slotRow(List<Kana?> slots, Widget Function(Kana) tile, double gap) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < slots.length; i++) ...[
        if (i > 0) SizedBox(width: gap),
        Expanded(
          child: slots[i] == null ? const SizedBox.shrink() : tile(slots[i]!),
        ),
      ],
    ],
  );
}
