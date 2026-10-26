import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kana_quest/app/app.dart';
import 'package:kana_quest/core/settings/app_settings.dart';
import 'package:kana_quest/data/repositories/kana_repository.dart';

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
    // Database kosong: tidak ada intro_done, seperti install baru.
    await TestDb.reset();
    await AppSettings.instance.load();
  });

  testWidgets('install baru: onboarding muncul lewat router tanpa crash', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const KanaQuestApp());
    await settle(tester);

    // Sebelum perbaikan, pushNamed<OnboardingResult> melempar cast error
    // karena router mengembalikan MaterialPageRoute<void>.
    expect(tester.takeException(), isNull);
    expect(find.text('Learn Hiragana & Katakana'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await settle(tester);
    expect(tester.takeException(), isNull);
    final introDone = await tester.runAsync(
      () => KanaRepository.instance.getMeta('intro_done'),
    );
    expect(introDone, '1');
    expect(find.text('Learn Hiragana & Katakana'), findsNothing);
  });

  testWidgets('tema bawaan mengikuti sistem', (tester) async {
    expect(AppSettings.instance.themeMode, ThemeMode.system);
  });
}
