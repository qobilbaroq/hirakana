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
    // Semua jenis kuis yang tersisa memakai pilihan multiple.
    final choiceKinds = QuizKind.values;

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

  group('pengecoh dari pasangan tertukar', () {
    test('3 pengecoh dari partners tetap menghasilkan tepat 4 pilihan', () {
      final target = katakanaList.firstWhere((k) => k.romaji == 'ko');
      final partners = [
        katakanaList.firstWhere((k) => k.romaji == 'fu'),
        katakanaList.firstWhere((k) => k.romaji == 'ne'),
        katakanaList.firstWhere((k) => k.romaji == 'pe'),
      ];

      for (final kind in QuizKind.values) {
        final q = buildQuestion(
          target,
          kind,
          Random(1),
          pool: katakanaList,
          partners: partners,
        );
        expect(q.options.length, 4, reason: 'kind=$kind');
        expect(q.options.map(q.optionLabel).toSet().length, 4,
            reason: 'kind=$kind');
        expect(
          q.options.any((k) => k.id == target.id),
          isTrue,
          reason: 'jawaban benar hilang untuk kind=$kind',
        );
      }
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