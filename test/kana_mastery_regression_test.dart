import 'package:flutter_test/flutter_test.dart';
import 'package:kana_quest/data/models/kana_progress.dart';
import 'package:kana_quest/data/repositories/kana_repository.dart';

import 'helpers/test_db.dart';

void main() {
  setUp(TestDb.reset);

  test('jawaban salah tidak menurunkan huruf yang sudah mastered', () async {
    final kana = kanaByRomaji('se');
    final db = await TestDb.store;
    await db.insert(
      'kana_progress',
      KanaProgress(
        kanaId: kana.id,
        correctCount: 6,
        wrongCount: 1,
        consecutiveCorrect: 2,
        sessionsCorrect: 3,
        lastCorrectSessionId: 1,
        masteryLevel: 3,
      ).toMap(),
    );

    await KanaRepository.instance.recordAnswer(
      sessionId: 2,
      kana: kana,
      correct: false,
      fast: false,
    );

    final progress = (await KanaRepository.instance.loadProgress())[kana.id]!;
    expect(progress.isMastered, isTrue);
    expect(progress.masteryLevel, 3);
    expect(progress.wrongCount, 2);
  });
}
