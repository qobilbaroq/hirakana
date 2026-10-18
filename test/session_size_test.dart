import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kana_quest/core/settings/app_settings.dart';
import 'package:kana_quest/features/learn/session_controller.dart';

import 'helpers/test_db.dart';

void main() {
  setUp(TestDb.reset);

  const vowels = ['a', 'i', 'u', 'e', 'o'];

  Future<void> seed(List<String> active) async {
    await repo.setActiveIds(hiraganaByRomaji(active).map((k) => k.id).toSet());
    await TestDb.markSeen(hiraganaByRomaji(active));
  }

  group('AppSettings.sessionSize', () {
    test('minimal 10 dan maksimal 60', () async {
      final s = AppSettings.instance;
      await s.setSessionSize(5);
      expect(s.sessionSize, 10);
      await s.setSessionSize(200);
      expect(s.sessionSize, AppSettings.maxSessionSize);
      await s.setSessionSize(25);
      expect(s.sessionSize, 25);
      await s.setSessionSize(10); // kembalikan default untuk test lain
    });

    test('tersimpan dan dimuat lagi', () async {
      final s = AppSettings.instance;
      await s.setSessionSize(30);
      s.sessionSize = 10;
      await s.load();
      expect(s.sessionSize, 30);
      await s.setSessionSize(10);
    });
  });

  group('buildQueue fillToSize', () {
    test('tanpa fillToSize: tidak diulang (perilaku lama)', () async {
      await seed(vowels);
      final q = await repo.buildQueue(type: 'hiragana', size: 20);
      expect(q.length, 5);
    });

    test('dengan fillToSize: huruf diulang rata sampai jumlahnya tercapai', () async {
      await seed(vowels);
      final q = await repo.buildQueue(
          type: 'hiragana', size: 20, fillToSize: true, rng: Random(4));
      expect(q.length, 20);
      final counts = <String, int>{};
      for (final k in q) {
        counts[k.id] = (counts[k.id] ?? 0) + 1;
      }
      expect(counts.length, 5);
      expect(counts.values.every((c) => c == 4), isTrue, reason: '$counts');
      for (var i = 1; i < q.length; i++) {
        expect(q[i].id, isNot(q[i - 1].id), reason: 'huruf sama berurutan di $i');
      }
    });

    test('ukuran tidak habis dibagi jumlah huruf tetap tepat', () async {
      await seed(vowels);
      final q = await repo.buildQueue(
          type: 'hiragana', size: 12, fillToSize: true, rng: Random(8));
      expect(q.length, 12);
    });
  });

  group('SessionController dengan sesi panjang', () {
    test('progres penuh walau huruf berulang', () async {
      await seed(vowels);
      await AppSettings.instance.setSessionSize(20);
      addTearDown(() => AppSettings.instance.setSessionSize(10));

      final c = SessionController(
          mode: 'quiz', args: const SessionArgs(type: 'hiragana'));
      await c.start();
      expect(c.total, 20);
      expect(c.queue.length, 20);

      while (!c.finished) {
        await c.answer(true);
      }
      expect(c.completed, 20);
      expect(c.progress, 1.0);
      expect(c.correct, 20);
    });

    test('Again per slot: huruf yang sama di slot lain tidak ikut kehabisan ulangan', () async {
      await seed(vowels);
      await AppSettings.instance.setSessionSize(15);
      addTearDown(() => AppSettings.instance.setSessionSize(10));

      final c = SessionController(
          mode: 'quiz', args: const SessionArgs(type: 'hiragana'));
      await c.start();
      var guard = 0;
      var first = true;
      while (!c.finished && guard++ < 200) {
        // Jawab salah sekali di soal pertama, sisanya benar.
        await c.answer(!first);
        first = false;
      }
      expect(c.finished, isTrue);
      expect(c.completed, c.total);
    });
  });
}
