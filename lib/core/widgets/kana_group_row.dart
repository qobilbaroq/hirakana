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

/// Satu baris huruf yang mengisi seluruh lebar, kolom sama lebar.
/// [tile] membuat satu huruf; tinggi diatur oleh [tile] sendiri.
Widget kanaGroupRow(
  List<Kana> group,
  Widget Function(Kana) tile, {
  double gap = 8,
}) {
  final slots = _slots(group);
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < slots.length; i++) ...[
        if (i > 0) SizedBox(width: gap),
        Expanded(
          child: slots[i] == null
              ? const SizedBox.shrink()
              : tile(slots[i]!),
        ),
      ],
    ],
  );
}
