import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kana_quest/data/repositories/word_repository.dart';
import 'package:kana_quest/data/seed/kana_data.dart';
import 'package:kana_quest/data/seed/word_data.dart';

/// Menguji kosakata berkelompok (N5–N4 dan N3) di assets/data/words.tsv:
/// setiap kata kurasi punya arti Indonesia, tingkat, kategori, dan suara.
void main() {
  late List<Word> all;
  late List<Word> curated;

  setUpAll(() {
    all = WordBank.parse(File('assets/data/words.tsv').readAsStringSync());
    curated = all.where((w) => w.level.isNotEmpty).toList();
  });

  group('parser words.tsv', () {
    test('baris lama (4 kolom) tetap terbaca, tanpa tingkat/kategori', () {
      final r = WordBank.parse('あい\tai\t1\tcinta\n');
      expect(r.single.meaning, 'cinta');
      expect(r.single.level, '');
      expect(r.single.category, '');
    });

    test('baris baru (6 kolom) terbaca lengkap', () {
      final r = WordBank.parse('たべもの\ttabemono\t1\tmakanan\tn5n4\tMakanan\n');
      expect(r.single.level, 'n5n4');
      expect(r.single.category, 'Makanan');
      expect(r.single.meaning, 'makanan');
    });

    test('label tingkat', () {
      expect(vocabLevelLabel('n5n4'), 'N5–N4');
      expect(vocabLevelLabel('n3'), 'N3');
    });
  });

  group('kosakata kurasi', () {
    test('ada cukup banyak untuk setiap tingkat', () {
      for (final l in vocabLevels) {
        final n = curated.where((w) => w.level == l.$1).length;
        expect(n, greaterThan(200), reason: 'tingkat ${l.$2} hanya $n kata');
      }
    });

    test('hanya tingkat yang dikenal, dan kategori tidak kosong', () {
      final ids = vocabLevels.map((l) => l.$1).toSet();
      for (final w in curated) {
        expect(ids.contains(w.level), isTrue,
            reason: 'tingkat tak dikenal: ${w.text} -> ${w.level}');
        expect(w.category, isNotEmpty, reason: 'tanpa kategori: ${w.text}');
      }
    });

    test('setiap kata punya arti Indonesia', () {
      for (final w in curated) {
        expect(w.meaning, isNotEmpty, reason: 'tanpa arti: ${w.text}');
      }
    });

    test('setiap kata bisa dibaca app dan satu script saja', () {
      for (final w in curated) {
        final pieces = WordRepository.parse(w.text);
        expect(pieces, isNotNull, reason: 'karakter tak dikenal: ${w.text}');
        final scripts = {
          for (final p in pieces!)
            if (p.kana != null) p.kana!.type
        };
        expect(scripts.length, 1, reason: 'campur script: ${w.text}');
      }
    });

    test('setiap kata punya suara normal dan lambat', () {
      for (final w in curated) {
        expect(w.hasAudio, isTrue, reason: 'kolom audio 0: ${w.text}');
        expect(File('assets/audio/words/${w.reading}.mp3').existsSync(), isTrue,
            reason: 'suara hilang: ${w.text} (${w.reading})');
        expect(
            File('assets/audio/words/${w.reading}_slow.mp3').existsSync(), isTrue,
            reason: 'suara lambat hilang: ${w.text} (${w.reading})');
      }
    });

    test('tidak ada kata kurasi ganda', () {
      final seen = <String>{};
      for (final w in curated) {
        expect(seen.add(w.text), isTrue, reason: 'ganda: ${w.text}');
      }
    });
  });

  group('filter tingkat', () {
    final everything = allKana.map((k) => k.id).toSet();

    test('level null = semua kata, level terisi = hanya kelompok itu', () {
      final semua =
          WordRepository.filterAvailable(all, everything, 'mixed');
      final n5 = WordRepository.filterAvailable(all, everything, 'mixed',
          level: 'n5n4');
      final n3 = WordRepository.filterAvailable(all, everything, 'mixed',
          level: 'n3');
      expect(n5, isNotEmpty);
      expect(n3, isNotEmpty);
      expect(n5.every((w) => w.level == 'n5n4'), isTrue);
      expect(n3.every((w) => w.level == 'n3'), isTrue);
      // Semua kata sudah diberi tingkat, jadi "semua" tepat sama dengan
      // gabungan N5-N4 + N3. Sebelumnya di sini dipakai `greaterThan`
      // karena masih ada kata tanpa tingkat; sekarang memakai kesamaan
      // supaya kata yang somehow luput dari giveiran akan caught.
      expect(semua.length, n5.length + n3.length);
      expect(all.every((w) => w.level.isNotEmpty), isTrue,
          reason: 'ada kata tanpa tingkat: '
              '${all.where((w) => w.level.isEmpty).take(5).map((w) => w.text)}');
    });

    test('kata hanya muncul kalau semua hurufnya aktif', () {
      final vowels = {
        for (final k in hiraganaList)
          if (k.group == 'vowels') k.id
      };
      final r = WordRepository.filterAvailable(all, vowels, 'hiragana',
          level: 'n5n4');
      for (final w in r) {
        for (final k in WordRepository.kanaOf(w.text)) {
          expect(vowels.contains(k.id), isTrue, reason: w.text);
        }
      }
    });
  });
}
