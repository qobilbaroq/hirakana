import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kana_quest/data/repositories/word_repository.dart';
import 'package:kana_quest/data/seed/kana_data.dart';
import 'package:kana_quest/data/seed/word_data.dart';
import 'package:kana_quest/features/words/word_questions.dart';

import 'helpers/test_db.dart';

Set<String> idsOfGroups(List<String> groups, {String type = 'hiragana'}) =>
    (type == 'hiragana' ? hiraganaList : katakanaList)
        .where((k) => groups.contains(k.group))
        .map((k) => k.id)
        .toSet();

void main() {
  late List<Word> real;

  setUpAll(() {
    real = WordBank.parse(File('assets/data/words.tsv').readAsStringSync());
    WordBank.instance.debugSet(real);
  });

  // Pool kata adalah daftar kurasi (729 kata) yang seluruhnya punya arti
  // Bahasa Indonesia dan rekaman utuh. Jadi yang dijaga di sini bukan
  // banyaknya, tapi kelengkapan: tidak boleh ada kata tanpa arti atau
  // tanpa rekaman.
  group('data kata (assets/data/words.tsv)', () {
    test('jumlahnya cukup dan setiap kata bisa dibaca app', () {
      expect(real.length, greaterThan(700));
      for (final w in real) {
        expect(WordRepository.parse(w.text), isNotNull,
            reason: 'karakter tak dikenal di "${w.text}"');
        expect(RegExp(r'^[a-z]+$').hasMatch(w.reading), isTrue,
            reason: 'romaji tidak valid: ${w.text} -> ${w.reading}');
      }
    });

    test('setiap kata punya arti Bahasa Indonesia yang singkat', () {
      for (final w in real) {
        expect(w.meaning.trim(), isNotEmpty,
            reason: 'kata tanpa arti: ${w.text}');
        expect(w.meaning.length, lessThanOrEqualTo(40),
            reason: 'arti terlalu panjang (${w.meaning.length} huruf): '
                '${w.text} -> ${w.meaning}');
      }
    });

    test('kata ber-audio punya file normal dan lambat', () {
      final withAudio = real.where((w) => w.hasAudio).toList();
      expect(withAudio.length, real.length,
          reason: 'hanya ${withAudio.length}/${real.length} kata punya rekaman');
      for (final w in withAudio) {
        expect(File('assets/audio/words/${w.reading}.mp3').existsSync(), isTrue,
            reason: 'rekaman hilang: ${w.reading}');
        expect(File('assets/audio/words/${w.reading}_slow.mp3').existsSync(), isTrue,
            reason: 'rekaman lambat hilang: ${w.reading}');
      }
    });

    test('kata bertambah terus di setiap tahap huruf, bukan hanya vowels + k + s', () {
      final groups = <String>[];
      final seen = <String>{};
      for (final k in hiraganaList) {
        if (seen.add(k.group)) groups.add(k.group);
      }
      var cumulative = <String>[];
      for (var i = 0; i < groups.length; i++) {
        cumulative = [...cumulative, groups[i]];
        final avail = WordRepository.filterAvailable(
            real, idsOfGroups(cumulative), 'hiragana');
        // Setiap tahap harus punya kata baru dibanding tahap sebelumnya.
        if (i >= 1) {
          final prev = WordRepository.filterAvailable(
              real, idsOfGroups(cumulative.sublist(0, i)), 'hiragana');
          expect(avail.length, greaterThan(prev.length),
              reason: 'tahap ${groups[i]} tidak menambah kata');
        }
        if (i >= 2) {
          expect(avail.length, greaterThanOrEqualTo(40),
              reason: 'hanya ${avail.length} kata sampai baris ${groups[i]}');
        }
      }
      // Seluruh hiragana: ratusan kata.
      final all = WordRepository.filterAvailable(
          real, hiraganaList.map((k) => k.id).toSet(), 'hiragana');
      expect(all.length, greaterThan(400));
      final allKata = WordRepository.filterAvailable(
          real, katakanaList.map((k) => k.id).toSet(), 'katakana');
      expect(allKata.length, greaterThan(250));
    });

    test('vowels + k + s: beberapa puluh kata, tidak berulang terus', () {
      final avail = WordRepository.filterAvailable(
          real, idsOfGroups(['vowels', 'k', 's']), 'hiragana');
      expect(avail.length, greaterThan(40));
      expect(avail.map((w) => w.text).toSet().length, avail.length);
    });
  });

  group('romaji', () {
    String romaji(String t) =>
        WordRepository.romajiOf(WordRepository.parse(t)!);

    test('kata biasa, kombinasi, っ dan ー', () {
      expect(romaji('あめ'), 'ame');
      expect(romaji('しゃしん'), 'shashin');
      expect(romaji('がっこう'), 'gakkou');
      expect(romaji('ラーメン'), 'raamen');
      expect(romaji('きって'), 'kitte');
      expect(romaji('ちゃいろ'), 'chairo');
    });

    test('parse menolak karakter tak dikenal (kanji)', () {
      expect(WordRepository.parse('日本'), isNull);
    });
  });

  group('buildReadingOptions', () {
    final pool = hiraganaList.take(5).toList(); // あ い う え お

    test('selalu 4 pilihan unik yang memuat jawaban', () {
      final rng = Random(7);
      final samples = <List<WordPiece>>[
        for (final t in ['あい', 'うえお', 'いえ', 'あおい', 'お'])
          WordRepository.parse(t)!,
      ];
      for (final pieces in samples) {
        for (var i = 0; i < 200; i++) {
          final answer = WordRepository.romajiOf(pieces);
          final o = buildReadingOptions(
              answer: answer, pieces: pieces, letterPool: pool, rng: rng);
          expect(o.length, 4);
          expect(o.toSet().length, 4, reason: '$o');
          expect(o, contains(answer));
        }
      }
    });

    test('pengecoh dibuat dengan mengganti satu huruf (mirip jawabannya)', () {
      final rng = Random(3);
      final pieces = WordRepository.parse('あいう')!;
      final o = buildReadingOptions(
          answer: 'aiu', pieces: pieces, letterPool: pool, rng: rng);
      for (final x in o.where((x) => x != 'aiu')) {
        expect(x.length, inInclusiveRange(2, 5));
      }
    });
  });

  group('buildReadingSession', () {
    setUp(() async {
      await TestDb.reset();
      WordBank.instance.debugSet(real);
    });

    Future<void> activate(List<String> groups) =>
        repo.setActiveIds(idsOfGroups(groups));

    test('sesi penuh, pilihan sah, tanpa teks dobel, ada variasi jenis soal', () async {
      await activate(['vowels', 'k', 's']);
      final qs = await buildReadingSession(
          type: 'hiragana', size: 10, rng: Random(1));
      expect(qs.length, 10);
      expect(qs.map((q) => q.text).toSet().length, 10);
      for (final q in qs) {
        expect(q.options.length, 4);
        expect(q.options.toSet().length, 4);
        expect(q.options, contains(q.answer));
      }
      expect(qs.any((q) => q.kind == ReadKind.word), isTrue);
      expect(qs.any((q) => q.kind != ReadKind.word), isTrue);
    });

    test('kata tidak berulang antar sesi selama masih ada yang belum muncul', () async {
      await activate(['vowels', 'k', 's']);
      final seenWords = <String>{};
      for (var s = 0; s < 6; s++) {
        final qs = await buildReadingSession(
            type: 'hiragana', size: 10, rng: Random(100 + s));
        final words =
            qs.where((q) => q.kind == ReadKind.word).map((q) => q.text).toList();
        expect(words.toSet().intersection(seenWords), isEmpty,
            reason: 'sesi ${s + 1} mengulang kata dari sesi sebelumnya');
        seenWords.addAll(words);
        await WordRepository.instance.markSeen(words);
      }
      expect(seenWords.length, greaterThanOrEqualTo(30));
    });

    test('sesi tetap penuh walau kata sedikit (hanya あいうえお)', () async {
      await activate(['vowels']);
      final qs = await buildReadingSession(
          type: 'hiragana', size: 10, rng: Random(2));
      expect(qs.length, 10);
      for (final q in qs) {
        expect(q.options, contains(q.answer));
      }
    });

    for (final size in [10, 25, 60]) {
      test('ukuran sesi $size terpenuhi (huruf unik terbatas pun)', () async {
        await activate(['vowels', 'k']);
        final qs = await buildReadingSession(
            type: 'hiragana', size: size, rng: Random(size));
        expect(qs.length, size);
      });
    }

    test('mixed: jawaban dan pilihan tetap sah', () async {
      await repo.setActiveIds({
        ...idsOfGroups(['vowels', 'k']),
        ...idsOfGroups(['vowels', 'k'], type: 'katakana'),
      });
      final qs = await buildReadingSession(
          type: 'mixed', size: 20, rng: Random(9));
      expect(qs.length, 20);
      for (final q in qs) {
        expect(q.options.toSet().length, 4);
        expect(q.options, contains(q.answer));
      }
    });
  });
}
