import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kana_quest/core/widgets/pill_choice.dart';
import 'package:kana_quest/features/practice/practice_screen.dart';
import 'package:kana_quest/features/words/words_screen.dart';

void main() {
  testWidgets('menu Practice hanya berisi latihan kana dan pil script bekerja',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PracticeScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Practice'), findsOneWidget);
    expect(find.text('Script'), findsOneWidget);
    expect(find.text('Flashcards'), findsOneWidget);
    expect(find.text('Quick quiz'), findsOneWidget);
    expect(find.text('Writing'), findsOneWidget);
    expect(find.text('Trace the character'), findsOneWidget);

    // Latihan kata pindah ke tab Words.
    expect(find.text('Reading practice'), findsNothing);
    expect(find.text('Meaning practice'), findsNothing);

    // Pilihan script memakai pil yang bisa diganti.
    final katakana = find.widgetWithText(PillChoice, 'Katakana');
    expect(katakana, findsOneWidget);
    await tester.tap(katakana);
    await tester.pump();
    expect(tester.widget<PillChoice>(katakana).selected, isTrue);

    // Semua menu tetap bisa dijangkau dengan scroll.
    for (final label in const [
      'Choose letters',
      'Recognition',
      'Kana → sound',
      'Sound → kana',
      'Look-alike drill',
    ]) {
      await tester.scrollUntilVisible(
        find.text(label),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(label), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('menu Words memuat latihan kata, filter, dan riwayat',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: WordsScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Words'), findsOneWidget);
    expect(find.text('Vocabulary'), findsOneWidget);
    expect(find.text('Reading practice'), findsOneWidget);
    expect(find.text('Meaning practice'), findsOneWidget);

    // Filter level kosakata berada sebelum daftar latihan.
    expect(
      tester.getTopLeft(find.text('All words')).dy,
      lessThan(tester.getTopLeft(find.text('Reading practice')).dy),
    );

    final n3 = find.widgetWithText(PillChoice, 'N3');
    await tester.tap(n3);
    await tester.pump();
    expect(tester.widget<PillChoice>(n3).selected, isTrue);

    for (final label in const [
      'Build the word: romaji',
      'Build the word: kana',
      'Word history',
    ]) {
      await tester.scrollUntilVisible(
        find.text(label),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(label), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
}
