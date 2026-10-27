import 'package:flutter_test/flutter_test.dart';
import 'package:kana_quest/data/models/kana_progress.dart';
import 'package:sqflite/sqflite.dart';

import 'helpers/test_db.dart';

void main() {
  setUp(TestDb.reset);

  test(
    'antrean membatasi huruf mastered hingga sekitar seperempat sesi',
    () async {
      final active = hiraganaByRomaji([
        'a',
        'i',
        'u',
        'e',
        'o',
        'ka',
        'ki',
        'ku',
      ]);
      await repo.setActiveIds(active.map((k) => k.id).toSet());
      await TestDb.markSeen(active);

      final db = await TestDb.store;
      final mastered = active.take(4).toList();
      for (final kana in mastered) {
        await db.insert(
          'kana_progress',
          KanaProgress(
            kanaId: kana.id,
            sessionsCorrect: 3,
            consecutiveCorrect: 2,
            lastReviewedAt: DateTime.now(),
            nextReviewAt: DateTime.now().add(const Duration(days: 14)),
            masteryLevel: 3,
          ).toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      final queue = await repo.buildQueue(type: 'hiragana', size: 8);
      final masteredCount = queue
          .where((kana) => mastered.contains(kana))
          .length;

      expect(queue.length, 6);
      expect(masteredCount, 2);
      expect(
        queue.where((kana) => !mastered.contains(kana)).toSet(),
        active.skip(4).toSet(),
      );
    },
  );

  test('sesi panjang mengisi slot ulang dengan huruf non-mastered', () async {
    final active = hiraganaByRomaji([
      'a',
      'i',
      'u',
      'e',
      'o',
      'ka',
      'ki',
      'ku',
    ]);
    await repo.setActiveIds(active.map((k) => k.id).toSet());
    await TestDb.markSeen(active);

    final db = await TestDb.store;
    for (final kana in active.take(4)) {
      await db.insert(
        'kana_progress',
        KanaProgress(
          kanaId: kana.id,
          sessionsCorrect: 3,
          consecutiveCorrect: 2,
          lastReviewedAt: DateTime.now(),
          nextReviewAt: DateTime.now().add(const Duration(days: 14)),
          masteryLevel: 3,
        ).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    final queue = await repo.buildQueue(
      type: 'hiragana',
      size: 20,
      fillToSize: true,
    );
    final masteredCount = queue
        .where((kana) => active.take(4).contains(kana))
        .length;

    expect(queue.length, 20);
    expect(masteredCount, 4);
    expect(masteredCount, lessThanOrEqualTo(20 ~/ 4));
  });
}
