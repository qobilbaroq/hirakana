import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kana_quest/data/models/kana.dart';
import 'package:kana_quest/data/seed/kana_data.dart';
import 'package:kana_quest/features/learn/quiz_question.dart';

/// Pool huruf aktif yang dipakai penguji: あいうえお + かきくけこ.
final _vowelsAndK = hiraganaList
    .where((k) =>
        ['a', 'i', 'u', 'e', 'o', 'ka', 'ki', 'ku', 'ke', 'ko'].contains(k.romaji))
    .toList();

final _smallPool = hiraganaList.take(3).toList(); // あ い う
final _tinyPool = hiraganaList.take(1).toList(); // あ
final _mixedPool = _vowelsAndK + katakanaList
    .where((k) => ['ka', 'ki', 'ku', 'ke', 'ko'].contains(k.romaji))
    .toList();

void main() {
  group('buildQuestion: pilihan jawaban selalu sah', () {
    // Kind yang memakai pilihanMultiple. kanaToRomaji adalah soal ketik,
    // jadi tidak punya options.
    final choiceKinds = QuizKind.values
        .where((k) => k != QuizKind.kanaToRomaji)
        .toList();

    final pools = <String, List<Kana>?>{
      'pool 10 huruf (vowels + k-row)': _vowelsAndK,
      'campur hiragana + katakana': _mixedPool,
      'pool kecil 3 huruf': _smallPool,
      'pool sangat kecil 1 huruf': _tinyPool,
      'pool null (semua huruf)': null,
    };

    for (final poolEntry in pools.entries) {
      for (final kind in choiceKinds) {
        test('${kind.name} dengan ${poolEntry.key}', () {
          final rng = Random(12345);
          final pool = poolEntry.value;
          for (var i = 0; i < 3000; i++) {
            final target = (pool ?? allKana)[rng.nextInt((pool ?? allKana).length)];
            final partners = <Kana>[allKana[rng.nextInt(allKana.length)]];
            final q = buildQuestion(target, kind, rng,
                pool: pool, partners: partners);

            final where = '$kind target=${target.id} pool=${poolEntry.key}';

            // 1. Jumlah pilihan harus tepat 4 (UI mengindeks o[0]..o[3]).
            expect(q.options.length, 4, reason: 'pilihan bukan 4 -> $where');

            // 2. Target WAJIB ada di pilihan (dicocokkan lewat id).
            expect(
              q.options.any((k) => k.id == target.id),
              isTrue,
              reason: 'JAWABAN BENAR TIDAK ADA -> $where; '
                  'options=${q.options.map((k) => '${k.id}/${q.optionLabel(k)}').toList()}',
            );

            // 3. Label tiap pilihan unik (dua pilihan dengan label sama
            //    membuat pengguna merasa jawabannya tidak ada).
            final labels = q.options.map(q.optionLabel).toList();
            expect(labels.toSet().length, labels.length,
                reason: 'label duplikat -> $where; labels=$labels');

            // 4. Label target muncul persis di salah satu pilihan.
            expect(labels, contains(q.optionLabel(target)),
                reason: 'label target hilang -> $where; labels=$labels');
          }
        });
      }
    }
  });

  group('buildQuestion: kanaToRomaji adalah soal ketik', () {
    test('tidak punya pilihan multiple', () {
      final rng = Random(7);
      for (var i = 0; i < 500; i++) {
        final target = _vowelsAndK[rng.nextInt(_vowelsAndK.length)];
        final q = buildQuestion(target, QuizKind.kanaToRomaji, rng,
            pool: _vowelsAndK);
        expect(q.isTyped, isTrue);
        expect(q.options, isEmpty);
        expect(q.showKana, isTrue);
      }
    });
  });

  group('buildQuestion: scriptDiff = 2 bunyi x 2 script', () {
    // Soal "Which one is Hiragana 'e'?" harus punya:
    //   2 opsi hiragana + 2 opsi katakana, dan 2 bunyi berbeda,
    // sehingga hanya SATU yang cocok script DAN bunyi.
    void checkStructure(QuizQuestion q, String where) {
      final t = q.target;
      final ids = q.options.map((k) => k.id).toSet();
      expect(ids.length, 4, reason: 'id opsi tidak unik -> $where');

      // Tepat satu opsi yang script DAN bunyi sama dengan target.
      final exact =
          q.options.where((k) => k.type == t.type && k.romaji == t.romaji);
      expect(exact.length, 1,
          reason: 'harus tepat 1 yang cocok script+bunyi -> $where; '
              'opsi=${q.options.map((k) => '${k.id}/${k.romaji}').toList()}');
      expect(exact.single.id, t.id);

      // Seimbang dua-dua.
      expect(q.options.where((k) => k.type == 'hiragana').length, 2,
          reason: 'bukan 2 hiragana -> $where');
      expect(q.options.where((k) => k.type == 'katakana').length, 2,
          reason: 'bukan 2 katakana -> $where');

      // Dua bunyi berbeda, masing-masing di kedua script.
      final romaji = q.options.map((k) => k.romaji).toSet();
      expect(romaji.length, 2,
          reason: 'bukan 2 bunyi berbeda -> $where: $romaji');
      for (final r in romaji) {
        final pair = q.options.where((k) => k.romaji == r);
        expect(pair.length, 2, reason: 'bunyi "$r" hanya muncul sekali -> $where');
        expect(pair.map((k) => k.type).toSet().length, 2,
            reason: 'bunyi "$r" tidak punya kedua script -> $where');
      }

      // Prompt harus menyebut script dan bunyi target.
      expect(q.prompt, contains(t.typeLabel));
      expect(q.prompt, contains(t.romaji));
    }

    test('pool 10 huruf: invarian 2x2 selalu berlaku', () {
      final rng = Random(99);
      for (var i = 0; i < 3000; i++) {
        final target = _vowelsAndK[rng.nextInt(_vowelsAndK.length)];
        final q = buildQuestion(target, QuizKind.scriptDiff, rng,
            pool: _vowelsAndK);
        checkStructure(q, 'pool10 ${target.id}');
      }
    });

    test('campur hiragana + katakana', () {
      final rng = Random(7);
      for (var i = 0; i < 3000; i++) {
        final target = _mixedPool[rng.nextInt(_mixedPool.length)];
        final q = buildQuestion(target, QuizKind.scriptDiff, rng,
            pool: _mixedPool);
        checkStructure(q, 'mixed ${target.id}');
      }
    });

    test('pool kecil 1 huruf tetap sah (jatuh ke semua huruf)', () {
      final rng = Random(3);
      for (var i = 0; i < 500; i++) {
        final target = _tinyPool.first;
        final q = buildQuestion(target, QuizKind.scriptDiff, rng,
            pool: _tinyPool);
        checkStructure(q, 'tiny ${target.id}');
      }
    });

    test('pool null', () {
      final rng = Random(21);
      for (var i = 0; i < 2000; i++) {
        final target = allKana[rng.nextInt(allKana.length)];
        final q = buildQuestion(target, QuizKind.scriptDiff, rng);
        checkStructure(q, 'null ${target.id}');
      }
    });

    test('tidak ada opsi yang dobel (script+bunyi)', () {
      final rng = Random(55);
      for (var i = 0; i < 3000; i++) {
        final target = allKana[rng.nextInt(allKana.length)];
        final q = buildQuestion(target, QuizKind.scriptDiff, rng);
        final keys =
            q.options.map((k) => '${k.type}_${k.romaji}').toSet();
        expect(keys.length, 4,
            reason: 'ada script+bunyi yang dobel untuk ${target.id}');
      }
    });

    test('isSaneQuestion menerima semua soal yang dihasilkan', () {
      final rng = Random(123);
      for (var i = 0; i < 3000; i++) {
        final target = allKana[rng.nextInt(allKana.length)];
        final pool = i.isEven ? _vowelsAndK : _mixedPool;
        final q = buildQuestion(target, QuizKind.scriptDiff, rng, pool: pool);
        expect(isSaneQuestion(q), isTrue,
            reason: 'isSaneQuestion menolak soal yang sah: ${q.options.map((k) => k.id).toList()}');
      }
    });
  });

  group('QuizQuestion.accepts', () {
    test('menerima romaji target dan variasinya', () {
      final ku = _vowelsAndK.firstWhere((k) => k.romaji == 'ku');
      final q = buildQuestion(ku, QuizKind.kanaToRomaji, Random(1));
      expect(q.accepts('ku'), isTrue);
      expect(q.accepts(' KU '), isTrue);
      expect(q.accepts('ko'), isFalse);
      expect(q.accepts(''), isFalse);
    });

    test('menerima ejaan alternatif (shi/si, tsu/tu)', () {
      final shi = hiraganaList.firstWhere((k) => k.romaji == 'shi');
      expect(buildQuestion(shi, QuizKind.kanaToRomaji, Random(1)).accepts('si'),
          isTrue);
      final tsu = hiraganaList.firstWhere((k) => k.romaji == 'tsu');
      expect(buildQuestion(tsu, QuizKind.kanaToRomaji, Random(1)).accepts('tu'),
          isTrue);
    });
  });

  group('data kana', () {
    test('く/ク = ku dan こ/コ = ko dengan id & group benar', () {
      final hKu = hiraganaList.firstWhere((k) => k.romaji == 'ku');
      expect(hKu.character, 'く');
      expect(hKu.group, 'k');
      expect(hKu.type, 'hiragana');

      final kKu = katakanaList.firstWhere((k) => k.romaji == 'ku');
      expect(kKu.character, 'ク');
      expect(kKu.type, 'katakana');

      final hKo = hiraganaList.firstWhere((k) => k.romaji == 'ko');
      expect(hKo.character, 'こ');
      final kKo = katakanaList.firstWhere((k) => k.romaji == 'ko');
      expect(kKo.character, 'コ');
    });
  });
}