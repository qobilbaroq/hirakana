import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kana_quest/core/storage/local_database.dart';
import 'package:kana_quest/data/repositories/word_repository.dart';
import 'package:kana_quest/data/seed/word_data.dart';
import 'package:kana_quest/features/words/word_history_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/test_db.dart';

WordRecord record(
  String text, {
  int seen = 1,
  int correct = 0,
  int wrong = 0,
  int minutesAgo = 0,
}) =>
    WordRecord(
      word: Word(text, 'x', meaning: 'arti $text'),
      seenCount: seen,
      correctCount: correct,
      wrongCount: wrong,
      lastAt: DateTime(2026, 10, 19).subtract(Duration(minutes: minutesAgo)),
    );

void main() {
  group('WordRecord: status kata', () {
    test('sering salah: salah >= 2 dan tidak lebih sedikit dari benar', () {
      expect(record('a', seen: 3, correct: 1, wrong: 2).isStruggling, isTrue);
      expect(record('a', seen: 2, correct: 1, wrong: 1).isStruggling, isFalse);
      expect(record('a', seen: 6, correct: 4, wrong: 2).isStruggling, isFalse);
    });

    test('baru: muncul 1-2 kali', () {
      expect(record('a', seen: 2).isNew, isTrue);
      expect(record('a', seen: 3).isNew, isFalse);
    });

    test('hafal: benar >= 3 dan jauh lebih banyak dari salah', () {
      expect(record('a', seen: 3, correct: 3).isMastered, isTrue);
      expect(record('a', seen: 7, correct: 6, wrong: 1).isMastered, isTrue);
      expect(record('a', seen: 5, correct: 3, wrong: 2).isMastered, isFalse);
      expect(record('a', seen: 2, correct: 2).isMastered, isFalse);
    });
  });

  group('applyHistoryFilter', () {
    final all = [
      record('baru', seen: 1, correct: 1, minutesAgo: 1),
      record('salah1', seen: 4, correct: 1, wrong: 3, minutesAgo: 5),
      record('salah2', seen: 3, correct: 0, wrong: 2, minutesAgo: 2),
      record('hafal', seen: 5, correct: 5, minutesAgo: 9),
    ];

    List<String> texts(WordHistoryFilter f) =>
        [for (final r in applyHistoryFilter(all, f)) r.word.text];

    test('semua: urutan tetap seperti yang diberikan (terbaru dulu)', () {
      expect(texts(WordHistoryFilter.all),
          ['baru', 'salah1', 'salah2', 'hafal']);
    });

    test('sering salah: yang paling sering salah di atas', () {
      expect(texts(WordHistoryFilter.struggling), ['salah1', 'salah2']);
    });

    test('baru dan hafal', () {
      expect(texts(WordHistoryFilter.fresh), ['baru']);
      expect(texts(WordHistoryFilter.mastered), ['hafal']);
    });
  });

  group('riwayat di database', () {
    final words = [
      const Word('あい', 'ai', meaning: 'cinta'),
      const Word('あお', 'ao', meaning: 'biru'),
      const Word('いえ', 'ie', meaning: 'rumah'),
    ];

    setUp(() async {
      await TestDb.reset();
      WordBank.instance.debugSet(words);
    });

    test('recordResult menghitung muncul, benar, dan salah', () async {
      final repo = WordRepository.instance;
      await repo.recordResult('あい', correct: true);
      await repo.recordResult('あい', correct: false);
      await repo.recordResult('あい', correct: false);
      await repo.recordResult('あお', correct: true);

      final history = await repo.history();
      final ai = history.firstWhere((r) => r.word.text == 'あい');
      expect(ai.seenCount, 3);
      expect(ai.correctCount, 1);
      expect(ai.wrongCount, 2);
      expect(ai.isStruggling, isTrue);
      final ao = history.firstWhere((r) => r.word.text == 'あお');
      expect(ao.seenCount, 1);
      expect(ao.correctCount, 1);
      expect(ao.wrongCount, 0);
    });

    test('history: yang terbaru di atas, kata tak dikenal dilewati', () async {
      final repo = WordRepository.instance;
      await repo.recordResult('あい', correct: true);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await repo.recordResult('いえ', correct: true);
      await repo.recordResult('ぜんぜんない', correct: true); // tidak ada di daftar

      final history = await repo.history();
      expect(history.length, 2);
      expect(history.first.word.text, 'いえ');
    });

    test('markSeen lama tetap jalan dan tidak menghitung benar/salah', () async {
      final repo = WordRepository.instance;
      await repo.markSeen(['あい']);
      final r = (await repo.history()).single;
      expect(r.seenCount, 1);
      expect(r.correctCount, 0);
      expect(r.wrongCount, 0);
    });

    test('wordsFor mengikuti urutan teks dan melewati yang tak dikenal', () async {
      final result =
          await WordRepository.instance.wordsFor(['いえ', 'xyz', 'あい']);
      expect(result.map((w) => w.text), ['いえ', 'あい']);
    });
  });

  group('migrasi database 3 -> 4', () {
    test('kata lama tetap ada dan mulai dari benar 0 / salah 0', () async {
      await TestDb.init();
      final dir = Directory.systemTemp.createTempSync('kana_quest_db');
      final path = '${dir.path}/old.db';

      // Database versi 3 seperti yang dibuat app sebelum update ini.
      final old = await openDatabase(path, version: 3, onCreate: (db, _) async {
        await db.execute(
            'CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
        await db.execute('''CREATE TABLE confusions (
          a_id TEXT NOT NULL, b_id TEXT NOT NULL,
          count INTEGER NOT NULL DEFAULT 1, last_at INTEGER NOT NULL,
          PRIMARY KEY (a_id, b_id))''');
        await db.execute('''CREATE TABLE word_history (
          text TEXT PRIMARY KEY,
          seen_count INTEGER NOT NULL DEFAULT 1,
          last_at INTEGER NOT NULL)''');
        await db.insert(
            'word_history', {'text': 'あい', 'seen_count': 5, 'last_at': 1000});
      });
      await old.close();

      await LocalDatabase.instance.debugUseDatabase(path);
      final db = await LocalDatabase.instance.database;
      final rows = await db.query('word_history');
      expect(rows.single['seen_count'], 5);
      expect(rows.single['correct_count'], 0);
      expect(rows.single['wrong_count'], 0);

      await LocalDatabase.instance.debugUseDatabase(inMemoryDatabasePath);
      dir.deleteSync(recursive: true);
    });
  });
}
