import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Satu kata untuk latihan baca.
class Word {
  const Word(
    this.text,
    this.reading, {
    this.meaning = '',
    this.hasAudio = false,
    this.level = '',
    this.category = '',
  });

  /// Tulisan kana, mis. 「あめ」.
  final String text;

  /// Cara baca dalam romaji, mis. "ame".
  final String reading;

  /// Arti dalam Bahasa Indonesia. Kosong untuk kata dari kamus (tidak ada arti).
  final String meaning;

  /// true kalau ada rekaman kata utuh di assets/audio/words/<reading>.mp3.
  final bool hasAudio;

  /// Kelompok tingkat: `n5n4` atau `n3`. Kosong untuk kata yang tidak punya kelompok.
  final String level;

  /// Kategori kosakata (Indonesia), mis. "Makanan". Kosong kalau tidak ada.
  final String category;
}

/// Kelompok tingkat kosakata untuk filter latihan: (id di words.tsv, label).
const vocabLevels = <(String, String)>[
  ('n5n4', 'N5–N4'),
  ('n3', 'N3'),
];

/// Label tampilan untuk id tingkat (mis. `n5n4` -> `N5–N4`).
String vocabLevelLabel(String id) {
  for (final l in vocabLevels) {
    if (l.$1 == id) return l.$2;
  }
  return id;
}

/// Daftar kata dimuat dari `assets/data/words.tsv` (1.272 kata kurasi).
///
/// Kolom dipisah TAB: kata, cara baca, ada audio (0/1), arti,
/// tingkat (opsional: n5n4 | n3), kategori (opsional).
/// Seluruh kata ditulis tangan untuk app ini (bukan dari kamus pihak
/// ketiga), jadi setiap kata punya arti Bahasa Indonesia dan rekaman utuh.
class WordBank {
  WordBank._();
  static final instance = WordBank._();

  List<Word>? _words;

  List<Word> get words => _words ?? const [];
  bool get isLoaded => _words != null;

  Future<List<Word>> load({AssetBundle? bundle}) async {
    final cached = _words;
    if (cached != null) return cached;
    final text =
        await (bundle ?? rootBundle).loadString('assets/data/words.tsv');
    return _words = parse(text);
  }

  /// Dipisah supaya bisa diuji tanpa asset bundle.
  static List<Word> parse(String tsv) {
    final result = <Word>[];
    for (final line in tsv.split('\n')) {
      if (line.trim().isEmpty) continue;
      final c = line.split('\t');
      if (c.length < 3) continue;
      result.add(Word(
        c[0],
        c[1],
        hasAudio: c[2].trim() == '1',
        meaning: c.length > 3 ? c[3].trim() : '',
        level: c.length > 4 ? c[4].trim() : '',
        category: c.length > 5 ? c[5].trim() : '',
      ));
    }
    return result;
  }

  /// Hanya untuk pengujian.
  @visibleForTesting
  void debugSet(List<Word> words) => _words = words;
}
