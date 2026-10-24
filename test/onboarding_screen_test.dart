import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kana_quest/features/onboarding/onboarding_screen.dart';

/// Membuka onboarding dari sebuah tombol; hasil pop-nya dikirim ke [onResult].
Future<void> _open(
  WidgetTester tester,
  ValueChanged<OnboardingResult?> onResult,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            final r = await Navigator.of(context).push<OnboardingResult>(
              MaterialPageRoute(builder: (_) => const OnboardingScreen()),
            );
            onResult(r);
          },
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('pemula: Next dua kali lalu Start Lesson 1', (tester) async {
    OnboardingResult? result;
    await _open(tester, (r) => result = r);

    expect(find.text('Learn Hiragana & Katakana'), findsOneWidget);
    await _tapText(tester, 'Next');
    expect(find.text('Where are you now?'), findsOneWidget);
    await _tapText(tester, 'Next');
    expect(find.text('Start Lesson 1'), findsOneWidget);

    await _tapText(tester, 'Start Lesson 1');
    expect(result, OnboardingResult.start);
  });

  testWidgets('sudah tahu sebagian: tombol akhir jadi Choose my letters', (
    tester,
  ) async {
    OnboardingResult? result;
    await _open(tester, (r) => result = r);

    await _tapText(tester, 'Next');
    await _tapText(tester, 'I know some already');
    await _tapText(tester, 'Next');
    expect(find.text('Choose my letters'), findsOneWidget);

    await _tapText(tester, 'Choose my letters');
    expect(result, OnboardingResult.chooseLetters);
  });

  testWidgets('Skip menutup onboarding dengan hasil skip', (tester) async {
    OnboardingResult? result;
    await _open(tester, (r) => result = r);

    await _tapText(tester, 'Skip');
    expect(result, OnboardingResult.skip);
  });
}
