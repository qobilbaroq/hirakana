import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kana_quest/app/app.dart';
import 'package:kana_quest/app/theme/app_colors.dart';
import 'package:kana_quest/core/settings/app_settings.dart';
import 'package:kana_quest/core/widgets/kana_group_row.dart';

import 'helpers/test_db.dart';

Future<void> settle(WidgetTester tester, {int rounds = 20}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 60)),
    );
    await tester.pump(const Duration(milliseconds: 30));
  }
}

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  setUp(() async {
    await TestDb.reset();
    await repo.setActiveIds(activeVowelsAndK.map((k) => k.id).toSet());
    await repo.setMeta('intro_done', '1');
    await AppSettings.instance.load();
  });

  test('teks light mode memenuhi kontras 4,5:1', () {
    addTearDown(() => AppColors.isDark = false);
    AppColors.isDark = false;
    final top = AppColors.backgroundGradient.colors.first;
    expect(
      _contrast(AppColors.onGradientMuted, top),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(AppPalette.light.clay, AppPalette.light.paper),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('jumlah kolom grid kana berkurang saat teks membesar', () {
    // Lebar area grid = lebar layar - 40.
    expect(kanaGridColumns(width: 350, textScale: 1), 5);
    expect(kanaGridColumns(width: 280, textScale: 1), 5);
    expect(kanaGridColumns(width: 350, textScale: 2), 3);
    expect(kanaGridColumns(width: 280, textScale: 2), 3);
    expect(kanaGridColumns(width: 240, textScale: 1), 4);
  });

  for (final width in [390.0, 360.0, 320.0]) {
    testWidgets('grid Kana tanpa overflow di teks 200% (lebar $width)', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1.0;
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      await tester.pumpWidget(const KanaQuestApp());
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('あ'), findsWidgets);
    });
  }

  testWidgets('navigasi bawah punya label terlihat', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const KanaQuestApp());
    await settle(tester);

    // Tab lain di-offstage oleh IndexedStack, jadi satu-satunya teks ini
    // adalah label di navigasi.
    expect(find.text('Practice'), findsOneWidget);
    expect(find.text('Words'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
