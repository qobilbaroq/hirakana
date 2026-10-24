import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kana_quest/app/theme/app_colors.dart';
import 'package:kana_quest/app/theme/app_fonts.dart';
import 'package:kana_quest/app/theme/app_theme.dart';
import 'package:kana_quest/core/settings/app_settings.dart';
import 'package:kana_quest/core/widgets/answer_option.dart';
import 'package:kana_quest/core/widgets/curved_nav_bar.dart';

import 'helpers/test_db.dart';

double contrast(Color a, Color b) {
  final l1 = a.computeLuminance();
  final l2 = b.computeLuminance();
  return (max(l1, l2) + 0.05) / (min(l1, l2) + 0.05);
}

void main() {
  tearDown(() {
    AppColors.accent = AppAccent.mono;
    AppColors.isDark = false;
    AppFonts.selectedId = AppFonts.defaultId;
  });

  group('warna aksen', () {
    test('mono: tombol utama tetap ink di atas paper (tanpa warna)', () {
      for (final dark in [true, false]) {
        final p = AppColors.paletteFor(dark, AppAccent.mono);
        expect(p.button, p.ink);
        expect(p.onButton, p.paper);
        expect(identical(p, dark ? AppPalette.dark : AppPalette.light), isTrue);
      }
    });

    for (final a in AppAccent.values.where((a) => !a.isMono)) {
      test('${a.name}: tombol berwarna dan teks putih terbaca', () {
        for (final dark in [true, false]) {
          final p = AppColors.paletteFor(dark, a);
          expect(p.button, a.color);
          expect(contrast(p.onButton, p.button), greaterThanOrEqualTo(4.0));
          expect(contrast(p.onActive, p.active), greaterThanOrEqualTo(4.0));
        }
      });

      test('${a.name}: gradien latar berwarna di atas dan netral di bawah', () {
        for (final dark in [true, false]) {
          AppColors.isDark = dark;
          AppColors.accent = AppAccent.mono;
          final mono = AppColors.backgroundGradient;
          AppColors.accent = a;
          final g = AppColors.backgroundGradient;
          expect(g.colors.length, mono.colors.length);
          expect(g.stops!.length, g.colors.length);
          expect(g.colors.first, isNot(mono.colors.first));
          expect(g.colors.last, mono.colors.last);
          for (final c in g.colors) {
            expect(c.a, 1);
          }
        }
      });

      test('${a.name}: kaca aktif tetap transparan', () {
        AppColors.accent = a;
        for (final dark in [true, false]) {
          AppColors.isDark = dark;
          final g = AppColors.activeGlassGradient(intensity: 1.5);
          expect(g.colors.first.a, greaterThan(0));
          expect(g.colors.first.a, lessThan(1));
          expect(g.colors.last.a, greaterThan(0));
          expect(g.colors.last.a, lessThan(1));
        }
      });
    }

    test('mode terang mono: kaca terpilih cukup gelap dari latar', () {
      AppColors.isDark = false;
      final g = AppColors.activeGlassGradient(intensity: 1.4);
      final bg = AppColors.backgroundGradient.colors.last;
      final top = Color.alphaBlend(g.colors.first, bg);
      expect(contrast(top, bg), greaterThanOrEqualTo(1.4));
    });

    test('bar navigasi lebih pekat dari sebelumnya', () {
      for (final dark in [true, false]) {
        AppColors.isDark = dark;
        expect(AppColors.glass.a, greaterThan(0.5));
        expect(AppColors.glass.a, lessThan(1));
      }
    });

    test('buildAppTheme mengikuti aksen', () {
      AppColors.accent = AppAccent.blue;
      final t = buildAppTheme(Brightness.dark);
      expect(
        t.filledButtonTheme.style?.backgroundColor?.resolve({}),
        AppAccent.blue.color,
      );
      expect(t.sliderTheme.activeTrackColor, AppAccent.blue.color);
    });

    test('byName: nama tidak dikenal kembali ke mono', () {
      expect(AppAccent.byName('blue'), AppAccent.blue);
      expect(AppAccent.byName('???'), AppAccent.mono);
      expect(AppAccent.byName(null), AppAccent.mono);
    });
  });

  group('font huruf Jepang', () {
    test('id unik dan family terisi', () {
      final ids = AppFonts.options.map((o) => o.id).toSet();
      expect(ids.length, AppFonts.options.length);
      for (final o in AppFonts.options) {
        expect(o.family, isNotEmpty);
      }
    });

    test('kana mengikuti pilihan, id tidak dikenal kembali ke standar', () {
      AppFonts.selectedId = 'klee';
      expect(AppFonts.kana, 'Klee One');
      AppFonts.selectedId = 'tidak-ada';
      expect(AppFonts.kana, 'Noto Sans JP');
    });
  });

  group('pengaturan tersimpan', () {
    setUp(() async {
      await TestDb.reset();
    });

    test('aksen dan font dimuat ulang setelah restart', () async {
      final s = AppSettings.instance;
      await s.load();
      await s.setAccent(AppAccent.purple);
      await s.setFont('mincho');
      expect(AppColors.accent, AppAccent.purple);
      expect(AppFonts.kana, 'Yuji Syuku');

      s.accent = AppAccent.mono;
      s.fontId = AppFonts.defaultId;
      await s.load();
      expect(s.accent, AppAccent.purple);
      expect(s.fontId, 'mincho');
      expect(AppColors.accent, AppAccent.purple);
    });
  });

  group('widget', () {
    testWidgets('AnswerOption tidak lagi menampilkan ikon centang/X', (
      tester,
    ) async {
      for (final state in OptionState.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnswerOption(
                label: 'ka',
                isKana: false,
                state: state,
                onTap: null,
              ),
            ),
          ),
        );
        expect(find.byType(Icon), findsNothing, reason: '$state');
      }
    });

    testWidgets('CurvedNavBar menggerakkan pil dulu, lalu memanggil onTap', (
      tester,
    ) async {
      var index = 0;
      final taps = <int>[];
      late StateSetter setOuter;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                setOuter = setState;
                return CurvedNavBar(
                  items: const [
                    CurvedNavItem(label: 'A', text: 'A'),
                    CurvedNavItem(label: 'B', text: 'B'),
                    CurvedNavItem(label: 'C', text: 'C'),
                  ],
                  currentIndex: index,
                  haptics: false,
                  onTap: (i) {
                    taps.add(i);
                    setOuter(() => index = i);
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('B'));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.tap(find.byTooltip('C'));
      await tester.pump(const Duration(milliseconds: 600));

      // Dua sentuhan cepat: keduanya diteruskan berurutan, indeks akhir = C.
      expect(taps, [1, 2]);
      expect(index, 2);
      expect(tester.takeException(), isNull);
    });
  });
}
