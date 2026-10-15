import 'dart:math';

import '../../data/models/kana.dart';
import '../../data/seed/kana_data.dart';

enum QuizKind { kanaToSound, soundToKana, kanaToRomaji, scriptDiff, lookalike }

extension QuizKindX on QuizKind {
  String get title => switch (this) {
        QuizKind.kanaToSound => 'Kana → sound',
        QuizKind.soundToKana => 'Sound → kana',
        QuizKind.kanaToRomaji => 'Kana → romaji',
        QuizKind.scriptDiff => 'Hiragana vs Katakana',
        QuizKind.lookalike => 'Look-alike drill',
      };

  String get subtitle => switch (this) {
        QuizKind.kanaToSound => 'See a character, pick its sound.',
        QuizKind.soundToKana => 'Hear a sound, pick the character.',
        QuizKind.kanaToRomaji => 'See a character, type the romaji.',
        QuizKind.scriptDiff => 'Same sound, different script.',
        QuizKind.lookalike => 'Letters you often mix up, side by side.',
      };
}

class QuizQuestion {
  const QuizQuestion({
    required this.kind,
    required this.target,
    required this.prompt,
    this.showKana = false,
    this.options = const [],
  });

  final QuizKind kind;
  final Kana target;
  final String prompt;
  final bool showKana;
  final List<Kana> options;

  bool get isTyped => kind == QuizKind.kanaToRomaji;

  /// Pilihan ditampilkan sebagai huruf (romaji TIDAK ditampilkan di bawahnya,
  /// supaya pengguna benar-benar mengingat karakternya).
  bool get optionsAreKana => kind != QuizKind.kanaToSound;

  String optionLabel(Kana k) => optionsAreKana ? k.character : k.romaji;

  /// Audio hanya boleh diputar sebelum menjawab kalau tidak membocorkan jawaban.
  bool get audioBeforeAnswer =>
      kind == QuizKind.soundToKana ||
      kind == QuizKind.scriptDiff ||
      kind == QuizKind.lookalike;

  static const _alternatives = {
    'shi': ['si'],
    'chi': ['ti'],
    'tsu': ['tu'],
    'fu': ['hu'],
    'wo': ['o'],
    'ji': ['zi'],
    'di': ['ji', 'dji'],
    'du': ['zu', 'dzu'],
    'sha': ['sya'],
    'shu': ['syu'],
    'sho': ['syo'],
    'cha': ['tya'],
    'chu': ['tyu'],
    'cho': ['tyo'],
    'ja': ['jya', 'zya'],
    'ju': ['jyu', 'zyu'],
    'jo': ['jyo', 'zyo'],
  };

  bool accepts(String input) {
    final value = input.trim().toLowerCase();
    if (value.isEmpty) return false;
    if (value == target.romaji) return true;
    return (_alternatives[target.romaji] ?? const []).contains(value);
  }
}

/// Pilihan jawaban: utamakan huruf aktif milik pengguna ([pool]); kalau kurang
/// dari 3 pengecoh, lengkapi dari seluruh huruf. Romaji tiap pilihan unik.
///
/// [partners] = huruf yang sering tertukar dengan [target]; mereka dijadikan
/// pengecoh lebih dulu supaya pembedaannya benar-benar dilatih.
List<Kana> _choices(
  Kana target,
  Random rng,
  List<Kana>? pool, {
  List<Kana> partners = const [],
}) {
  List<Kana> candidates(List<Kana> source) => source
      .where((k) => k.type == target.type && k.romaji != target.romaji)
      .toList();

  var c = candidates(pool ?? allKana);
  if (c.map((k) => k.romaji).toSet().length < 3) c = candidates(allKana);
  c.shuffle(rng);

  final used = <String>{target.romaji};
  final picked = <Kana>[];
  for (final k in partners) {
    if (k.type == target.type && used.add(k.romaji)) picked.add(k);
    if (picked.length == 3) break;
  }
  for (final k in c) {
    if (used.add(k.romaji)) picked.add(k);
    if (picked.length == 3) break;
  }
  return [target, ...picked]..shuffle(rng);
}

/// Invarian soal pilihan ganda. [QuizQuestion] dibangun di banyak tempat, jadi
/// Maintainlah di sini supaya bug "tidak ada jawaban yang benar" tidak bisa
/// muncul diam-diam lagi.
bool isSaneQuestion(QuizQuestion q) {
  if (q.isTyped) return q.options.isEmpty; // soal ketik tidak punya pilihan
  if (q.options.length != 4) return false;
  // Jawaban benar harus selalu ada.
  if (!q.options.any((k) => k.id == q.target.id)) return false;
  // Dua pilihan berlabel sama membuat pengguna mengira jawabannya hilang.
  if (q.options.map(q.optionLabel).toSet().length != q.options.length) {
    return false;
  }
  // Hiragana vs Katakana harus berbentuk 2 bunyi x 2 script.
  if (q.kind == QuizKind.scriptDiff) {
    final t = q.target;
    // Tepat satu opsi yang script DAN bunyinya sama dengan target.
    if (q.options
            .where((k) => k.type == t.type && k.romaji == t.romaji)
            .length !=
        1) {
      return false;
    }
    // Seimbang: dua hiragana dan dua katakana.
    if (q.options.where((k) => k.type == 'hiragana').length != 2) return false;
    if (q.options.where((k) => k.type == 'katakana').length != 2) return false;
    // Dua bunyi berbeda, masing-masing muncul di kedua script.
    if (q.options.map((k) => k.romaji).toSet().length != 2) return false;
    for (final romaji in q.options.map((k) => k.romaji).toSet()) {
      if (q.options.where((k) => k.romaji == romaji).length != 2) return false;
    }
  }
  return true;
}

/// Mengembalikan [q] apa adanya, tapi lebih dulu memastikan invariansnya benar
/// (dalam mode debug/test ada yang melempar error).
QuizQuestion _checked(QuizQuestion q) {
  assert(
    isSaneQuestion(q),
    'Soal kuis tidak sah: kind=${q.kind} target=${q.target.id} '
    '(${q.target.typeLabel} "${q.target.romaji}") '
    'options=${q.options.map((k) => '${k.id}/${k.character}').toList()}',
  );
  return q;
}

QuizQuestion buildQuestion(
  Kana target,
  QuizKind kind,
  Random rng, {
  List<Kana>? pool,
  List<Kana> partners = const [],
}) {
  switch (kind) {
    case QuizKind.kanaToSound:
      return _checked(QuizQuestion(
        kind: kind,
        target: target,
        prompt: 'What sound does this make?',
        showKana: true,
        options: _choices(target, rng, pool, partners: partners),
      ));
    case QuizKind.soundToKana:
      return _checked(QuizQuestion(
        kind: kind,
        target: target,
        prompt: 'Which character sounds like "${target.romaji}"?',
        options: _choices(target, rng, pool, partners: partners),
      ));
    case QuizKind.kanaToRomaji:
      return QuizQuestion(
        kind: kind,
        target: target,
        prompt: 'Type the romaji for this character',
        showKana: true,
      );
    case QuizKind.lookalike:
      return _checked(QuizQuestion(
        kind: kind,
        target: target,
        prompt: 'Which character sounds like "${target.romaji}"?',
        options: _choices(target, rng, null, partners: partners),
      ));
    case QuizKind.scriptDiff:
      // Desain 2 bunyi x 2 script:
      //   target (T,R) + counterpart (script lawan, R)
      //   other(T,R2) + otherCounterpart (script lawan, R2)
      // Jadi tepat satu pilihan cocok script DAN bunyi, dua pilihan se-script
      // dan dua pilihan se-bunyi: pengguna harus tahu keduanya, bukan cuma
      // mencari satu-satunya yang berbeda script.
      final counterpart = allKana.firstWhere(
          (k) => k.romaji == target.romaji && k.type != target.type);

      // Huruf pembanding: bunyi lain, script SAMA seperti target. Utamakan
      // dari huruf aktif pengguna; kalau tidak ada, ambil dari semua huruf.
      bool usable(Kana k) =>
          k.type == target.type && k.romaji != target.romaji;
      final fromPool =
          (pool ?? const <Kana>[]).where(usable).toList();
      final otherSource =
          fromPool.isNotEmpty ? fromPool : allKana.where(usable).toList();
      final other = (otherSource.toList()..shuffle(rng)).first;
      final otherCounterpart = allKana.firstWhere(
          (k) => k.romaji == other.romaji && k.type != other.type);

      return _checked(
        QuizQuestion(
          kind: kind,
          target: target,
          prompt: 'Which one is ${target.typeLabel} "${target.romaji}"?',
          options: [target, counterpart, other, otherCounterpart]..shuffle(rng),
        ),
      );
  }
}
