import '../models/kana.dart';
import '../seed/kana_data.dart';
import '../seed/word_data.dart';
import 'kana_repository.dart';

/// Kata yang bisa dibaca dari huruf pilihan pengguna.
class WordRepository {
  WordRepository._();
  static final instance = WordRepository._();

  /// Minimal kata supaya latihan baca bisa jalan.
  static const minWords = 3;
  static const sessionSize = 10;

  static final Map<String, Kana> _byChar = {
    for (final k in allKana) k.character: k,
  };

  static const _small = 'ゃゅょャュョ';
  static const _free = 'っッー '; // tidak perlu dipilih dulu

  /// Memecah kata jadi huruf-huruf kana (きゃ dihitung satu huruf).
  /// null kalau ada karakter yang tidak dikenal (misalnya kanji).
  static List<Kana>? kanaOf(String text) {
    final result = <Kana>[];
    var i = 0;
    while (i < text.length) {
      final ch = text[i];
      if (_free.contains(ch)) {
        i++;
        continue;
      }
      if (i + 1 < text.length && _small.contains(text[i + 1])) {
        final combo = _byChar[ch + text[i + 1]];
        if (combo == null) return null;
        result.add(combo);
        i += 2;
        continue;
      }
      final k = _byChar[ch];
      if (k == null) return null;
      result.add(k);
      i++;
    }
    return result;
  }

  /// Kata yang SEMUA hurufnya ada di huruf aktif. [type]: hiragana | katakana | mixed.
  Future<List<Word>> available(String type) async {
    final active = await KanaRepository.instance.activeIds();
    final result = <Word>[];
    for (final w in allWords) {
      final tokens = kanaOf(w.text);
      if (tokens == null || tokens.isEmpty) continue;
      if (type != 'mixed' && tokens.first.type != type) continue;
      if (tokens.every((k) => active.contains(k.id))) result.add(w);
    }
    return result;
  }
}
