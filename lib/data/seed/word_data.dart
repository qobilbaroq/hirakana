import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Satu kata untuk latihan baca.
class Word {
  const Word(
    this.text,
    this.reading, {
    this.meaning = '',
    this.hasAudio = false,
    this.meaningEn = '',
    this.level = '',
    this.kanji = '',
  });

  /// Tulisan kana, mis. 「あめ」.
  final String text;

  /// Cara baca dalam romaji, mis. "ame".
  final String reading;

  /// Arti dalam Bahasa Indonesia. Kosong kalau belum diterjemahkan.
  final String meaning;

  /// true kalau ada rekaman kata utuh di `assets/audio/words/reading.mp3`.
  final bool hasAudio;

  /// Arti dalam bahasa Inggris (dari daftar JLPT).
  final String meaningEn;

  /// Tingkat JLPT: 'N5', 'N4', 'N3', atau kosong untuk kata umum lainnya.
  static const levels = ['N5', 'N4', 'N3'];
  static const levelRank = {'N5': 0, 'N4': 1, 'N3': 2};

  /// Kosong berarti bukan kosakata JLPT (kata umum dari kamus).
  final String level;

  /// Penulisan kanji asli, ditampilkan kecil setelah menjawab.
  final String kanji;

  /// true kalau kata ini punya arti (Indonesia atau Inggris).
  bool get hasAnyMeaning => meaning.isNotEmpty || meaningEn.isNotEmpty;

  /// Arti untuk ditampilkan: Indonesia dulu, lalu Inggris.
  String get displayMeaning => meaning.isNotEmpty ? meaning : meaningEn;

  /// Teks yang dikirim ke TTS: kana saja, supaya dibaca sebagai kata.
  String get spokenText => text;
}

/// Daftar kata dimuat dari `assets/data/words.tsv` (sekitar 10 ribu kata).
///
/// Format TSV, kolom dipisah TAB:
///   kata, cara baca, ada-audio (0/1), arti Indonesia, arti Inggris,
///   level (N5|N4|N3|kosong), kanji (opsional)
///
/// Baris lama 4 kolom (kata, cara baca, audio, arti) tetap bisa dibaca: kolom
/// yang tidak ada dianggap kosong.
///
/// Isinya: kosakata JLPT N5/N4/N3 + kata umum dari kamus JMdict
/// (EDRDG, CC BY-SA 4.0). Lihat DOKUMENTASI.md bagian 9 untuk sumber.
class WordBank {
  WordBank._();
  static final instance = WordBank._();

  List<Word>? _words;

  /// Sedang memuat? Dipakai supaya dua panggilan bersamaan tidak mengurai
  /// berkas 10 ribu baris dua kali.
  Future<List<Word>>? _loading;

  List<Word> get words => _words ?? const [];
  bool get isLoaded => _words != null;

  Future<List<Word>> load({AssetBundle? bundle}) async {
    final cached = _words;
    if (cached != null) return cached;
    final inFlight = _loading;
    if (inFlight != null) return inFlight;
    final future = (bundle ?? rootBundle)
        .loadString('assets/data/words.tsv')
        .then((text) => _words = parse(text));
    _loading = future;
    try {
      return await future;
    } finally {
      _loading = null;
    }
  }

  /// Dipisah supaya bisa diuji tanpa asset bundle. Menerima baris 4-7 kolom.
  static List<Word> parse(String tsv) {
    final result = <Word>[];
    for (final line in tsv.split('\n')) {
      if (line.trim().isEmpty) continue;
      final c = line.split('\t');
      if (c.length < 3) continue;
      String at(int i) => i < c.length ? c[i].trim() : '';
      final level = at(5);
      result.add(Word(
        at(0),
        at(1),
        hasAudio: at(2) == '1',
        meaning: at(3),
        meaningEn: at(4),
        level: Word.levels.contains(level) ? level : '',
        kanji: at(6),
      ));
    }
    return result;
  }

  /// Hanya untuk pengujian.
  @visibleForTesting
  void debugSet(List<Word> words) {
    _words = words;
    _loading = null;
  }
}
