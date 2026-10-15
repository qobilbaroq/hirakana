import 'package:flutter_test/flutter_test.dart';
import 'package:kana_quest/features/learn/session_controller.dart';

import 'helpers/test_db.dart';

/// Seed huruf aktif + progres.
Future<void> seed({required List<String> active, int seenCount = 0}) async {
  final ids = hiraganaByRomaji(active).map((k) => k.id).toSet();
  await repo.setActiveIds(ids);
  if (seenCount > 0) await TestDb.markSeen(hiraganaByRomaji(active).take(seenCount));
}

void main() {
  setUp(TestDb.reset);

  group('buildQueue: urutan diacak', () {
    test('urutan bervariasi antar pemanggilan', () async {
      await seed(active: ['a', 'i', 'u', 'e', 'o', 'ka', 'ki', 'ku', 'ke', 'ko'],
          seenCount: 10);

      final orders = <String>{};
      for (var i = 0; i < 40; i++) {
        final q = await repo.buildQueue(type: 'hiragana');
        orders.add(q.map((k) => k.id).join(','));
      }
      // 10! urutan; 40 sampel harus menghasilkan lebih dari satu susunan.
      expect(orders.length, greaterThan(5),
          reason: 'urutan selalu sama antar sesi: $orders');
    });

    test('anggota himpunan benar dan tidak ada duplikat', () async {
      final active = ['a', 'i', 'u', 'e', 'o', 'ka', 'ki', 'ku', 'ke', 'ko'];
      await seed(active: active, seenCount: 10);
      final expected = hiraganaByRomaji(active).map((k) => k.id).toSet();

      for (var i = 0; i < 20; i++) {
        final q = await repo.buildQueue(type: 'hiragana');
        expect(q.length, 10);
        expect(q.map((k) => k.id).toSet(), expected);
        expect(q.map((k) => k.id).toSet().length, q.length,
            reason: 'huruf dobel di antrean');
      }
    });

    test('huruf yang sama tidak pernah dua kali berturut-turut', () async {
      await seed(active: ['a', 'i', 'u', 'e', 'o', 'ka', 'ki', 'ku', 'ke', 'ko'],
          seenCount: 10);
      for (var i = 0; i < 60; i++) {
        final q = await repo.buildQueue(type: 'hiragana');
        for (var j = 1; j < q.length; j++) {
          expect(q[j].id, isNot(q[j - 1].id),
              reason: 'berurutan sama di posisi $j: ${q.map((k) => k.id).toList()}');
        }
      }
    });

    test('shuffle:false mempertahankan urutan dataset', () async {
      await seed(active: ['a', 'i', 'u', 'e', 'o'], seenCount: 5);
      final q = await repo.buildQueue(type: 'hiragana', shuffle: false);
      expect(q.map((k) => k.character).toList(), ['あ', 'い', 'う', 'え', 'お']);
    });
  });

  group('buildQueue: prioritas huruf tetap dipertahankan', () {
    test('huruf jatuh tempo lebih dulu dipilih saat huruf aktif > ukuran',
        () async {
      // 12 huruf aktif, sesi 5: 5 yang paling sering salah harus terpilih.
      final all = hiraganaByRomaji([
        'a', 'i', 'u', 'e', 'o', 'ka', 'ki', 'ku', 'ke', 'ko', 'sa', 'shi',
      ]);
      await repo.setActiveIds(all.map((k) => k.id).toSet());
      await TestDb.markSeen(all);

      // Tandai 5 huruf sebagai "due" dengan banyak salah.
      final db = await TestDb.store;
      for (final k in all.take(5)) {
        await db.update(
          'kana_progress',
          {'wrong_count': 9, 'next_review_at': 0},
          where: 'kana_id = ?',
          whereArgs: [k.id],
        );
      }

      for (var i = 0; i < 10; i++) {
        final q = await repo.buildQueue(type: 'hiragana', size: 5);
        expect(q.length, 5);
        expect(q.map((k) => k.id).toSet(),
            all.take(5).map((k) => k.id).toSet(),
            reason: 'huruf yang sering salah harus masuk, dapat ${q.map((k) => k.id).toList()}');
      }
    });
  });

  group('SessionController: pengecualian flashcard', () {
    test('sesi pertama flashcard tetap berurutan (あ い う え お)', () async {
      await seed(active: ['a', 'i', 'u', 'e', 'o']); // belum pernah dilihat
      final s = SessionController(
          mode: 'flashcard', args: const SessionArgs(type: 'hiragana'));
      await s.start();
      expect(s.queue.map((k) => k.character).toList(),
          ['あ', 'い', 'う', 'え', 'お']);
    });

    test('kuis SELALU diacak walau belum pernah dilihat', () async {
      await seed(active: ['a', 'i', 'u', 'e', 'o']);
      // Kuis hanya mengambil huruf yang sudah dilihat; tandai sebagai dilihat
      // tapi tanpa Changing urutan dataset.
      await TestDb.markSeen(hiraganaByRomaji(['a', 'i', 'u', 'e', 'o']));

      final orders = <String>{};
      for (var i = 0; i < 40; i++) {
        final s = SessionController(
            mode: 'quiz', args: const SessionArgs(type: 'hiragana'));
        await s.start();
        orders.add(s.queue.map((k) => k.id).join(','));
      }
      expect(orders.length, greaterThan(3),
          reason: 'kuis harus selalu diacak penuh: $orders');
    });

    test('flashcard setelah ada yang dilihat juga diacak', () async {
      await seed(active: ['a', 'i', 'u', 'e', 'o'], seenCount: 5);
      final orders = <String>{};
      for (var i = 0; i < 40; i++) {
        final s = SessionController(
            mode: 'flashcard', args: const SessionArgs(type: 'hiragana'));
        await s.start();
        orders.add(s.queue.map((k) => k.id).join(','));
      }
      expect(orders.length, greaterThan(3));
    });
  });
}