import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kana_quest/data/seed/kana_data.dart';
import 'package:kana_quest/data/seed/word_data.dart';
import 'package:kana_quest/features/words/meaning_questions.dart';

import 'helpers/test_db.dart';

void main() {
  late List<Word> real;

  setUpAll(() {
    real = WordBank.parse(File('assets/data/words.tsv').readAsStringSync());
    WordBank.instance.debugSet(real);
  });

  group('meaningsClash', () {
    test('arti sama persis bentrok, tanpa membedakan huruf besar', () {
      expect(meaningsClash('biru', 'Biru'), isTrue);
    });

    test('berbagi kata penting bentrok', () {
      expect(meaningsClash('satu (buah)', 'lantai satu / satu kali'), isTrue);
      expect(meaningsClash('makan', 'makan malam'), isTrue);
    });

    test('kata umum seperti "buah" dan "saya" tidak dihitung', () {
      expect(meaningsClash('lima (buah)', 'tiga (buah)'), isFalse);
      expect(meaningsClash('ayah (saya)', 'ibu (saya)'), isFalse);
    });

    test('arti yang berbeda tidak bentrok', () {
      expect(meaningsClash('rumah', 'sekolah'), isFalse);
    });
  });

  group('buildMeaningOptions', () {
    test(
      'selalu 4 pilihan unik, memuat jawaban, tanpa pilihan yang bentrok',
      () {
        for (var seed = 0; seed < 3; seed++) {
          final rng = Random(seed);
          for (final w in real) {
            final options = buildMeaningOptions(
              target: w,
              bank: real,
              rng: rng,
            );
            expect(options.length, 4, reason: 'pilihan kurang untuk ${w.text}');
            expect(
              options.toSet().length,
              4,
              reason: 'pilihan dobel untuk ${w.text}: $options',
            );
            expect(options, contains(w.meaning));
            final wrong = options.where((o) => o != w.meaning);
            for (final o in wrong) {
              expect(
                meaningsClash(o, w.meaning),
                isFalse,
                reason: '"$o" bisa ikut benar untuk ${w.text} (${w.meaning})',
              );
            }
          }
        }
      },
    );

    test('pengecoh diutamakan dari kategori yang sama', () {
      final target = real.firstWhere((w) => w.category == 'Hewan');
      var sameCategory = 0;
      const rounds = 30;
      for (var i = 0; i < rounds; i++) {
        final options = buildMeaningOptions(
          target: target,
          bank: real,
          rng: Random(i),
        );
        final distractors = options.where((o) => o != target.meaning);
        sameCategory += real
            .where(
              (w) =>
                  w.category == target.category &&
                  distractors.contains(w.meaning),
            )
            .map((w) => w.meaning)
            .toSet()
            .length;
      }
      // Dua dari tiga pengecoh dari kategori yang sama (kurang sedikit kalau
      // artinya kebetulan dipakai kata dari kategori lain juga).
      expect(sameCategory, greaterThanOrEqualTo(rounds));
    });

    test(
      'bank yang tidak cukup menghasilkan error, bukan soal tanpa jawaban',
      () {
        final target = real.first;
        expect(
          () => buildMeaningOptions(
            target: target,
            bank: [target],
            rng: Random(1),
          ),
          throwsA(isA<StateError>()),
        );
      },
    );
  });

  group('buildMeaningSession', () {
    setUp(() async {
      await TestDb.reset();
    });

    Future<void> activate(List<String> groups) => repo.setActiveIds(
      hiraganaList
          .where((k) => groups.contains(k.group))
          .map((k) => k.id)
          .toSet(),
    );

    test('sesi penuh, semua kata punya pilihan sah', () async {
      await activate(['vowels', 'k', 's']);
      final qs = await buildMeaningSession(
        type: 'hiragana',
        size: 10,
        rng: Random(1),
      );
      expect(qs.length, 10);
      for (final q in qs) {
        expect(q.options.length, 4);
        expect(q.options, contains(q.answer));
      }
    });

    test(
      'pool kecil: sesi tetap penuh dan kata tidak sama berturut-turut',
      () async {
        await activate(['vowels']);
        final qs = await buildMeaningSession(
          type: 'hiragana',
          size: 25,
          rng: Random(2),
        );
        expect(qs.length, 25);
        for (var i = 1; i < qs.length; i++) {
          expect(
            qs[i].word.text == qs[i - 1].word.text,
            isFalse,
            reason: '"${qs[i].word.text}" muncul dua kali berturut',
          );
        }
      },
    );

    test(
      'onlyTexts: hanya kata dari daftar itu, walau hurufnya belum dipilih',
      () async {
        await activate(['vowels']);
        final texts = real.take(5).map((w) => w.text).toList();
        final qs = await buildMeaningSession(
          type: 'mixed',
          size: 10,
          onlyTexts: texts,
          rng: Random(3),
        );
        expect(qs.length, 10);
        expect(qs.every((q) => texts.contains(q.word.text)), isTrue);
      },
    );

    test('tanpa kata yang cocok: sesi kosong, bukan error', () async {
      await repo.setActiveIds(<String>{});
      final qs = await buildMeaningSession(
        type: 'hiragana',
        size: 10,
        rng: Random(4),
      );
      expect(qs, isEmpty);
    });
  });
}
