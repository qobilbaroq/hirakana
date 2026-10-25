import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kana_quest/core/settings/app_settings.dart';
import 'package:kana_quest/core/widgets/kana_character.dart';
import 'package:kana_quest/core/widgets/primary_button.dart';
import 'package:kana_quest/data/repositories/word_repository.dart';
import 'package:kana_quest/data/seed/kana_data.dart';
import 'package:kana_quest/data/seed/word_data.dart';
import 'package:kana_quest/features/learn/session_controller.dart';
import 'package:kana_quest/features/words/build_questions.dart';
import 'package:kana_quest/features/words/build_word_screen.dart';

import 'helpers/test_db.dart';

const _screen = Size(360, 640); // HP kecil

Future<void> settle(WidgetTester tester, {int rounds = 10}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 90)));
    await tester.pump(const Duration(milliseconds: 30));
  }
}

/// Menekan potongan yang belum terpakai dengan label [label].
Future<void> tapTile(WidgetTester tester, String label) async {
  for (final element in find.byType(Opacity).evaluate()) {
    final opacity = element.widget as Opacity;
    if (opacity.opacity != 1.0) continue;
    final inside = find.descendant(
      of: find.byWidget(opacity),
      matching: find.text(label),
    );
    if (inside.evaluate().isEmpty) continue;
    final tile = find.byWidget(opacity);
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pump();
    return;
  }
  fail('potongan "$label" tidak ditemukan');
}

Future<void> tapAnyUnusedTile(WidgetTester tester) async {
  for (final element in find.byType(Opacity).evaluate()) {
    final opacity = element.widget as Opacity;
    if (opacity.opacity != 1.0) continue;
    final tile = find.byWidget(opacity);
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pump();
    return;
  }
  fail('tidak ada potongan tersisa');
}

void main() {
  late List<Word> bank;

  setUpAll(() {
    bank = WordBank.parse(File('assets/data/words.tsv').readAsStringSync());
  });

  setUp(() async {
    await TestDb.reset();
    await repo.setActiveIds(hiraganaList.map((k) => k.id).toSet());
    AppSettings.instance.autoPlay = false;
  });

  testWidgets('Build the word: romaji bisa disusun sampai benar',
      (tester) async {
    tester.view.physicalSize = _screen;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: BuildWordScreen(
          args: SessionArgs(type: 'hiragana'),
          direction: BuildDirection.toRomaji,
        ),
      ),
    );
    await settle(tester);

    // Huruf Jepang besar adalah teks soal.
    final prompt =
        tester.widget<KanaCharacter>(find.byType(KanaCharacter)).text;
    final word = bank.firstWhere((w) => w.text == prompt);
    final answer =
        alignedRomajiTiles(WordRepository.parse(prompt)!, word.reading)!;

    final check = find.widgetWithText(PrimaryButton, 'Check');
    expect(tester.widget<PrimaryButton>(check).onPressed, isNull,
        reason: 'Check harus mati sebelum kotak penuh');

    for (final label in answer) {
      await tapTile(tester, label);
    }

    expect(tester.widget<PrimaryButton>(check).onPressed, isNotNull);
    await tester.tap(check);
    await tester.pumpAndSettle();

    expect(find.text("Nice, that's right."), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Lepas widget supaya sesi tersimpan sebelum database di-reset.
    await tester.pumpWidget(const SizedBox());
    await settle(tester, rounds: 2);
  });

  testWidgets('Build the word: kana bisa diisi dan diperiksa', (tester) async {
    tester.view.physicalSize = _screen;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: BuildWordScreen(
          args: SessionArgs(type: 'hiragana'),
          direction: BuildDirection.toKana,
        ),
      ),
    );
    await settle(tester);

    final prompt = tester
        .widget<Text>(find.byWidgetPredicate(
            (w) => w is Text && w.style?.fontSize == 40 && w.data != null))
        .data!;
    expect(prompt, isNotEmpty);

    final check = find.widgetWithText(PrimaryButton, 'Check');
    var guard = 0;
    while (tester.widget<PrimaryButton>(check).onPressed == null &&
        guard++ < 20) {
      await tapAnyUnusedTile(tester);
    }

    expect(tester.widget<PrimaryButton>(check).onPressed, isNotNull,
        reason: 'Check harus aktif setelah semua kotak terisi');

    await tester.tap(check);
    await tester.pumpAndSettle();

    expect(
      find.text("Nice, that's right.").evaluate().isNotEmpty ||
          find.text('Not quite.').evaluate().isNotEmpty,
      isTrue,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await settle(tester, rounds: 2);
  });

  testWidgets('grid potongan muat tanpa scroll di layar 360x640',
      (tester) async {
    tester.view.physicalSize = _screen;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // Kata terpanjang di daftar: 7 potongan jawaban + 5 pengecoh = 12 kotak.
    final word = bank.firstWhere((w) => w.text == 'しんにゅうしゃいん');
    final question = buildQuestionFor(
      word: word,
      direction: BuildDirection.toKana,
      active: [...hiraganaList, ...katakanaList],
      partners: const {},
      rng: Random(1),
    )!;
    expect(question.slotCount, 7);
    expect(question.tiles.length, 12);

    await tester.pumpWidget(
      MaterialApp(
        home: BuildWordScreen(
          args: const SessionArgs(type: 'hiragana'),
          direction: BuildDirection.toKana,
          questions: [question],
        ),
      ),
    );
    await settle(tester);

    expect(tester.getSize(find.byType(Wrap).first).height,
        lessThanOrEqualTo(49),
        reason: '7 kotak jawaban harus tetap satu baris');

    // Potongan cukup besar untuk ibu jari walau 12 kotak (4 kolom x 3 baris).
    expect(tester.getSize(find.byType(Opacity).first).width,
        greaterThanOrEqualTo(58));

    final scrollable =
        tester.state<ScrollableState>(find.byType(Scrollable).first);
    expect(scrollable.position.maxScrollExtent, 0,
        reason: 'soal terpanjang harus muat tanpa scroll');
    expect(tester.takeException(), isNull);

    // Umpan balik setelah Check juga tidak boleh mendorong layar.
    for (final label in question.answerTiles) {
      await tapTile(tester, label);
    }
    final check = find.widgetWithText(PrimaryButton, 'Check');
    expect(tester.widget<PrimaryButton>(check).onPressed, isNotNull);
    await tester.tap(check);
    await tester.pumpAndSettle();

    final after =
        tester.state<ScrollableState>(find.byType(Scrollable).first);
    expect(after.position.maxScrollExtent, 0,
        reason: 'umpan balik setelah Check harus muat tanpa scroll');
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await settle(tester, rounds: 2);
  });
}
