import 'dart:math';

import '../../data/repositories/word_repository.dart';
import '../../data/seed/word_data.dart';

/// Satu soal tebak arti: lihat kata (tulisan Jepang), pilih arti Bahasa
/// Indonesia yang benar. Maksimal 4 pilihan, satu benar.
class MeaningQuestion {
  const MeaningQuestion({required this.word, required this.options});

  final Word word;
  final List<String> options; // arti-arti, memuat word.meaning

  String get answer => word.meaning;
}

/// Kata-kata umum yang tidak dihitung saat membandingkan dua arti.
const _ignoredTokens = {
  'buah',
  'saya',
  'yang',
  'dan',
  'untuk',
  'dari',
  'dengan',
};

Set<String> _tokens(String meaning) => {
  for (final t in meaning.toLowerCase().split(RegExp(r'[^a-z]+')))
    if (t.length >= 3 && !_ignoredTokens.contains(t)) t,
};

/// Dua arti dianggap bentrok kalau sama persis atau berbagi kata penting,
/// misalnya "satu (buah)" dan "lantai satu / satu kali". Pengecoh yang
/// bentrok dengan jawaban bisa ikut benar, jadi tidak boleh dipakai.
bool meaningsClash(String a, String b) {
  if (a.trim().toLowerCase() == b.trim().toLowerCase()) return true;
  return _tokens(a).intersection(_tokens(b)).isNotEmpty;
}

/// Susun pilihan arti untuk [target]: arti yang benar ditambah sampai 3
/// pengecoh dari [bank]. Pengecoh diutamakan dari kategori yang sama (dua
/// pertama) supaya tidak terlalu mudah ditebak, tidak pernah bentrok dengan
/// jawaban atau satu sama lain, dan semua pilihan berbeda.
List<String> buildMeaningOptions({
  required Word target,
  required List<Word> bank,
  required Random rng,
}) {
  final candidates = [
    for (final w in bank)
      if (w.text != target.text &&
          w.meaning.isNotEmpty &&
          !meaningsClash(w.meaning, target.meaning))
        w,
  ]..shuffle(rng);

  final sameCategory = target.category.isEmpty
      ? <Word>[]
      : candidates.where((w) => w.category == target.category).toList();
  final others = candidates.where((w) => !sameCategory.contains(w)).toList();

  final picked = <String>[];
  void tryAdd(Word w) {
    if (picked.length >= 3) return;
    if (picked.any((m) => meaningsClash(m, w.meaning))) return;
    picked.add(w.meaning);
  }

  for (final w in sameCategory.take(8)) {
    if (picked.length >= 2) break;
    tryAdd(w);
  }
  for (final w in others) {
    if (picked.length >= 3) break;
    tryAdd(w);
  }
  for (final w in sameCategory) {
    if (picked.length >= 3) break;
    tryAdd(w);
  }

  final options = [target.meaning, ...picked]..shuffle(rng);
  if (options.length != 4 || options.toSet().length != 4) {
    throw StateError('Pilihan arti tidak sah untuk "${target.text}": $options');
  }
  return options;
}

/// Menyusun satu sesi tebak arti sebanyak [size] soal.
///
/// Kata diambil dari kata yang bisa dibaca dari huruf pilihan pengguna
/// (kata yang belum pernah / paling lama tidak muncul diutamakan), atau dari
/// [onlyTexts] kalau mengulang kata dari riwayat. Kalau kata yang tersedia
/// lebih sedikit dari [size], kata diulang (diacak per putaran) sampai sesi
/// penuh, sama seperti latihan baca.
Future<List<MeaningQuestion>> buildMeaningSession({
  required String type,
  required int size,
  String? vocabLevel,
  List<String>? onlyTexts,
  Random? rng,
}) async {
  final r = rng ?? Random();
  final repo = WordRepository.instance;
  final pool = onlyTexts != null
      ? await repo.wordsFor(onlyTexts)
      : await repo.available(type, level: vocabLevel);
  final withMeaning = [
    for (final w in pool)
      if (w.meaning.isNotEmpty) w,
  ];
  if (withMeaning.isEmpty) return const [];

  final picked = await repo.pick(withMeaning, min(size, withMeaning.length), r);
  if (picked.length < size) {
    final base = [...picked];
    while (picked.length < size) {
      final round = [...base]..shuffle(r);
      // Jangan sampai kata yang sama muncul dua kali berurutan di sambungan.
      if (round.length > 1 && round.first.text == picked.last.text) {
        final last = round.removeAt(0);
        round.add(last);
      }
      picked.addAll(round.take(size - picked.length));
    }
  }

  final bank = await WordBank.instance.load();
  return [
    for (final w in picked)
      MeaningQuestion(
        word: w,
        options: buildMeaningOptions(target: w, bank: bank, rng: r),
      ),
  ];
}
