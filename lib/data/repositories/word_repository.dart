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

/// Satu baris riwayat kata: kata + berapa kali muncul, benar, dan salah.
class WordRecord {
  const WordRecord({
    required this.word,
    required this.seenCount,
    required this.correctCount,
    required this.wrongCount,
    required this.lastAt,
  });

  final Word word;
  final int seenCount;
  final int correctCount;
  final int wrongCount;
  final DateTime lastAt;

  /// Sering salah: salah minimal 2 kali dan tidak lebih sedikit dari benarnya.
  bool get isStruggling => wrongCount >= 2 && wrongCount >= correctCount;

  /// Baru dipelajari: baru muncul 1-2 kali.
  bool get isNew => seenCount <= 2;

  /// Sudah hafal: benar minimal 3 kali dan benarnya jauh lebih banyak.
  bool get isMastered => correctCount >= 3 && correctCount >= wrongCount * 3;
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
  Future<List<Word>> available(String type, {String? level}) async {
    final words = await WordBank.instance.load();
    final active = await KanaRepository.instance.activeIds();
    return filterAvailable(words, active, type, level: level);
  }

  /// Dipisah dari [available] supaya bisa diuji tanpa database.
  /// [level] (n5n4 | n3) membatasi ke kosakata kelompok itu; null = semua kata.
  static List<Word> filterAvailable(
      List<Word> words, Set<String> active, String type,
      {String? level}) {
    final result = <Word>[];
    for (final w in words) {
      if (level != null && w.level != level) continue;
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

  /// Mencatat satu jawaban untuk [text]: menambah jumlah muncul dan jumlah
  /// benar atau salah. Dipakai latihan baca dan tebak arti.
  Future<void> recordResult(String text, {required bool correct}) async {
    final db = await LocalDatabase.instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final column = correct ? 'correct_count' : 'wrong_count';
    final updated = await db.rawUpdate(
      'UPDATE word_history SET seen_count = seen_count + 1, '
      '$column = $column + 1, last_at = ? WHERE text = ?',
      [now, text],
    );
    if (updated == 0) {
      await db.insert('word_history', {
        'text': text,
        'seen_count': 1,
        'correct_count': correct ? 1 : 0,
        'wrong_count': correct ? 0 : 1,
        'last_at': now,
      });
    }
  }

  /// Semua kata yang pernah muncul, yang terbaru dulu. Kata yang sudah tidak
  /// ada di daftar kata (misalnya daftar kata diperbarui) dilewati.
  Future<List<WordRecord>> history() async {
    final words = await WordBank.instance.load();
    final byText = {for (final w in words) w.text: w};
    final db = await LocalDatabase.instance.database;
    final rows = await db.query('word_history', orderBy: 'last_at DESC');
    return [
      for (final r in rows)
        if (byText[r['text'] as String] != null)
          WordRecord(
            word: byText[r['text'] as String]!,
            seenCount: r['seen_count'] as int,
            correctCount: r['correct_count'] as int,
            wrongCount: r['wrong_count'] as int,
            lastAt: DateTime.fromMillisecondsSinceEpoch(r['last_at'] as int),
          ),
    ];
  }

  /// Kata dari daftar kata untuk teks-teks [texts] (urutan mengikuti [texts]),
  /// dipakai untuk mengulang kata dari riwayat. Kata yang tidak bisa dibaca
  /// app dilewati.
  Future<List<Word>> wordsFor(Iterable<String> texts) async {
    final words = await WordBank.instance.load();
    final byText = {for (final w in words) w.text: w};
    return [
      for (final t in texts)
        if (byText[t] != null && parse(t) != null) byText[t]!,
    ];
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
