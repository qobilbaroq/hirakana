import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kana_quest/core/settings/app_settings.dart';
import 'package:kana_quest/core/widgets/answer_option.dart';
import 'package:kana_quest/data/repositories/kana_repository.dart';
import 'package:kana_quest/data/seed/kana_data.dart';
import 'package:kana_quest/data/seed/word_data.dart';
import 'package:kana_quest/features/learn/session_controller.dart';
import 'package:kana_quest/features/words/word_practice_screen.dart';

import 'helpers/test_db.dart';

const _screen = Size(360, 640);

Future<void> settle(WidgetTester tester, {int rounds = 10}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 90)));
    await tester.pump(const Duration(milliseconds: 30));
  }
}

void main() {
  final repo = KanaRepository.instance;
  late List<Word> bank;

  setUpAll(() {
    bank = WordBank.parse(File('assets/data/words.tsv').readAsStringSync());
    WordBank.instance.debugSet(bank);
  });

  setUp(() async {
    await TestDb.reset();
    await repo.setActiveIds(hiraganaList.map((k) => k.id).toSet());
    AppSettings.instance.autoPlay = false;
    AppSettings.instance.showMeaning = true;
  });

  testWidgets(
      'Reading feedback: arti ukuran besar dan romaji di bawahnya, tanpa alert "nice that right", tanpa kana di feedback',
      (tester) async {
    tester.view.physicalSize = _screen;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: WordPracticeScreen(
          args: SessionArgs(type: 'hiragana', onlyTexts: ['あい']),
        ),
      ),
    );
    await settle(tester);

    // Jawaban benar untuk 「あい」 adalah 'ai', artinya 'cinta'.
    final aiOption = find.widgetWithText(AnswerOption, 'ai');
    expect(aiOption, findsOneWidget);

    await tester.tap(aiOption);
    await tester.pumpAndSettle();

    // Alert "Nice, that's right." harus tidak ada.
    expect(find.text("Nice, that's right."), findsNothing);
    expect(find.text("Nice, that's right"), findsNothing);

    // Feedback menampilkan arti "cinta" dan romaji "ai" di bawahnya.
    expect(find.text('cinta'), findsOneWidget);
    expect(find.text('ai'), findsWidgets); // di option dan di feedback

    // Cek bahwa style arti memiliki font size besar (>= 20).
    final artiWidget = tester.widget<Text>(find.text('cinta'));
    expect(artiWidget.style?.fontSize, greaterThanOrEqualTo(20));

    // Kana 「あい」 hanya ada 1 di card utama (tidak diduplikasi di feedback).
    expect(find.text('あい'), findsOneWidget);

    // Lepas widget supaya sesi tersimpan.
    await tester.pumpWidget(const SizedBox());
    await settle(tester, rounds: 2);
  });

  testWidgets('Reading feedback saat salah: ada "Not quite.", arti, dan romaji',
      (tester) async {
    tester.view.physicalSize = _screen;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: WordPracticeScreen(
          args: SessionArgs(type: 'hiragana', onlyTexts: ['あい']),
        ),
      ),
    );
    await settle(tester);

    // Cari opsi yang salah (bukan 'ai').
    final wrongOption = find.byWidgetPredicate(
      (widget) => widget is AnswerOption && widget.label != 'ai',
    );
    expect(wrongOption, findsWidgets);

    await tester.tap(wrongOption.first);
    await tester.pumpAndSettle();

    // Alert salah harus muncul.
    expect(find.text('Not quite.'), findsOneWidget);
    expect(find.text("Nice, that's right."), findsNothing);

    // Tetap menampilkan arti dan cara baca romaji yang benar.
    expect(find.text('cinta'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await settle(tester, rounds: 2);
  });
}
