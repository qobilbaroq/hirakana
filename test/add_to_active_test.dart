import 'package:flutter_test/flutter_test.dart';
import 'package:kana_quest/data/repositories/kana_repository.dart';
import 'package:kana_quest/data/seed/kana_data.dart';

import 'helpers/test_db.dart';

void main() {
  setUp(() async {
    await TestDb.reset();
  });

  test('script yang masih kosong: awalan 5 huruf ikut terisi', () async {
    // User sudah punya set hiragana, lalu mengetuk katakana untuk pertama kali.
    await repo.setActiveIds(hiraganaList.take(3).map((k) => k.id).toSet());
    final tapped = katakanaList[KanaRepository.starterCount];

    await repo.addToActive(tapped);

    final katakana = await repo.activeKana('katakana');
    expect(katakana.length, KanaRepository.starterCount + 1);
    expect(katakana.map((k) => k.id), contains(tapped.id));
    // Set hiragana tidak berubah.
    final hiragana = await repo.activeKana('hiragana');
    expect(hiragana.length, 3);
  });

  test('menambah huruf yang sudah aktif tidak menggandakan', () async {
    final first = hiraganaList.first;
    await repo.addToActive(first);
    await repo.addToActive(first);
    final active = await repo.activeKana('hiragana');
    expect(active.where((k) => k.id == first.id).length, 1);
    expect(active.length, KanaRepository.starterCount);
  });
}
