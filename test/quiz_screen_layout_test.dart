import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kana_quest/core/settings/app_settings.dart';
import 'package:kana_quest/core/widgets/answer_option.dart';
import 'package:kana_quest/core/widgets/primary_button.dart';
import 'package:kana_quest/features/learn/quiz_question.dart';
import 'package:kana_quest/features/learn/quiz_screen.dart';
import 'package:kana_quest/features/learn/session_controller.dart';

import 'helpers/test_db.dart';

const _screen = Size(360, 640); // HP kecil

Future<void> settle(WidgetTester tester, {int rounds = 4}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 90)));
    await tester.pump(const Duration(milliseconds: 30));
  }
}

void main() {
  setUp(() async {
    await TestDb.reset();
    AppSettings.instance.autoPlay = false;
    await repo.setActiveIds(activeVowelsAndK.map((k) => k.id).toSet());
    await TestDb.markSeen(activeVowelsAndK);
  });

  testWidgets('opsi jawaban benar selalu terlihat di layar 360x640',
      (tester) async {
    tester.view.physicalSize = _screen;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        theme: null,
        home: QuizScreen(args: SessionArgs(type: 'hiragana')),
      ),
    );
    await settle(tester, rounds: 10);

    final rng = Random(3);
    final problems = <String>[];
    // ignore: avoid_print
    print('--- mulai sesi ---');

    for (var q = 0; q < 12; q++) {
      final maxBottom = _screen.height;

      final opts =
          tester.widgetList<AnswerOption>(find.byType(AnswerOption)).toList();
      if (opts.length != 4) {
        problems.add('soal $q: jumlah pilihan = ${opts.length}');
        break;
      }
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .whereType<String>()
          .toList();
      // ignore: avoid_print
      print('soal $q | ${texts.firstWhere((t) => t.contains('?'), orElse: () => '?')} '
          '| pilihan=${opts.map((o) => o.label).toList()} | bawah=${maxBottom.toStringAsFixed(0)}');
      // Kadang benar, kadang salah -> ikut menguji jalur retry/Again.
      await tester.tap(find.byType(AnswerOption).at(rng.nextInt(4)));
      await settle(tester);

      final afterAnswer =
          tester.widgetList<AnswerOption>(find.byType(AnswerOption)).toList();
      final correct =
          afterAnswer.where((o) => o.state == OptionState.correct).toList();
      final labels = afterAnswer.map((o) => o.label).toList();
      if (correct.length != 1) {
        problems.add('soal $q: opsi benar = ${correct.length}, labels=$labels');
      } else {
        final idx = afterAnswer.indexOf(correct.first);
        final r = tester.getRect(find.byType(AnswerOption).at(idx));
        if (r.bottom > maxBottom || r.top < 0) {
          problems.add('soal $q: "${correct.first.label}" TERPOTONG '
              'rect=$r batasBawah=$maxBottom');
        }
      }

      final next = find.text('Next');
      if (next.evaluate().isEmpty) {
        problems.add('soal $q: tombol Next tidak ditemukan');
        break;
      }
      await tester.tap(next);
      await settle(tester);

      if (find.byType(AnswerOption).evaluate().isEmpty) {
        break; // sesi habis
      }
    }

    // ignore: avoid_print
    print('MASALAH = $problems');
    expect(problems, isEmpty);
  });

  testWidgets('tap cepat pada pilihan dan Next tidak merusak state',
      (tester) async {
    tester.view.physicalSize = _screen;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: QuizScreen(args: SessionArgs(type: 'hiragana'))),
    );
    await settle(tester, rounds: 10);

    final problems = <String>[];

    for (var round = 0; round < 6; round++) {
      if (find.byType(AnswerOption).evaluate().isEmpty) break;
      // Double-tap pada pilihan yang sama tanpa menunggu.
      await tester.tap(find.byType(AnswerOption).at(0), warnIfMissed: false);
      await tester.tap(find.byType(AnswerOption).at(0), warnIfMissed: false);
      await settle(tester);

      final opts =
          tester.widgetList<AnswerOption>(find.byType(AnswerOption)).toList();
      if (opts.length != 4) {
        problems.add('round $round: pilihan setelah double-tap = ${opts.length}');
        break;
      }
      final correct =
          opts.where((o) => o.state == OptionState.correct).toList();
      if (correct.length != 1) {
        problems.add('round $round: opsi benar = ${correct.length}, '
            'labels=${opts.map((o) => o.label).toList()}');
      }
      if (find.text('Next').evaluate().isEmpty) break;
      // Triple-tap pada Next tanpa menunggu.
      await tester.tap(find.text('Next'), warnIfMissed: false);
      await tester.tap(find.text('Next'), warnIfMissed: false);
      await tester.tap(find.text('Next'), warnIfMissed: false);
      await settle(tester);

      final after =
          tester.widgetList<AnswerOption>(find.byType(AnswerOption)).toList();
      if (after.isEmpty) break;
      if (after.isNotEmpty && after.length != 4) {
        problems.add('round $round: pilihan setelah triple-Next = ${after.length}');
      }
    }

    // ignore: avoid_print
    print('MASALAH TAP = $problems');
    expect(problems, isEmpty);
  });

  for (final size in const [Size(360, 640), Size(412, 915)]) {
    testWidgets(
        'pilihan jauh dari Next dan tidak bergeser saat menjawab '
        '(${size.width.toInt()}x${size.height.toInt()})', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Jenis tetap supaya panjang prompt tidak mengubah jarak pilihan ke Next.
      await tester.pumpWidget(
        const MaterialApp(
          home: QuizScreen(
            args: SessionArgs(
              type: 'hiragana',
              quizKind: QuizKind.kanaToSound,
            ),
          ),
        ),
      );
      await settle(tester, rounds: 10);

      Rect lowest() {
        final rects = [
          for (var i = 0; i < 4; i++)
            tester.getRect(find.byType(AnswerOption).at(i)),
        ];
        return rects.reduce((a, b) => a.bottom > b.bottom ? a : b);
      }

      final before = lowest();
      await tester.tap(find.byType(AnswerOption).at(0));
      await settle(tester);
      final after = lowest();

      // Pilihan tidak loncat saat umpan balik muncul.
      expect(after.top, before.top);
      expect(after.bottom, before.bottom);

      // Ada jarak lega antara pilihan dan tombol Next.
      final next = tester.getRect(find.byType(PrimaryButton));
      expect(next.top - after.bottom, greaterThanOrEqualTo(60));
    });
  }
}
