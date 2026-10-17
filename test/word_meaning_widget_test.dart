import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kana_quest/app/theme/app_theme.dart';
import 'package:kana_quest/core/settings/app_settings.dart';
import 'package:kana_quest/core/widgets/answer_option.dart';
import 'package:kana_quest/data/seed/kana_data.dart';
import 'package:kana_quest/data/seed/word_data.dart';
import 'package:kana_quest/features/learn/session_controller.dart';
import 'package:kana_quest/features/words/word_practice_screen.dart';

import 'helpers/test_db.dart';

const _screen = Size(360, 720);

// 'あか' hanya memakai a + ka, keduanya ada di set huruf aktif.
Word _word({
  String meaning = 'merah',
  String meaningEn = 'red',
  String kanji = '赤',
}) =>
    Word('あか', 'aka', meaning: meaning, hasAudio: false,
        meaningEn: meaningEn, level: 'N5', kanji: kanji);

Future<void> pumpScreen(WidgetTester tester, Word w) async {
  AppSettings.instance.autoPlay = false; // jangan sentuh audio di test
  // Pakai kata yang diminta test ini (bukan milik setUp).
  WordBank.instance.debugSet([w]);
  await tester.pumpWidget(MaterialApp(
    theme: buildAppTheme(Brightness.light),
    home: const WordPracticeScreen(args: SessionArgs(type: 'hiragana')),
  ));
  await settle(tester, rounds: 10);
}

Future<void> settle(WidgetTester tester, {int rounds = 4}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 80)));
    await tester.pump(const Duration(milliseconds: 30));
  }
}

void main() {
  setUp(() async {
    await TestDb.reset();
    WordBank.instance.debugSet([_word()]);
    final ids = hiraganaByRomaji(
            ['a', 'i', 'u', 'e', 'o', 'ka', 'ki', 'ku', 'ke', 'ko'])
        .map((k) => k.id)
        .toSet();
    await repo.setActiveIds(ids);
    await TestDb.markSeen(hiraganaList.take(5));
    // Sesi 1 soal supaya yang tampil pasti soal kata, bukan huruf/rangkaian
    // (soal diacak urutannya).
    AppSettings.instance.sessionSize = 1;
  });

  testWidgets('arti Bahasa Indonesia tampil setelah menjawab SALAH',
      (tester) async {
    tester.view.physicalSize = _screen;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    AppSettings.instance.showMeaning = true;
    await pumpScreen(tester, _word());
    // belum menjawab -> belum ada arti
    expect(find.text('merah'), findsNothing);

    await tester.tap(find.byType(AnswerOption).last);
    await settle(tester);

    expect(find.text('merah'), findsOneWidget);
    expect(find.text('赤'), findsOneWidget); // kanji kecil
  });

  testWidgets('arti Inggris tampil dengan label EN kalau Indonesia kosong',
      (tester) async {
    tester.view.physicalSize = _screen;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    AppSettings.instance.showMeaning = true;
    await pumpScreen(tester, _word(meaning: '', meaningEn: 'red'));
    await tester.tap(find.byType(AnswerOption).last);
    await settle(tester);

    expect(find.text('red'), findsOneWidget);
    expect(find.text('EN'), findsOneWidget);
  });

  testWidgets('toggle Show meaning mati -> arti tidak tampil', (tester) async {
    tester.view.physicalSize = _screen;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    AppSettings.instance.showMeaning = false;
    await pumpScreen(tester, _word());
    await tester.tap(find.byType(AnswerOption).last);
    await settle(tester);

    expect(find.text('merah'), findsNothing);
    expect(find.text('EN'), findsNothing);
  });

  test('displayMeaning memilih Indonesia dulu', () {
    expect(_word().displayMeaning, 'merah');
    expect(_word(meaning: '').displayMeaning, 'red');
  });

  test('hasAnyDefinition benar untuk kata tanpa arti', () {
    expect(_word(meaning: '', meaningEn: '').hasAnyMeaning, isFalse);
    expect(_word(meaning: '', meaningEn: 'red').hasAnyMeaning, isTrue);
  });
}