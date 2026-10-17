import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Satu kata untuk latihan baca.
class Word {
  const Word(
    this.text,
    this.reading, {
    this.meaning = '',
    this.hasAudio = false,
  });

  /// Tulisan kana, mis. 「あめ」.
  final String text;

  /// Cara baca dalam romaji, mis. "ame".
  final String reading;

  /// Arti dalam Bahasa Indonesia. Kosong untuk kata dari kamus (tidak ada arti).
  final String meaning;

  /// true kalau ada rekaman kata utuh di assets/audio/words/<reading>.mp3.
  final bool hasAudio;
}

/// Daftar kata dimuat dari `assets/data/words.tsv` (sekitar 9 ribu kata).
///
/// Kolom dipisah TAB: kata, cara baca, ada audio (0/1), arti (opsional).
/// Isinya: kata kurasi (ber-arti) + kata umum dari kamus JMdict
/// (EDRDG, CC BY-SA 4.0) yang tersusun dari huruf kana yang ada di app.
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
      ));
    }
    return result;
  }

  /// Hanya untuk pengujian.
  @visibleForTesting
  void debugSet(List<Word> words) => _words = words;
}
