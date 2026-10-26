import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kana_quest/app/app.dart';
import 'package:kana_quest/core/settings/app_settings.dart';
import 'package:kana_quest/features/practice/practice_screen.dart';
import 'package:kana_quest/features/profile/profile_screen.dart';
import 'package:kana_quest/features/words/words_screen.dart';

import 'helpers/test_db.dart';

Future<void> settle(WidgetTester tester, {int rounds = 20}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 60)),
    );
    await tester.pump(const Duration(milliseconds: 30));
  }
}

void main() {
  setUp(() async {
    await TestDb.reset();
    await repo.setActiveIds(activeVowelsAndK.map((k) => k.id).toSet());
    // Onboarding hanya untuk pengguna baru; tes ini membahas tab utama.
    await repo.setMeta('intro_done', '1');
    await AppSettings.instance.load();
    await AppSettings.instance.setThemeMode(ThemeMode.dark);
  });

  testWidgets('tab Kana, Practice, Words, dan Profile terbuka tanpa overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const KanaQuestApp());
    await settle(tester);

    // Judul layar + label navigasi, jadi lebih dari satu.
    expect(find.text('Kana'), findsWidgets);
    expect(find.text('Hiragana'), findsWidgets);
    // Baris kombinasi tetap dibangun di grid 5 kolom.
    expect(find.text('きゃ'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Practice'));
    await settle(tester);
    expect(find.text('Practice'), findsWidgets);
    expect(find.text('Flashcards'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Words'));
    await settle(tester);
    expect(find.text('Words'), findsWidgets);
    expect(find.text('Reading practice'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Profile'));
    await settle(tester);
    expect(find.text('Profile'), findsWidgets);
    expect(find.text('Daily streak'), findsOneWidget);
    expect(find.text('Milestones'), findsOneWidget);
    final profileScroll = find
        .descendant(
          of: find.byType(ProfileScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('Recent sessions'),
      300,
      scrollable: profileScroll,
    );
    expect(find.text('Recent sessions'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Kana'));
    await settle(tester);
    // Judul layar + label navigasi, jadi lebih dari satu.
    expect(find.text('Kana'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('konten tab lain bergulir di belakang navigasi transparan', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const KanaQuestApp());
    await settle(tester);

    for (final entry in [
      ('Practice', PracticeScreen),
      ('Words', WordsScreen),
      ('Profile', ProfileScreen),
    ]) {
      await tester.tap(find.byTooltip(entry.$1));
      await settle(tester);
      final list = find
          .descendant(
            of: find.byType(entry.$2),
            matching: find.byType(ListView),
          )
          .first;
      expect(
        tester.getRect(list).bottom,
        closeTo(640, 0.1),
        reason:
            '${entry.$1} harus menyisakan ruang agar konten terlihat '
            'di belakang navbar, bukan berhenti di atasnya',
      );
    }
  });
}
