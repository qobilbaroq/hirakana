import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kana_quest/app/theme/app_colors.dart';
import 'package:kana_quest/app/theme/app_theme.dart';

double contrast(Color a, Color b) {
  final l1 = a.computeLuminance();
  final l2 = b.computeLuminance();
  return (max(l1, l2) + 0.05) / (min(l1, l2) + 0.05);
}

void main() {
  group('palet terang dan gelap', () {
    test('tidak ada lagi mode AMOLED / hitam sejati', () {
      expect(AppPalette.dark.paper, isNot(const Color(0xFF000000)));
      expect(AppPalette.dark.paper.computeLuminance(), greaterThan(0.001));
    });

    test('pilihan aktif memakai abu-abu, bukan hitam', () {
      expect(AppPalette.light.active, isNot(AppPalette.light.ink));
      expect(AppPalette.light.active.computeLuminance(), greaterThan(0.2));
      expect(
        contrast(AppPalette.light.onActive, AppPalette.light.active),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(AppPalette.dark.onActive, AppPalette.dark.active),
        greaterThanOrEqualTo(4.5),
      );
    });

    for (final entry in {
      'terang': AppPalette.light,
      'gelap': AppPalette.dark,
    }.entries) {
      test('${entry.key}: teks terbaca di atas latar dan permukaan', () {
        final p = entry.value;
        expect(contrast(p.ink, p.paper), greaterThanOrEqualTo(7));
        expect(contrast(p.ink, p.white), greaterThanOrEqualTo(7));
        expect(contrast(p.ink, p.sand), greaterThanOrEqualTo(7));
        expect(contrast(p.muted, p.paper), greaterThanOrEqualTo(3.5));
        expect(contrast(p.muted, p.white), greaterThanOrEqualTo(3.5));
        expect(contrast(p.onAction, p.action), greaterThanOrEqualTo(4.5));
      });
    }

    test('tema gelap tidak memakai blok terang yang menyilaukan', () {
      expect(AppPalette.dark.action.computeLuminance(), lessThan(0.25));
      expect(AppPalette.dark.ink.computeLuminance(), lessThan(0.85));
    });
  });

  group('gradien latar', () {
    test('gelap memakai stop yang diberikan dan menggelap ke bawah', () {
      addTearDown(() => AppColors.isDark = false);
      AppColors.isDark = true;
      final g = AppColors.backgroundGradient;
      expect(g.stops!.length, 8);
      expect(g.colors.length, 8);
      expect(g.colors.first.a, 1);
      expect(g.colors.last.a, 1);
      expect(
        g.colors.first.computeLuminance(),
        greaterThan(g.colors.last.computeLuminance()),
      );
    });

    test('terang memakai gradasi hangat yang tetap terang', () {
      addTearDown(() => AppColors.isDark = false);
      AppColors.isDark = false;
      final g = AppColors.backgroundGradient;
      expect(g.colors.first.a, 1);
      expect(g.colors.last.a, 1);
      expect(g.colors.first.computeLuminance(), greaterThan(0.65));
    });

    test('kaca aktif kana tetap transparan di kedua tema', () {
      addTearDown(() => AppColors.isDark = false);
      for (final dark in [true, false]) {
        AppColors.isDark = dark;
        final g = AppColors.activeGlassGradient(intensity: 1.5);
        expect(g.colors.first.a, greaterThan(0));
        expect(g.colors.first.a, lessThan(1));
        expect(g.colors.last.a, greaterThan(0));
        expect(g.colors.last.a, lessThan(1));
      }
    });
  });

  group('buildAppTheme', () {
    for (final entry in {
      'terang': (Brightness.light, AppPalette.light),
      'gelap': (Brightness.dark, AppPalette.dark),
    }.entries) {
      test('${entry.key}: scaffold transparan untuk latar gradien', () {
        final theme = buildAppTheme(entry.value.$1);
        final p = entry.value.$2;
        expect(theme.scaffoldBackgroundColor, Colors.transparent);
        expect(theme.appBarTheme.backgroundColor, Colors.transparent);
        expect(theme.colorScheme.surface, p.paper);
        expect(theme.cardTheme.color, p.white);
        expect(
          theme.segmentedButtonTheme.style?.backgroundColor?.resolve({
            WidgetState.selected,
          }),
          p.active,
        );
        expect(theme.colorScheme.primary, p.action);
        expect(theme.colorScheme.onPrimary, p.onAction);
        expect(
          theme.filledButtonTheme.style?.backgroundColor?.resolve({}),
          p.ink,
        );
        expect(
          theme.filledButtonTheme.style?.foregroundColor?.resolve({}),
          p.paper,
        );
      });
    }

    test('snackbar dan dialog tidak menjadi blok terang di tema gelap', () {
      final t = buildAppTheme(Brightness.dark);
      expect(
        t.snackBarTheme.backgroundColor!.computeLuminance(),
        lessThan(0.2),
      );
      expect(t.dialogTheme.backgroundColor, AppPalette.dark.white);
    });
  });
}
