import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kana_quest/core/widgets/kana_character.dart';
import 'package:kana_quest/core/widgets/primary_button.dart';
import 'package:kana_quest/data/seed/kana_data.dart';
import 'package:kana_quest/features/learn/session_controller.dart';
import 'package:kana_quest/features/writing/kana_tracing_canvas.dart';
import 'package:kana_quest/features/writing/writing_screen.dart';

import 'helpers/test_db.dart';

/// Lebar 411 (bukan 360) karena font pengujian Flutter membuat setiap huruf
/// selebar font-size; label lama "Try again" jadi 127 px dan memicu overflow
/// yang tidak terjadi dengan Roboto di perangkat.
const _screen = Size(411, 731);

Future<void> settle(WidgetTester tester, {int rounds = 10}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 90)));
    await tester.pump(const Duration(milliseconds: 30));
  }
}

void main() {
  setUp(() async {
    await TestDb.reset();
    await repo.setActiveIds(activeVowelsAndK.map((k) => k.id).toSet());
  });

  testWidgets('romaji huruf contoh baru tampil setelah Check',
      (tester) async {
    tester.view.physicalSize = _screen;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: WritingScreen(args: SessionArgs(type: 'hiragana')),
      ),
    );
    await settle(tester);

    final example = tester.widget<KanaCharacter>(find.byType(KanaCharacter));
    final kana = hiraganaList.firstWhere((k) => k.character == example.text);

    // Sebelum Check: hanya ajakan menebak, romaji masih disembunyikan.
    expect(find.text('Guess the reading'), findsOneWidget);
    expect(find.text(kana.romaji), findsNothing);

    // Satu goresan supaya tombol Check aktif.
    await tester.drag(find.byType(KanaTracingCanvas), const Offset(60, 40));
    await tester.pump();
    await tester.tap(find.widgetWithText(PrimaryButton, 'Check'));
    await tester.pumpAndSettle();

    // Sesudah Check: romaji terbuka, tanpa overflow.
    expect(find.text(kana.romaji), findsOneWidget);
    expect(find.text('Guess the reading'), findsNothing);
    expect(tester.takeException(), isNull);

    // Lepas widget supaya sesi tersimpan sebelum database di-reset.
    await tester.pumpWidget(const SizedBox());
    await settle(tester, rounds: 2);
  });
}
