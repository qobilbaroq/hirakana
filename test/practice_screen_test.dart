import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kana_quest/features/practice/practice_screen.dart';

void main() {
  testWidgets('menu Practice tersusun rapi dan filternya bekerja',
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
    expect(find.text('Writing'), findsOneWidget);
    expect(find.text('Words'), findsOneWidget);
    expect(find.text('Trace the character'), findsOneWidget);
    expect(find.text('Reading practice'), findsOneWidget);

    // Filter kosakata berada tepat sebelum daftar latihan kata.
    expect(
      tester.getTopLeft(find.text('All words')).dy,
      lessThan(tester.getTopLeft(find.text('Reading practice')).dy),
    );

    // Filter level bisa dipilih.
    await tester.tap(find.widgetWithText(ChoiceChip, 'N3'));
    await tester.pump();
    expect(
      tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'N3')).selected,
      isTrue,
    );

    // Semua menu bisa dijangkau dengan scroll.
    for (final label in const [
      'Meaning practice',
      'Build the word: romaji',
      'Build the word: kana',
      'Word history',
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
}
