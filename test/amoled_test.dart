import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kana_quest/app/theme/app_colors.dart';
import 'package:kana_quest/app/theme/app_theme.dart';
import 'package:kana_quest/data/seed/word_data.dart';
import 'package:kana_quest/features/words/word_practice_screen.dart';


void main() {
  group('AppPalette.amoled', () {
    test('warna sesuai spesifikasi', () {
      const p = AppPalette.amoled;
      expect(p.paper, const Color(0xFF000000));
      expect(p.white, const Color(0xFF0B0B0B));
      expect(p.sand, const Color(0xFF181818));
      expect(p.line, const Color(0xFF262626));
      expect(p.guide, const Color(0xFF1A1A1A));
      expect(p.ink, const Color(0xFFECE9E0));
      expect(p.muted, const Color(0xFF9FA395));
      expect(p.sage, const Color(0xFF9DB093));
      expect(p.clay, const Color(0xFFE0A992));
    });

    test('hanya aktif kalau isDark DAN isAmoled', () {
      addTearDown(() {
        AppColors.isDark = false;
        AppColors.isAmoled = false;
      });

      AppColors.isDark = true;
      AppColors.isAmoled = true;
      expect(AppColors.paper, const Color(0xFF000000));
      expect(AppColors.white, const Color(0xFF0B0B0B));

      // isAmoled tapi tema terang -> tetap palet terang.
      AppColors.isDark = false;
      expect(AppColors.paper, AppPalette.light.paper);
      expect(AppColors.paper, isNot(const Color(0xFF000000)));

      // gelap tapi AMOLED mati -> palet gelap biasa, bukan hitam.
      AppColors.isDark = true;
      AppColors.isAmoled = false;
      expect(AppColors.paper, AppPalette.dark.paper);
      expect(AppColors.paper, isNot(const Color(0xFF000000)));
    });

    test('teks tetap terbaca: ink terang di atas permukaan hitam', () {
      addTearDown(() {
        AppColors.isDark = false;
        AppColors.isAmoled = false;
      });
      AppColors.isDark = true;
      AppColors.isAmoled = true;
      // Kontras luminance harus jauh.
      expect(AppColors.ink.computeLuminance(),
          greaterThan(AppColors.white.computeLuminance() + 0.5));
      expect(AppColors.ink.computeLuminance(),
          greaterThan(AppColors.sand.computeLuminance()));
      expect(AppColors.ink.computeLuminance(),
          greaterThan(AppColors.muted.computeLuminance()));
    });
  });

  group('buildAppTheme AMOLED', () {
    test('latar scaffold, appbar, navbar dan colorScheme benar-benar hitam', () {
      final t = buildAppTheme(Brightness.dark, amoled: true);
      expect(t.scaffoldBackgroundColor, const Color(0xFF000000));
      expect(t.appBarTheme.backgroundColor, const Color(0xFF000000));
      expect(t.navigationBarTheme.backgroundColor, const Color(0xFF000000));
      expect(t.colorScheme.surface, const Color(0xFF000000));
      expect(t.cardTheme.color, const Color(0xFF0B0B0B));
      // Permukaan container tidak boleh abu kehijauan (hasil seed sage).
      for (final c in [
        t.colorScheme.surfaceContainerLowest,
        t.colorScheme.surfaceContainer,
        t.colorScheme.surfaceContainerHigh,
        t.colorScheme.surfaceContainerHighest,
      ]) {
        expect(c.computeLuminance(), lessThan(0.12),
            reason: 'permukaan $c terlalu terang untuk AMOLED');
      }
    });

    test('tema gelap biasa tidak berubah', () {
      final t = buildAppTheme(Brightness.dark);
      expect(t.scaffoldBackgroundColor, AppPalette.dark.paper);
      expect(t.scaffoldBackgroundColor, const Color(0xFF171916));
    });

    test('tema terang tidak terpengaruh amoled', () {
      final withFlag = buildAppTheme(Brightness.light, amoled: true);
      final without = buildAppTheme(Brightness.light);
      expect(withFlag.scaffoldBackgroundColor, without.scaffoldBackgroundColor);
      expect(withFlag.scaffoldBackgroundColor, AppPalette.light.paper);
    });
  });

  group('pilihan jawaban latihan kata', () {
    test('jawaban benar selalu ada, tepat 4, berlabel unik', () {
      final rng = Random(5);
      // Pool kecil supaya jumlah kata terbatas seperti kondisi nyata.
      final pool = allWords.take(20).toList();
      for (final w in allWords.take(200)) {
        final options = buildWordOptions(w, pool, rng);
        expect(options.length, 4, reason: 'kata ${w.text} (${w.reading})');
        expect(options, contains(w.reading),
            reason: 'jawaban benar hilang untuk ${w.text} (${w.reading}): $options');
        expect(options.toSet().length, 4,
            reason: 'label duplikat untuk ${w.text}: $options');
      }
    });

    test('noun dipakai dua kali sebagai pilihan', () {
      final rng = Random(11);
      final pool = allWords.take(5).toList();
      for (final w in pool) {
        final options = buildWordOptions(w, pool, rng);
        expect(options, contains(w.reading));
        expect(options.toSet().length, options.length);
      }
    });
  });
}