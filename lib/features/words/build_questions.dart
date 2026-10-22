import 'dart:math';

import '../../data/models/kana.dart';
import '../../data/repositories/kana_repository.dart';
import '../../data/repositories/word_repository.dart';
import '../../data/seed/kana_data.dart';
import '../../data/seed/word_data.dart';

/// Jumlah kata maksimal dalam satu sesi Susun Kata. Menyusun lebih lama
/// daripada memilih jawaban, jadi sesinya lebih pendek dari Reading.
const buildSessionSize = 15;

/// Arah latihan Susun Kata.
enum BuildDirection {
  /// Tampil kosakata Jepang, user menyusun romajinya.
  toRomaji,

  /// Tampil romaji, user menyusun kananya.
  toKana,
}

/// Satu potongan yang bisa dipilih. [id] unik dalam satu soal, supaya dua
/// potongan yang tulisannya sama (mis. dua `sa`) tetap bisa dibedakan.
class BuildTile {
  const BuildTile(this.id, this.label);

  final int id;
  final String label;
}

/// Satu soal Susun Kata: lihat arti + teks soal, susun jawabannya dari
/// potongan yang tersedia (potongan benar + pengecoh).
class BuildQuestion {
  const BuildQuestion({
    required this.direction,
    required this.word,
    required this.prompt,
    required this.answerTiles,
    required this.tiles,
  });

  final BuildDirection direction;
  final Word word;

  /// Teks soal yang ditampilkan besar: kata Jepang (toRomaji) atau romaji (toKana).
  final String prompt;

  /// Potongan jawaban yang benar, berurutan.
  final List<String> answerTiles;

  /// Semua potongan yang tersedia (jawaban + pengecoh), sudah diacak.
  final List<BuildTile> tiles;

  int get slotCount => answerTiles.length;

  /// Jawaban lengkap yang benar (potongan digabung).
  String get answer => answerTiles.join();

  /// Benar kalau gabungan potongan yang dipilih sama dengan jawaban.
  bool isCorrect(List<String> picked) => picked.join() == answer;
}

/// Memecah kata jadi potongan romaji. Satu potongan = satu suku kata.
/// っ digabung dengan suku kata sesudahnya (きって -> ki + tte), dan ー
/// menjadi potongan vokal (ラーメン -> ra + a + me + n). Gabungan semua
/// potongan sama persis dengan [WordRepository.romajiOf].
List<String> romajiTilesOf(List<WordPiece> pieces) {
  final out = <String>[];
  var pending = false;
  for (final p in pieces) {
    if (p.isSmallTsu) {
      pending = true;
      continue;
    }
    if (p.isLong) {
      final s = out.join();
      for (var i = s.length - 1; i >= 0; i--) {
        if ('aiueo'.contains(s[i])) {
          out.add(s[i]);
          break;
        }
      }
      continue;
    }
    var r = p.kana!.romaji;
    if (pending) {
      if (r.startsWith('ch')) {
        r = 't$r';
      } else if ('kstpgzdbhfjmrcw'.contains(r[0])) {
        r = '${r[0]}$r';
      }
      pending = false;
    }
    out.add(r);
  }
  return out;
}

/// Ejaan alternatif yang dipakai daftar kata untuk satu potongan romaji.
/// - っ + ち ditulis "cchi" (bukan "tchi") di sebagian kata.
/// - は sebagai partikel dibaca "wa" (こんにちは -> konnichiwa).
/// - づ dan ぢ dibaca "zu" dan "ji".
List<String> _spellings(String tile) => [
      tile,
      if (tile.startsWith('tch')) 'c${tile.substring(1)}',
      if (tile == 'ha') 'wa',
      if (tile == 'du') 'zu',
      if (tile == 'di') 'ji',
    ];

/// Potongan romaji yang gabungannya SAMA dengan [reading] di daftar kata,
/// memakai ejaan alternatif bila perlu. null kalau tetap tidak bisa dicocokkan
/// (berarti ada kesalahan data di daftar kata).
List<String>? alignedRomajiTiles(List<WordPiece> pieces, String reading) {
  final base = romajiTilesOf(pieces);
  if (base.join() == reading) return base;
  final out = <String>[];
  var pos = 0;
  for (final t in base) {
    String? hit;
    for (final c in _spellings(t)) {
      if (reading.startsWith(c, pos)) {
        hit = c;
        break;
      }
    }
    if (hit == null) return null;
    out.add(hit);
    pos += hit.length;
  }
  return pos == reading.length ? out : null;
}

/// Memecah kata jadi potongan kana. っ/ッ dan ー tetap potongan sendiri;
/// きゃ dan sejenisnya tetap satu potongan. [script] menentukan っ atau ッ.
List<String> kanaTilesOf(List<WordPiece> pieces, String script) => [
      for (final p in pieces)
        if (p.isSmallTsu)
          (script == 'katakana' ? 'ッ' : 'っ')
        else if (p.isLong)
          'ー'
        else
          p.kana!.character,
    ];

/// Kata ini bisa dibuat jadi soal Susun Kata? Semua karakternya dikenal dan
/// potongan yang digabung sama persis dengan tulisan dan romaji di daftar kata.
bool isBuildable(Word w) {
  final pieces = WordRepository.parse(w.text);
  if (pieces == null) return false;
  final letters = [for (final p in pieces) if (p.kana != null) p.kana!];
  if (letters.isEmpty) return false;
  return alignedRomajiTiles(pieces, w.reading) != null &&
      kanaTilesOf(pieces, letters.first.type).join() == w.text;
}

/// Memilih label pengecoh untuk satu soal.
///
/// Aturan: tidak pernah sama dengan label jawaban, dan tidak pernah punya
/// romaji yang sama dengan salah satu huruf jawaban (mis. ぢ untuk じ), supaya
/// tidak ada jawaban lain yang ikut benar. Urutan prioritas: huruf yang sering
/// tertukar (hanya untuk tile kana), lalu huruf yang bunyinya mirip, lalu
/// huruf aktif lain. Kalau huruf aktif kurang dari [minCount], dilengkapi dari
/// seluruh huruf script itu.
List<String> _distractorLabels({
  required List<Kana> answerLetters,
  required Set<String> answerLabels,
  required Set<String> answerRomaji,
  required List<Kana> pool,
  required List<Kana> fallback,
  required Map<String, List<Kana>> partners,
  required String Function(Kana) labelOf,
  required bool usePartners,
  required int count,
  required int minCount,
  required Random rng,
}) {
  final blockedRomaji = {
    for (final k in answerLetters) k.romaji,
    ...answerRomaji,
  };
  final poolIds = {for (final k in pool) k.id};
  final ranked = <Kana>[];
  final seen = <String>{};

  void add(Kana k) {
    final label = labelOf(k);
    if (answerLabels.contains(label) || blockedRomaji.contains(k.romaji)) {
      return;
    }
    if (!seen.add(label)) return;
    ranked.add(k);
  }

  // 1) huruf yang sering tertukar (maksimal 2)
  if (usePartners) {
    final near = <Kana>[];
    for (final a in answerLetters) {
      for (final k in partners[a.id] ?? const <Kana>[]) {
        if (k.type == a.type && poolIds.contains(k.id)) near.add(k);
      }
    }
    near.shuffle(rng);
    for (final k in near) {
      if (ranked.length >= min(2, count)) break;
      add(k);
    }
  }

  // 2) bunyi mirip: konsonan awal atau vokal akhir sama dengan huruf jawaban
  bool similar(Kana k) => answerLetters.any((a) =>
      a.romaji[0] == k.romaji[0] ||
      a.romaji[a.romaji.length - 1] == k.romaji[k.romaji.length - 1]);
  final similarCap = ranked.length + (count - ranked.length + 1) ~/ 2;
  final others = [...pool]..shuffle(rng);
  for (final k in others.where(similar)) {
    if (ranked.length >= min(similarCap, count)) break;
    add(k);
  }

  // 3) huruf aktif lain
  for (final k in others) {
    if (ranked.length >= count) break;
    add(k);
  }

  // 4) cadangan: lengkapi sampai batas minimal dari seluruh huruf script
  if (ranked.length < minCount) {
    final extra = [...fallback]..shuffle(rng);
    for (final k in extra) {
      if (ranked.length >= minCount) break;
      add(k);
    }
  }
  return [for (final k in ranked) labelOf(k)];
}

/// Membuat satu soal Susun Kata untuk [word]. null kalau kata tidak bisa dibuat
/// jadi soal (lihat [isBuildable]).
BuildQuestion? buildQuestionFor({
  required Word word,
  required BuildDirection direction,
  required List<Kana> active,
  required Map<String, List<Kana>> partners,
  required Random rng,
}) {
  final pieces = WordRepository.parse(word.text);
  if (pieces == null) return null;
  final letters = [for (final p in pieces) if (p.kana != null) p.kana!];
  if (letters.isEmpty) return null;
  final script = letters.first.type;
  final romajiTiles = alignedRomajiTiles(pieces, word.reading);
  final kanaTiles = kanaTilesOf(pieces, script);
  if (romajiTiles == null || kanaTiles.join() != word.text) return null;

  final toKana = direction == BuildDirection.toKana;
  final answerTiles = toKana ? kanaTiles : romajiTiles;
  final pool = active.where((k) => k.type == script).toList();
  final fallback = script == 'hiragana' ? hiraganaList : katakanaList;

  // Total potongan menyesuaikan panjang kata; minimal 3 pengecoh.
  final n = answerTiles.length;
  final total = n <= 3 ? 8 : (n <= 5 ? 10 : 12);
  final distractors = _distractorLabels(
    answerLetters: letters,
    answerLabels: answerTiles.toSet(),
    answerRomaji: romajiTiles.toSet(),
    pool: pool,
    fallback: fallback,
    partners: partners,
    labelOf: (k) => toKana ? k.character : k.romaji,
    usePartners: toKana,
    count: max(3, total - n),
    minCount: 3,
    rng: rng,
  );

  final labels = [...answerTiles, ...distractors]..shuffle(rng);
  return BuildQuestion(
    direction: direction,
    word: word,
    prompt: toKana ? word.reading : word.text,
    answerTiles: answerTiles,
    tiles: [
      for (var i = 0; i < labels.length; i++) BuildTile(i, labels[i]),
    ],
  );
}

/// Menyusun satu sesi Susun Kata: kata dari huruf pilihan user (yang belum
/// pernah / paling lama tidak muncul diutamakan, sama seperti Reading), tanpa
/// kata yang diulang dalam satu sesi. Kalau kata yang tersedia lebih sedikit
/// dari [size], sesi mengikuti jumlah itu.
Future<List<BuildQuestion>> createBuildSession({
  required BuildDirection direction,
  required String type,
  required int size,
  String? vocabLevel,
  Random? rng,
}) async {
  final r = rng ?? Random();
  final words = WordRepository.instance;
  final active = await KanaRepository.instance.activeKana(type);
  final partners = await KanaRepository.instance.confusionPartners();
  final pool = [
    for (final w in await words.available(type, level: vocabLevel))
      if (isBuildable(w)) w,
  ];
  final picked = await words.pick(pool, min(size, pool.length), r);
  final questions = <BuildQuestion>[];
  for (final w in picked) {
    final q = buildQuestionFor(
      word: w,
      direction: direction,
      active: active,
      partners: partners,
      rng: r,
    );
    if (q != null) questions.add(q);
  }
  return questions;
}
