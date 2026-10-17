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
  group('AppPalette.amoled', () {
    const p = AppPalette.amoled;

    test('latar hitam sejati, permukaan lain tetap sangat gelap', () {
      expect(p.paper, const Color(0xFF000000));
      expect(p.white.computeLuminance(), lessThan(0.03));
      expect(p.sand.computeLuminance(), lessThan(0.03));
      expect(p.line.computeLuminance(), lessThan(0.06));
    });

    test('permukaan hangat (sedikit kehijauan), bukan abu netral', () {
      // Abu netral di samping hitam terlihat "kotor" di layar OLED.
      for (final c in [p.white, p.sand, p.line, p.guide]) {
        expect(c.g, greaterThanOrEqualTo(c.r));
        expect(c.g, greaterThanOrEqualTo(c.b));
      }
    });

    test('hanya aktif kalau isDark DAN isAmoled', () {
      addTearDown(() {
        AppColors.isDark = false;
        AppColors.isAmoled = false;
      });

      AppColors.isDark = true;
      AppColors.isAmoled = true;
      expect(AppColors.paper, AppPalette.amoled.paper);
      expect(AppColors.white, AppPalette.amoled.white);
      expect(AppColors.action, AppPalette.amoled.action);

      // isAmoled tapi tema terang -> tetap palet terang.
      AppColors.isDark = false;
      expect(AppColors.paper, AppPalette.light.paper);

      // gelap tapi AMOLED mati -> palet gelap biasa, bukan hitam.
      AppColors.isDark = true;
      AppColors.isAmoled = false;
      expect(AppColors.paper, AppPalette.dark.paper);
      expect(AppColors.paper, isNot(const Color(0xFF000000)));
    });
  });

  group('kenyamanan mata di semua palet', () {
    final palettes = {
      'terang': AppPalette.light,
      'gelap': AppPalette.dark,
      'AMOLED': AppPalette.amoled,
    };

    palettes.forEach((name, p) {
      test('$name: teks terbaca di atas latar dan permukaan', () {
        expect(contrast(p.ink, p.paper), greaterThanOrEqualTo(7), reason: name);
        expect(contrast(p.ink, p.white), greaterThanOrEqualTo(7), reason: name);
        expect(contrast(p.ink, p.sand), greaterThanOrEqualTo(7), reason: name);
        // Teks sekunder tidak perlu setegas teks utama.
        expect(contrast(p.muted, p.paper), greaterThanOrEqualTo(3.5), reason: name);
        expect(contrast(p.muted, p.white), greaterThanOrEqualTo(3.5), reason: name);
      });

      test('$name: tombol utama terbaca', () {
        expect(contrast(p.onAction, p.action), greaterThanOrEqualTo(4.5),
            reason: name);
      });
    });

    test('tema gelap: tidak ada blok terang yang menyilaukan', () {
      for (final p in [AppPalette.dark, AppPalette.amoled]) {
        // Tombol utama dulu berwarna krem terang (luminance ~0.8).
        expect(p.action.computeLuminance(), lessThan(0.25));
        // Teks tidak putih murni.
        expect(p.ink.computeLuminance(), lessThan(0.85));
        // Aksen diredam.
        expect(p.sage.computeLuminance(), lessThan(0.5));
        expect(p.clay.computeLuminance(), lessThan(0.5));
      }
    });
  });

  group('buildAppTheme', () {
    test('AMOLED: latar scaffold, appbar, navbar dan colorScheme hitam', () {
      final t = buildAppTheme(Brightness.dark, amoled: true);
      expect(t.scaffoldBackgroundColor, const Color(0xFF000000));
      expect(t.appBarTheme.backgroundColor, const Color(0xFF000000));
      expect(t.navigationBarTheme.backgroundColor, const Color(0xFF000000));
      expect(t.colorScheme.surface, const Color(0xFF000000));
      expect(t.cardTheme.color, AppPalette.amoled.white);
      for (final c in [
        t.colorScheme.surfaceContainerLowest,
        t.colorScheme.surfaceContainer,
        t.colorScheme.surfaceContainerHigh,
        t.colorScheme.surfaceContainerHighest,
      ]) {
        expect(c.computeLuminance(), lessThan(0.05),
            reason: 'permukaan $c terlalu terang untuk AMOLED');
      }
    });

    test('tema gelap biasa memakai palet gelap', () {
      final t = buildAppTheme(Brightness.dark);
      expect(t.scaffoldBackgroundColor, AppPalette.dark.paper);
      expect(t.colorScheme.surface, AppPalette.dark.paper);
    });

    test('tema terang tidak terpengaruh amoled', () {
      final withFlag = buildAppTheme(Brightness.light, amoled: true);
      final without = buildAppTheme(Brightness.light);
      expect(withFlag.scaffoldBackgroundColor, without.scaffoldBackgroundColor);
      expect(withFlag.scaffoldBackgroundColor, AppPalette.light.paper);
    });

    for (final entry in {
      'terang': buildAppTheme(Brightness.light),
      'gelap': buildAppTheme(Brightness.dark),
      'AMOLED': buildAppTheme(Brightness.dark, amoled: true),
    }.entries) {
      test('${entry.key}: komponen Material memakai warna palet', () {
        final t = entry.value;
        final p = t.brightness == Brightness.light
            ? AppPalette.light
            : (entry.key == 'AMOLED' ? AppPalette.amoled : AppPalette.dark);
        expect(t.colorScheme.primary, p.action);
        expect(t.colorScheme.onPrimary, p.onAction);
        expect(t.filledButtonTheme.style?.backgroundColor?.resolve({}), p.action);
        // Snackbar dan dialog tidak boleh jadi blok terang di tema gelap.
        if (p.isDark) {
          expect(t.snackBarTheme.backgroundColor!.computeLuminance(), lessThan(0.2));
          expect(t.dialogTheme.backgroundColor, p.white);
        }
      });
    }
  });
}
