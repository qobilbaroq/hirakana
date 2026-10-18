import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kana_quest/core/settings/app_settings.dart';
import 'package:kana_quest/data/repositories/word_repository.dart';
import 'package:kana_quest/data/seed/kana_data.dart';
import 'package:kana_quest/data/seed/word_data.dart';
import 'package:kana_quest/features/words/word_questions.dart';

import 'helpers/test_db.dart';

final _audioDir = Directory('assets/audio/words');

List<Word> _loadBank() {
  final file = File('assets/data/words.tsv');
  return WordBank.parse(file.readAsStringSync());
}

void main() {
  final all = _loadBank();
  final jlpt = all.where((w) => w.level.isNotEmpty).toList();

  group('words.tsv bisa diparse', () {
    test('baris 4-7 kolom dan romaji hanya [a-z]+', () {
      final raw = File('assets/data/words.tsv').readAsLinesSync();
      var kolom = <int>{};
      for (final line in raw) {
        if (line.trim().isEmpty) continue;
        kolom.add(line.split('\t').length);
        final c = line.split('\t');
        expect(
          RegExp(r'^[a-z]+$').hasMatch(c[1]),
          isTrue,
          reason: 'romaji bukan [a-z]+: "${c[1]}"',
        );
      }
      for (final n in kolom) {
        expect(n, inInclusiveRange(4, 7), reason: 'jumlah kolom $n');
      }
    });

    test('WordBank.parse menerima format lama 4 kolom', () {
      final parsed = WordBank.parse('あめ\tame\t1\thujan');
      expect(parsed, hasLength(1));
      expect(parsed.first.meaning, 'hujan');
      expect(parsed.first.meaningEn, '');
      expect(parsed.first.level, '');
      expect(parsed.first.kanji, '');
    });

    test('WordBank.parse membaca 7 kolom', () {
      final parsed = WordBank.parse('あめ\tame\t1\thujan\tran\tN5\t雨');
      final w = parsed.first;
      expect(w.meaning, 'hujan');
      expect(w.meaningEn, 'ran');
      expect(w.level, 'N5');
      expect(w.kanji, '雨');
    });
  });

  group('isi kata', () {
    test('setiap kata bisa di-parse oleh WordRepository.parse', () {
      final bad = <String>[];
      for (final w in all) {
        if (WordRepository.parse(w.text) == null) bad.add(w.text);
      }
      expect(
        bad,
        isEmpty,
        reason:
            '${bad.length} kata tidak bisa di-parse, contoh: ${bad.take(5)}',
      );
    });

    test('tidak ada teks kata yang ganda', () {
      final seen = <String, int>{};
      for (final w in all) {
        seen[w.text] = (seen[w.text] ?? 0) + 1;
      }
      final dupes = seen.entries.where((e) => e.value > 1).map((e) => e.key);
      expect(dupes, isEmpty, reason: 'duplikat: ${dupes.take(5)}');
    });

    test('arti tambahan yang cocok tersedia di words.tsv', () {
      final extra = File('tool/translations/meanings_extra.tsv')
          .readAsLinesSync()
          .where((line) => line.trim().isNotEmpty && !line.startsWith('#'))
          .map((line) => line.split('\t'))
          .toList();
      expect(extra, hasLength(7568));
      final byText = {for (final word in all) word.text: word};
      final missing = <String>[];

      for (final row in extra) {
        expect(row, hasLength(2), reason: 'format TSV salah: $row');
        expect(row[1].trim(), isNotEmpty, reason: 'arti kosong: ${row[0]}');
        expect(
          row[1].length,
          lessThanOrEqualTo(60),
          reason: 'arti terlalu panjang: ${row[0]}',
        );
        expect(
          row[1].allMatches('(').length,
          row[1].allMatches(')').length,
          reason: 'kurung tidak berpasangan: ${row[0]}',
        );
        expect(
          row[1].toLowerCase(),
          isNot('istilah khusus'),
          reason: 'placeholder belum diterjemahkan: ${row[0]}',
        );
        final word = byText[row[0]];
        if (word != null && word.meaning.trim().isEmpty) {
          missing.add(row[0]);
        }
      }
      expect(
        missing,
        isEmpty,
        reason: 'arti tambahan belum masuk: ${missing.take(10)}',
      );
    });

    test('arti tambahan tidak memiliki kata ganda', () {
      final extra = File('tool/translations/meanings_extra.tsv')
          .readAsLinesSync()
          .where((line) => line.trim().isNotEmpty && !line.startsWith('#'))
          .map((line) => line.split('\t').first)
          .toList();
      final seen = <String>{};
      final duplicates = extra.where((text) => !seen.add(text)).toList();
      expect(
        duplicates,
        isEmpty,
        reason: 'duplikat di meanings_extra.tsv: ${duplicates.take(10)}',
      );
    });

    test('arti tambahan tidak mengulang butir makna', () {
      final lines = File('tool/translations/meanings_extra.tsv')
          .readAsLinesSync()
          .where((line) => line.trim().isNotEmpty && !line.startsWith('#'));
      final duplicates = <String>[];
      for (final line in lines) {
        final row = line.split('\t');
        expect(row, hasLength(2), reason: 'format TSV salah: $row');
        final items = row[1]
            .split(RegExp(r'[;,]'))
            .map((item) => item.trim().toLowerCase())
            .where((item) => item.isNotEmpty)
            .toList();
        if (items.toSet().length != items.length) duplicates.add(row[0]);
      }
      expect(
        duplicates,
        isEmpty,
        reason: 'butir makna ganda: ${duplicates.take(10)}',
      );
    });

    test('catatan arti yang diragukan cocok dengan terjemahan tambahan', () {
      final meanings = <String, String>{};
      for (final line in File(
        'tool/translations/meanings_extra.tsv',
      ).readAsLinesSync()) {
        if (line.trim().isEmpty || line.startsWith('#')) continue;
        final row = line.split('\t');
        if (row.length == 2) meanings[row[0]] = row[1];
      }
      final uncertain = File('tool/translations/uncertain_extra.tsv')
          .readAsLinesSync()
          .where((line) => line.trim().isNotEmpty && !line.startsWith('#'))
          .map((line) => line.split('\t'))
          .toList();
      final seen = <String>{};
      for (final row in uncertain) {
        expect(row, hasLength(3), reason: 'format TSV salah: $row');
        expect(row[2].trim(), isNotEmpty, reason: 'alasan kosong: ${row[0]}');
        expect(seen.add(row[0]), isTrue, reason: 'catatan ganda: ${row[0]}');
        expect(
          meanings[row[0]],
          row[1],
          reason: 'arti berbeda dari meanings_extra: ${row[0]}',
        );
      }
    });

    test('koreksi manual tetap menang atas arti tambahan', () {
      final fixes = File('tool/translations/manual_fixes.tsv')
          .readAsLinesSync()
          .where((line) => line.trim().isNotEmpty && !line.startsWith('#'))
          .map((line) => line.split('\t'))
          .toList();
      final byText = {for (final word in all) word.text: word};
      for (final fix in fixes) {
        expect(fix, hasLength(2), reason: 'format TSV salah: $fix');
        final word = byText[fix[0]];
        if (word != null) {
          expect(
            word.meaning,
            fix[1].trim(),
            reason: 'koreksi hilang: ${fix[0]}',
          );
        }
      }
    });

    test('level hanya N5/N4/N3 atau kosong', () {
      for (final w in all) {
        expect(
          w.level == '' || Word.levels.contains(w.level),
          isTrue,
          reason: 'level tak dikenal: "${w.level}" di ${w.text}',
        );
      }
    });

    test('setiap kata JLPT punya arti Inggris (100%)', () {
      final without = jlpt.where((w) => w.meaningEn.trim().isEmpty).toList();
      expect(
        without,
        isEmpty,
        reason: '${without.length} kata JLPT tanpa arti Inggris',
      );
    });

    test('panjang arti tidak melebihi 60 karakter', () {
      final tooLong = all
          .where((w) => w.meaning.length > 60 || w.meaningEn.length > 60)
          .toList();
      expect(
        tooLong,
        isEmpty,
        reason: 'terlalu panjang: ${tooLong.take(3).map((w) => w.meaning)}',
      );
    });

    test('KOREKSI: minimal 90% kata JLPT punya arti Indonesia', () {
      final withIndo = jlpt.where((w) => w.meaning.trim().isNotEmpty).length;
      final pct = withIndo / jlpt.length * 100;
      expect(
        pct,
        greaterThanOrEqualTo(90.0),
        reason:
            'hanya $withIndo/${jlpt.length} = ${pct.toStringAsFixed(1)}% '
            'punya arti Indonesia. Sisanya memakai arti Inggris (label EN).',
      );
    });
  });

  group('rekaman audio', () {
    test('kata ber-audio punya berkas normal dan lambat', () {
      final missing = <String>[];
      for (final w in all) {
        if (!w.hasAudio) continue;
        final n = File('${_audioDir.path}/${w.reading}.mp3');
        final s = File('${_audioDir.path}/${w.reading}_slow.mp3');
        if (!n.existsSync() || !s.existsSync()) missing.add(w.reading);
      }
      expect(
        missing,
        isEmpty,
        reason: '${missing.length} rekaman hilang, contoh: ${missing.take(5)}',
      );
    });

    test('kata tanpa audio memang tidak punya berkas', () {
      final wrong = all
          .where(
            (w) =>
                !w.hasAudio &&
                File('${_audioDir.path}/${w.reading}.mp3').existsSync(),
          )
          .map((w) => w.reading)
          .toList();
      expect(
        wrong,
        isEmpty,
        reason: 'tertandai tanpa audio padahal ada: $wrong',
      );
    });
  });

  group('pemilihan kata per tingkat', () {
    test('level N5 saja hanya menghasilkan kata N5', () {
      final pool = WordRepository.filterAvailable(
        all,
        _tenLetters,
        'hiragana',
        level: WordLevel.n5,
      );
      expect(pool, isNotEmpty);
      expect(pool.every((w) => w.level == 'N5'), isTrue);
    });

    test('switch other mati: tidak ada kata level kosong', () {
      final pool = WordRepository.filterAvailable(
        all,
        _tenLetters,
        'hiragana',
        level: WordLevel.n5n4n3,
        includeExtra: false,
      );
      expect(pool.every((w) => w.level.isNotEmpty), isTrue);
    });

    test('switch other hidup: kata level kosong ikut', () {
      final withExtra = WordRepository.filterAvailable(
        all,
        _tenLetters,
        'hiragana',
        includeExtra: true,
      );
      final without = WordRepository.filterAvailable(
        all,
        _tenLetters,
        'hiragana',
        includeExtra: false,
      );
      expect(withExtra.length, greaterThan(without.length));
    });

    test('N5-N3 mencakup lebih banyak kata daripada N5 saja', () {
      final n5 = WordRepository.filterAvailable(
        all,
        _tenLetters,
        'hiragana',
        level: WordLevel.n5,
      );
      final n3 = WordRepository.filterAvailable(
        all,
        _tenLetters,
        'hiragana',
        level: WordLevel.n5n4n3,
      );
      expect(n3.length, greaterThan(n5.length));
    });

    test('TIADA kata tanpa arti yang lolos ke pool mana pun', () {
      // 7.568 dari 7.826 kata pool lama tidak punya arti Indonesia maupun
      // Inggris. Kalau ikut masuk, latihan baca untuk huruf a-o/s-ta jadi
      // 903 soal dengan 590 soal tanpa arti.
      for (final includeExtra in [false, true]) {
        for (final type in ['hiragana', 'katakana', 'mixed']) {
          for (final level in WordLevel.values) {
            final pool = WordRepository.filterAvailable(
              all,
              _tenLetters,
              type,
              level: level,
              includeExtra: includeExtra,
            );
            final tanpa = pool.where((w) => !w.hasAnyMeaning).toList();
            expect(
              tanpa,
              isEmpty,
              reason:
                  'type=$type level=${level.name} '
                  'includeExtra=$includeExtra: '
                  '${tanpa.take(5).map((w) => w.text)}',
            );
          }
        }
      }

      final everyKana = allKana.map((kana) => kana.id).toSet();
      for (final type in ['hiragana', 'katakana', 'mixed']) {
        final pool = WordRepository.filterAvailable(
          all,
          everyKana,
          type,
          includeExtra: true,
        );
        expect(
          pool.where((word) => !word.hasAnyMeaning),
          isEmpty,
          reason: 'type=$type, huruf aktif seluruhnya',
        );
      }
    });
  });

  group('pemilihan kata memprioritaskan level rendah', () {
    test('kata belum pernah muncul, level terendah didahulukan', () async {
      await TestDb.reset();
      final active = _tenLetters;
      final pool = WordRepository.filterAvailable(all, active, 'hiragana');
      final picked = await WordRepository.instance.pick(pool, 5, _rng());
      expect(picked, hasLength(5));
      // Kalau ada kata N5 di pool, pilihan awal harus N5.
      final adaN5 = pool.any((w) => w.level == 'N5');
      if (adaN5) {
        expect(
          picked.first.level,
          'N5',
          reason:
              'level terendah harus didahulukan, dapat '
              '${picked.map((w) => "${w.reading}/${w.level}")}',
        );
      }
    });

    test('sesi tetap penuh walau huruf aktif sedikit', () async {
      await TestDb.reset();
      await repo.setActiveIds(
        hiraganaByRomaji([
          'a',
          'i',
          'u',
          'e',
          'o',
          'ka',
          'ki',
          'ku',
          'ke',
          'ko',
        ]).map((k) => k.id).toSet(),
      );
      await TestDb.markSeen(hiraganaList.take(5));
      // rootBundle tidak bisa dipakai di unit test, jadi suntik daftar kata.
      WordBank.instance.debugSet(all);
      final session = await buildReadingSession(type: 'hiragana', size: 20);
      expect(session, hasLength(20));
      expect(session.every((q) => q.options.contains(q.answer)), isTrue);
      expect(session.every((q) => q.options.length == 4), isTrue);
    });
  });
}

Set<String> get _tenLetters => hiraganaByRomaji([
  'a',
  'i',
  'u',
  'e',
  'o',
  'ka',
  'ki',
  'ku',
  'ke',
  'ko',
]).map((k) => k.id).toSet();

Random _rng() => Random(7);
