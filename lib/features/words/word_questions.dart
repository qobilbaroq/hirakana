import 'dart:math';

import '../../data/models/kana.dart';
import '../../data/repositories/kana_repository.dart';
import '../../data/repositories/word_repository.dart';
import '../../data/seed/kana_data.dart';
import '../../data/seed/word_data.dart';

enum ReadKind { word, chunk, single }

/// Satu soal latihan baca: tebak cara baca (romaji) dari kata, beberapa huruf,
/// atau satu huruf. Selalu 4 pilihan, satu benar.
class ReadQuestion {
  const ReadQuestion({
    required this.kind,
    required this.text,
    required this.letters,
    required this.answer,
    required this.options,
    this.word,
  });

  final ReadKind kind;
  final String text; // yang ditampilkan
  final List<Kana> letters; // huruf kana pembentuk (tanpa っ dan ー)
  final String answer; // romaji yang benar
  final List<String> options; // 4 romaji, memuat answer
  final Word? word; // hanya untuk kind == word

  /// Rekaman kata utuh tersedia?
  bool get hasWholeWordAudio => word?.hasAudio ?? false;
}

/// 4 pilihan romaji: [answer] ditambah 3 pengecoh yang dibuat dengan MENGGANTI
/// satu huruf pada soal dengan huruf lain dari script yang sama. Jadi
/// pilihannya mirip dan tidak bisa ditebak dari panjangnya. Huruf yang sering
/// tertukar ([partners]) diutamakan.
List<String> buildReadingOptions({
  required String answer,
  required List<WordPiece> pieces,
  required List<Kana> letterPool,
  required Random rng,
  Map<String, List<Kana>> partners = const {},
}) {
  final positions = [
    for (var i = 0; i < pieces.length; i++)
      if (pieces[i].kana != null) i,
  ];
  if (positions.isEmpty) {
    throw StateError('Soal baca tidak memiliki huruf kana: "$answer"');
  }
  final options = <String>{answer};

  var guard = 0;
  while (options.length < 4 && guard++ < 120) {
    final i = positions[rng.nextInt(positions.length)];
    final original = pieces[i].kana!;
    final near = (partners[original.id] ?? const <Kana>[])
        .where((k) => k.type == original.type)
        .toList();
    final Kana replacement;
    if (near.isNotEmpty && rng.nextDouble() < 0.4) {
      replacement = near[rng.nextInt(near.length)];
    } else {
      final candidates = letterPool.where((k) => k.id != original.id).toList();
      if (candidates.isEmpty) break;
      replacement = candidates[rng.nextInt(candidates.length)];
    }
    final copy = [...pieces];
    copy[i] = WordPiece.kana(replacement);
    options.add(WordRepository.romajiOf(copy));
  }

  // Cadangan (jarang terjadi): lengkapi dengan romaji huruf lain.
  if (options.length < 4) {
    final script = pieces[positions.first].kana!.type;
    final fallback = allKana.where((k) => k.type == script).toList()
      ..shuffle(rng);
    final extra = [...letterPool.where((k) => k.type == script), ...fallback];
    for (final k in extra) {
      options.add(k.romaji);
      if (options.length == 4) break;
    }
  }
  final result = options.toList()..shuffle(rng);
  if (result.length != 4 || !result.contains(answer)) {
    throw StateError('Pilihan baca tidak sah untuk "$answer": $result');
  }
  return result;
}

List<Kana> _scriptPool(List<Kana> active, String script) =>
    active.where((k) => k.type == script).toList();

/// Menyusun satu sesi latihan baca sebanyak [size] soal.
///
/// Komposisi: sekitar 60% kata sungguhan (diutamakan yang belum pernah /
/// paling lama tidak muncul), 25% rangkaian 2-3 huruf acak, 15% satu huruf.
/// Kalau kata yang cocok sedikit, sisanya diisi rangkaian huruf, jadi sesi
/// selalu penuh dan tidak ada soal yang itu-itu saja.
///
/// [vocabLevel] (n5n4 | n3) membatasi kata ke kosakata kelompok itu; kalau
/// dipilih, porsi kata dinaikkan jadi sekitar 85% (sisanya huruf/rangkaian).
Future<List<ReadQuestion>> buildReadingSession({
  required String type,
  required int size,
  String? vocabLevel,
  List<String>? onlyTexts,
  Random? rng,
}) async {
  final r = rng ?? Random();
  final repo = KanaRepository.instance;
  final words = WordRepository.instance;

  final active = await repo.activeKana(type);
  final partners = await repo.confusionPartners();

  // Script yang punya cukup huruf aktif untuk soal huruf/rangkaian.
  final scripts = [
    for (final s in ['hiragana', 'katakana'])
      if (_scriptPool(active, s).length >= WordRepository.minLetters) s,
  ];

  // [onlyTexts] = mengulang kata dari riwayat: pakai kata-kata itu saja,
  // tanpa menyaring huruf pilihan (kata sudah pernah dipelajari).
  final pool = onlyTexts != null
      ? await words.wordsFor(onlyTexts)
      : await words.available(type, level: vocabLevel);
  // Setiap soal adalah KATA SUNGGUHAN dengan rekaman utuh - tidak ada soal
  // rangkaian huruf atau satu huruf lagi, karena yang seperti itu bukan
  // kosakata dan suaranya hanya bunyi per huruf.
  //
  // Kalau huruf aktif masih sedikit sehingga pool-nya kecil, kata diulang
  // sampai sesi penuh - pola yang sama dipakai mode kuis untuk huruf
  // (fillToSize di KanaRepository.buildQueue). Rangkaian huruf dan satu
  // huruf hanya jadi cadangan kalau pool-nya benar-benar kosong, supaya
  // sesi tidak tampil nol soal.
  var wordCount = min(size, pool.length);
  var chunkCount = 0;
  var singleCount = 0;
  // Selisih ukuran sesi DAN pool diisi dengan mengulang kata (di bawah),
  // bukan dengan rangkaian huruf. Jadi chunkTotal = 0 selama pool tidak kosong.
  var chunkTotal = 0;
  if (pool.isEmpty) {
    wordCount = 0;
    chunkCount = scripts.isEmpty ? 0 : (size * 0.6).round();
    singleCount = scripts.isEmpty ? 0 : (size * 0.15).round();
    chunkTotal = chunkCount + (size - chunkCount - singleCount);
    if (scripts.isEmpty) chunkTotal = 0;
  }

  final questions = <ReadQuestion>[];
  final usedTexts = <String>{};

  // 1) kata sungguhan
  final picked = await words.pick(pool, wordCount, r);
  // Pool lebih kecil daripada ukuran sesi (huruf aktif masih sedikit):
  // ulangi kata yang sudah dipilih sampai sesi penuh, dengan urutan
  // diacak tiap putaran supaya kata yang sama tidak bersebelahan.
  if (picked.isNotEmpty && picked.length < size) {
    final base = [...picked];
    while (picked.length < size) {
      final round = [...base]..shuffle(r);
      picked.addAll(round.take(size - picked.length));
    }
  }
  for (final w in picked) {
    final pieces = WordRepository.parse(w.text)!;
    final letters = [
      for (final p in pieces)
        if (p.kana != null) p.kana!,
    ];
    final script = letters.first.type;
    var letterPool = _scriptPool(active, script);
    if (letterPool.length < WordRepository.minLetters) {
      letterPool = script == 'hiragana' ? hiraganaList : katakanaList;
    }
    questions.add(
      ReadQuestion(
        kind: ReadKind.word,
        text: w.text,
        letters: letters,
        answer: w.reading,
        options: buildReadingOptions(
          answer: w.reading,
          pieces: pieces,
          letterPool: letterPool,
          rng: r,
          partners: partners,
        ),
        word: w,
      ),
    );
    usedTexts.add(w.text);
  }

  // 2) rangkaian huruf acak (2-3 huruf)
  void addChunk() {
    final script = scripts[r.nextInt(scripts.length)];
    final letters = _scriptPool(active, script)..shuffle(r);
    final len = r.nextDouble() < 0.6 ? 2 : 3;
    final chosen = letters.take(min(len, letters.length)).toList();
    final text = chosen.map((k) => k.character).join();
    if (!usedTexts.add(text)) return;
    final pieces = [for (final k in chosen) WordPiece.kana(k)];
    final answer = WordRepository.romajiOf(pieces);
    questions.add(
      ReadQuestion(
        kind: ReadKind.chunk,
        text: text,
        letters: chosen,
        answer: answer,
        options: buildReadingOptions(
          answer: answer,
          pieces: pieces,
          letterPool: _scriptPool(active, script),
          rng: r,
          partners: partners,
        ),
      ),
    );
  }

  var guard = 0;
  while (scripts.isNotEmpty &&
      questions.where((q) => q.kind == ReadKind.chunk).length < chunkTotal &&
      guard++ < 400) {
    addChunk();
  }

  // 3) satu huruf
  guard = 0;
  while (scripts.isNotEmpty &&
      questions.where((q) => q.kind == ReadKind.single).length < singleCount &&
      guard++ < 200) {
    final script = scripts[r.nextInt(scripts.length)];
    final letterPool = _scriptPool(active, script);
    final k = letterPool[r.nextInt(letterPool.length)];
    if (!usedTexts.add(k.character)) continue;
    questions.add(
      ReadQuestion(
        kind: ReadKind.single,
        text: k.character,
        letters: [k],
        answer: k.romaji,
        options: buildReadingOptions(
          answer: k.romaji,
          pieces: [WordPiece.kana(k)],
          letterPool: letterPool,
          rng: r,
          partners: partners,
        ),
      ),
    );
  }

  // Pelengkap: kalau masih kurang dari [size] (kata dan huruf tunggal yang unik
  // terbatas), tambah rangkaian huruf supaya sesi selalu penuh.
  guard = 0;
  while (scripts.isNotEmpty && questions.length < size && guard++ < 800) {
    addChunk();
  }

  // Acak urutan dan pastikan teks yang sama tidak pernah bersebelahan.
  return _shuffleNoAdjacent(questions, r).take(size).toList();
}

/// Mengacak [items] dengan syarat dua item berurutan tidak punya teks sama.
/// Susun greedily: tiap kali ambil kandidat acak yang teksnya berbeda dari
/// yang terakhir. Kalau semua sisa kandidat bertabrakan (hanya mungkin kalau
/// semua teksnya identik), ambil saja yang pertama - tidak ada yang bisa
/// dilakukan.
List<ReadQuestion> _shuffleNoAdjacent(List<ReadQuestion> items, Random rng) {
  if (items.length < 2) return items;
  final rest = [...items]..shuffle(rng);
  final out = <ReadQuestion>[rest.removeLast()];
  while (rest.isNotEmpty) {
    final last = out.last.text;
    final pick = rest.indexWhere((q) => q.text != last);
    if (pick == -1) {
      out.addAll(rest);
      break;
    }
    out.add(rest.removeAt(pick));
  }
  return out;
}
