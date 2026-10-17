import 'dart:math';

import '../../core/storage/local_database.dart';
import '../models/kana.dart';
import '../seed/kana_data.dart';
import '../seed/word_data.dart';
import 'kana_repository.dart';

/// Satu potongan dari sebuah kata: huruf kana, atau tanda khusus
/// (っ = jeda/penggandaan konsonan, ー = pemanjang vokal).
class WordPiece {
  const WordPiece.kana(Kana this.kana)
      : isSmallTsu = false,
        isLong = false;
  const WordPiece.smallTsu()
      : kana = null,
        isSmallTsu = true,
        isLong = false;
  const WordPiece.longMark()
      : kana = null,
        isSmallTsu = false,
        isLong = true;

  final Kana? kana;
  final bool isSmallTsu;
  final bool isLong;
}

/// Kata yang bisa dibaca dari huruf pilihan pengguna, plus riwayat kata yang
/// sudah pernah muncul supaya latihan tidak itu-itu saja.
class WordRepository {
  WordRepository._();
  static final instance = WordRepository._();

  /// Jumlah huruf aktif minimal per script supaya soal 4 pilihan bisa dibuat.
  static const minLetters = 4;

  static final Map<String, Kana> _byChar = {
    for (final k in allKana) k.character: k,
  };
  static final Map<String, List<WordPiece>?> _parsed = {};

  static const _small = 'ゃゅょャュョ';

  /// Memecah kata jadi potongan (きゃ dihitung satu huruf). null kalau ada
  /// karakter yang tidak dikenal (misalnya kanji).
  static List<WordPiece>? parse(String text) {
    if (_parsed.containsKey(text)) return _parsed[text];
    final result = <WordPiece>[];
    List<WordPiece>? out = result;
    var i = 0;
    while (i < text.length) {
      final ch = text[i];
      if (ch == 'っ' || ch == 'ッ') {
        result.add(const WordPiece.smallTsu());
        i++;
        continue;
      }
      if (ch == 'ー') {
        result.add(const WordPiece.longMark());
        i++;
        continue;
      }
      if (i + 1 < text.length && _small.contains(text[i + 1])) {
        final combo = _byChar[ch + text[i + 1]];
        if (combo == null) {
          out = null;
          break;
        }
        result.add(WordPiece.kana(combo));
        i += 2;
        continue;
      }
      final k = _byChar[ch];
      if (k == null) {
        out = null;
        break;
      }
      result.add(WordPiece.kana(k));
      i++;
    }
    return _parsed[text] = out;
  }

  /// Huruf kana saja (tanpa っ dan ー).
  static List<Kana> kanaOf(String text) =>
      [for (final p in parse(text) ?? const <WordPiece>[]) if (p.kana != null) p.kana!];

  /// Cara baca romaji dari potongan kata (っ menggandakan konsonan, ー
  /// mengulang vokal terakhir).
  static String romajiOf(List<WordPiece> pieces) {
    final sb = StringBuffer();
    var pending = false;
    for (final p in pieces) {
      if (p.isSmallTsu) {
        pending = true;
        continue;
      }
      if (p.isLong) {
        final s = sb.toString();
        for (var i = s.length - 1; i >= 0; i--) {
          if ('aiueo'.contains(s[i])) {
            sb.write(s[i]);
            break;
          }
        }
        continue;
      }
      final r = p.kana!.romaji;
      if (pending) {
        if (r.startsWith('ch')) {
          sb.write('t');
        } else if ('kstpgzdbhfjmrcw'.contains(r[0])) {
          sb.write(r[0]);
        }
        pending = false;
      }
      sb.write(r);
    }
    return sb.toString();
  }

  /// Kata yang SEMUA hurufnya ada di huruf aktif. [type]: hiragana | katakana | mixed.
  Future<List<Word>> available(String type) async {
    final words = await WordBank.instance.load();
    final active = await KanaRepository.instance.activeIds();
    return filterAvailable(words, active, type);
  }

  /// Dipisah dari [available] supaya bisa diuji tanpa database.
  static List<Word> filterAvailable(
      List<Word> words, Set<String> active, String type) {
    final result = <Word>[];
    for (final w in words) {
      final pieces = parse(w.text);
      if (pieces == null) continue;
      final letters = [for (final p in pieces) if (p.kana != null) p.kana!];
      if (letters.isEmpty) continue;
      if (type != 'mixed' && letters.first.type != type) continue;
      if (letters.every((k) => active.contains(k.id))) result.add(w);
    }
    return result;
  }

  /// Bisa jalan kalau ada script dengan minimal [minLetters] huruf aktif.
  Future<bool> canRun(String type) async {
    final ids = await KanaRepository.instance.activeIds();
    bool enough(List<Kana> list) =>
        list.where((k) => ids.contains(k.id)).length >= minLetters;
    return switch (type) {
      'hiragana' => enough(hiraganaList),
      'katakana' => enough(katakanaList),
      _ => enough(hiraganaList) || enough(katakanaList),
    };
  }

  // ------------------------------------------------------------ riwayat

  Future<Map<String, int>> _lastSeen() async {
    final db = await LocalDatabase.instance.database;
    final rows = await db.query('word_history');
    return {for (final r in rows) r['text'] as String: r['last_at'] as int};
  }

  /// Memilih [count] kata dari [pool]: yang belum pernah muncul dulu (acak),
  /// lalu yang paling lama tidak muncul. Hasilnya diacak urutannya.
  Future<List<Word>> pick(List<Word> pool, int count, Random rng) async {
    final last = await _lastSeen();
    final unseen = pool.where((w) => !last.containsKey(w.text)).toList()
      ..shuffle(rng);
    final seen = pool.where((w) => last.containsKey(w.text)).toList()
      ..shuffle(rng)
      ..sort((a, b) => last[a.text]!.compareTo(last[b.text]!));
    return ([...unseen, ...seen].take(count).toList())..shuffle(rng);
  }

  Future<void> markSeen(Iterable<String> texts) async {
    final db = await LocalDatabase.instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final t in texts) {
      final updated = await db.rawUpdate(
        'UPDATE word_history SET seen_count = seen_count + 1, last_at = ? WHERE text = ?',
        [now, t],
      );
      if (updated == 0) {
        await db.insert('word_history',
            {'text': t, 'seen_count': 1, 'last_at': now});
      }
    }
  }
}
