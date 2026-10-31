import 'dart:math';

import '../../data/models/kana.dart';
import '../../data/seed/kana_data.dart';

enum QuizKind { kanaToSound, soundToKana, lookalike }

extension QuizKindX on QuizKind {
  String get title => switch (this) {
        QuizKind.kanaToSound => 'Kana → sound',
        QuizKind.soundToKana => 'Sound → kana',
        QuizKind.lookalike => 'Look-alike drill',
      };

  String get subtitle => switch (this) {
        QuizKind.kanaToSound => 'See a character, pick its sound.',
        QuizKind.soundToKana => 'Hear a sound, pick the character.',
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

  /// Pilihan ditampilkan sebagai huruf (romaji TIDAK ditampilkan di bawahnya,
  /// supaya pengguna benar-benar mengingat karakternya).
  bool get optionsAreKana => kind != QuizKind.kanaToSound;

  String optionLabel(Kana k) => optionsAreKana ? k.character : k.romaji;

  /// Audio hanya boleh diputar sebelum menjawab kalau tidak membocorkan jawaban.
  bool get audioBeforeAnswer =>
      kind == QuizKind.soundToKana || kind == QuizKind.lookalike;
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
    if (picked.length >= 3) break;
  }
  // Kalau pengecoh dari pasangan tertukar sudah cukup, jangan tambah lagi:
  // menambah satu huruf ke daftar yang sudah 3 membuat syarat == 3 tidak
  // pernah terpenuhi dan seluruh kandidat ikut masuk.
  if (picked.length < 3) {
    for (final k in c) {
      if (used.add(k.romaji)) picked.add(k);
      if (picked.length >= 3) break;
    }
  }
  return [target, ...picked]..shuffle(rng);
}

/// Invarian soal pilihan ganda. [QuizQuestion] dibangun di banyak tempat, jadi
/// Maintainlah di sini supaya bug "tidak ada jawaban yang benar" tidak bisa
/// muncul diam-diam lagi.
bool isSaneQuestion(QuizQuestion q) {
  if (q.options.length != 4) return false;
  // Jawaban benar harus selalu ada.
  if (!q.options.any((k) => k.id == q.target.id)) return false;
  // Dua pilihan berlabel sama membuat pengguna mengira jawabannya hilang.
  if (q.options.map(q.optionLabel).toSet().length != q.options.length) {
    return false;
  }
  return true;
}

/// Mengembalikan [q] apa adanya setelah memastikan invariansnya benar.
QuizQuestion _checked(QuizQuestion q) {
  if (!isSaneQuestion(q)) {
    throw StateError(
      'Soal kuis tidak sah: kind=${q.kind} target=${q.target.id} '
      '(${q.target.typeLabel} "${q.target.romaji}") '
      'options=${q.options.map((k) => '${k.id}/${k.character}').toList()}',
    );
  }
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
    case QuizKind.lookalike:
      return _checked(QuizQuestion(
        kind: kind,
        target: target,
        prompt: 'Which character sounds like "${target.romaji}"?',
        options: _choices(target, rng, null, partners: partners),
      ));
  }
}
