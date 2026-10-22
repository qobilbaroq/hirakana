import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kana_quest/core/widgets/mastery_indicator.dart';

void main() {
  Future<void> pumpAt(WidgetTester tester, double width, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(width: width, child: child),
          ),
        ),
      ),
    );
  }

  testWidgets('empat langkah kaca dan label aksesibilitas', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpAt(tester, 120, const MasteryIndicator(step: 2));

    expect(find.bySemanticsLabel('Mastery 2 of 4'), findsOneWidget);
    expect(tester.takeException(), isNull);
    handle.dispose();
  });

  testWidgets('level lama 3 dipetakan ke langkah selesai', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpAt(tester, 120, const MasteryIndicator(level: 3));

    expect(find.bySemanticsLabel('Mastery complete'), findsOneWidget);
    expect(tester.takeException(), isNull);
    handle.dispose();
  });

  testWidgets('muat di tile sempit tanpa overflow', (tester) async {
    await pumpAt(tester, 58, const MasteryIndicator(step: 4));

    expect(tester.takeException(), isNull);
  });
}
