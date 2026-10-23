import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kana_quest/data/repositories/word_repository.dart';
import 'package:kana_quest/data/seed/kana_data.dart';
import 'package:kana_quest/data/seed/word_data.dart';
import 'package:kana_quest/features/words/build_questions.dart';

void main() {
  late List<Word> real;

  setUpAll(() {
    real = WordBank.parse(File('assets/data/words.tsv').readAsStringSync());
  });

  List<String> romajiTiles(String t) =>
      romajiTilesOf(WordRepository.parse(t)!);
  List<String> kanaTiles(String t, String script) =>
      kanaTilesOf(WordRepository.parse(t)!, script);

  group('potongan', () {
    test('romaji: satu potongan = satu suku kata', () {
      expect(romajiTiles('あめ'), ['a', 'me']);
      expect(romajiTiles('しゃしん'), ['sha', 'shi', 'n']);
    });

    test('romaji: っ digabung dengan suku kata sesudahnya', () {
      expect(romajiTiles('きって'), ['ki', 'tte']);
      expect(romajiTiles('がっこう'), ['ga', 'kko', 'u']);
      expect(romajiTiles('キッチン'), ['ki', 'tchi', 'n']);
    });

    test('romaji: ー menjadi potongan vokal', () {
      expect(romajiTiles('ラーメン'), ['ra', 'a', 'me', 'n']);
      expect(romajiTiles('コーヒー'), ['ko', 'o', 'hi', 'i']);
    });

    test('kana: っ/ッ dan ー tetap potongan sendiri, きゃ satu potongan', () {
      expect(kanaTiles('きって', 'hiragana'), ['き', 'っ', 'て']);
      expect(kanaTiles('キッチン', 'katakana'), ['キ', 'ッ', 'チ', 'ン']);
      expect(kanaTiles('ラーメン', 'katakana'), ['ラ', 'ー', 'メ', 'ン']);
      expect(kanaTiles('しゃしん', 'hiragana'), ['しゃ', 'し', 'ん']);
    });

    test('gabungan potongan sama dengan romajiOf dan tulisan asli', () {
      for (final w in real) {
        final pieces = WordRepository.parse(w.text)!;
        final script = pieces.firstWhere((p) => p.kana != null).kana!.type;
        expect(romajiTilesOf(pieces).join(), WordRepository.romajiOf(pieces),
            reason: 'romaji ${w.text}');
        expect(kanaTilesOf(pieces, script).join(), w.text,
            reason: 'kana ${w.text}');
      }
    });

    test('ejaan daftar kata: cchi, partikel は, づ dan ぢ', () {
      List<String>? aligned(String t, String r) =>
          alignedRomajiTiles(WordRepository.parse(t)!, r);
      expect(aligned('キッチン', 'kicchin'), ['ki', 'cchi', 'n']);
      expect(aligned('しゅっちょう', 'shutchou'), ['shu', 'tcho', 'u']);
      expect(aligned('こんにちは', 'konnichiwa'),
          ['ko', 'n', 'ni', 'chi', 'wa']);
      expect(aligned('つづく', 'tsuzuku'), ['tsu', 'zu', 'ku']);
      expect(aligned('はなぢ', 'hanaji'), ['ha', 'na', 'ji']);
      expect(aligned('あめ', 'ame'), ['a', 'me']);
      expect(aligned('あめ', 'ane'), isNull); // romaji di data salah
    });

    // ちょうちょ di daftar kata dibaca "chouchou", padahal tulisannya
    // ちょ+う+ちょ ("choucho"): kesalahan data, jadi tidak dijadikan soal.
    const knownDataErrors = {'ちょうちょ'};

    test('semua kata di daftar bisa dibuat jadi soal (kecuali salah data)', () {
      final bad = {for (final w in real) if (!isBuildable(w)) w.text};
      expect(bad.difference(knownDataErrors), isEmpty,
          reason: 'kata tidak bisa disusun: $bad');
    });
  });

  group('soal', () {
    final allActive = [...hiraganaList, ...katakanaList];

    List<String> sorted(Iterable<String> x) => x.toList()..sort();

    BuildQuestion make(Word w, BuildDirection d, {int seed = 1}) =>
        buildQuestionFor(
          word: w,
          direction: d,
          active: allActive,
          partners: const {},
          rng: Random(seed),
        )!;

    test('setiap potongan jawaban ada, id unik, jumlah potongan wajar', () {
      for (final d in BuildDirection.values) {
        for (final w in real.where(isBuildable)) {
          final q = make(w, d);
          final labels = q.tiles.map((t) => t.label).toList();
          final remaining = [...labels];
          for (final a in q.answerTiles) {
            expect(remaining.remove(a), isTrue,
                reason: 'potongan "$a" hilang untuk ${w.text}');
          }
          expect(q.tiles.map((t) => t.id).toSet().length, q.tiles.length);
          // minimal 3 pengecoh
          expect(q.tiles.length - q.answerTiles.length,
              greaterThanOrEqualTo(3),
              reason: 'pengecoh kurang untuk ${w.text}');
          expect(q.slotCount, q.answerTiles.length);
          expect(q.isCorrect(q.answerTiles), isTrue);
        }
      }
    });

    test('arah toRomaji: jawaban = romaji kata, teks soal = kata Jepang', () {
      final w = real.firstWhere((w) => w.text == 'あめ');
      final q = make(w, BuildDirection.toRomaji);
      expect(q.prompt, 'あめ');
      expect(q.answer, 'ame');
    });

    test('arah toKana: jawaban = tulisan kata, teks soal = romaji', () {
      final w = real.firstWhere((w) => w.text == 'あめ');
      final q = make(w, BuildDirection.toKana);
      expect(q.prompt, 'ame');
      expect(q.answer, 'あめ');
    });

    test('pengecoh tidak pernah sama romajinya dengan huruf jawaban', () {
      // こんにちは dibaca "konnichiwa": わ (wa) tidak boleh jadi pengecoh
      // untuk は, karena kedua pilihan itu sama-sama cocok dengan "wa".
      const w = Word('こんにちは', 'konnichiwa', meaning: 'halo');
      for (var seed = 0; seed < 50; seed++) {
        final q = make(w, BuildDirection.toKana, seed: seed);
        expect(q.tiles.map((t) => t.label), isNot(contains('わ')));
        expect(q.answer, 'こんにちは');
        expect(q.prompt, 'konnichiwa');
      }
      // Pada seluruh kata: tidak ada pengecoh yang romajinya bentrok.
      for (final word in real.where(isBuildable)) {
        final pieces = WordRepository.parse(word.text)!;
        final blocked = {
          for (final p in pieces)
            if (p.kana != null) p.kana!.romaji,
          ...alignedRomajiTiles(pieces, word.reading)!,
        };
        final q = make(word, BuildDirection.toKana, seed: 7);
        final remaining = q.tiles.map((t) => t.label).toList();
        for (final a in q.answerTiles) {
          remaining.remove(a);
        }
        for (final label in remaining) {
          expect(blocked.contains(_romajiOf(label)), isFalse,
              reason: 'pengecoh $label bentrok untuk ${word.text}');
        }
      }
    });

    test('pengecoh romaji tidak sama dengan potongan jawaban', () {
      const w = Word('ささ', 'sasa', meaning: 'bambu kecil');
      for (var seed = 0; seed < 50; seed++) {
        final q = make(w, BuildDirection.toRomaji, seed: seed);
        // dua "sa" benar, tidak boleh ada "sa" lain sebagai pengecoh
        expect(q.tiles.where((t) => t.label == 'sa').length, 2);
      }
    });

    test('hanya memakai huruf aktif; cadangan dari semua huruf kalau kurang',
        () {
      const w = Word('あめ', 'ame', meaning: 'hujan');
      final few = hiraganaList.where((k) => ['あ', 'め', 'い'].contains(k.character)).toList();
      final q = buildQuestionFor(
        word: w,
        direction: BuildDirection.toKana,
        active: few,
        partners: const {},
        rng: Random(3),
      )!;
      // Hanya "い" yang aktif selain jawaban, jadi sisanya dari cadangan.
      expect(q.tiles.length - q.answerTiles.length, 3);
      expect(q.tiles.map((t) => t.label), contains('い'));
    });

    test('kata tak dikenal atau tidak cocok tidak jadi soal', () {
      final q = buildQuestionFor(
        word: const Word('日本', 'nihon'),
        direction: BuildDirection.toKana,
        active: allActive,
        partners: const {},
        rng: Random(1),
      );
      expect(q, isNull);
    });

    test('isCorrect membandingkan gabungan potongan', () {
      final w = real.firstWhere((w) => w.text == 'あめ');
      final q = make(w, BuildDirection.toKana);
      expect(q.isCorrect(['あ', 'め']), isTrue);
      expect(q.isCorrect(['め', 'あ']), isFalse);
      expect(sorted(q.answerTiles), ['あ', 'め']);
    });
  });
}

String _romajiOf(String kana) {
  for (final k in [...hiraganaList, ...katakanaList]) {
    if (k.character == kana) return k.romaji;
  }
  return kana; // っ / ー
}
