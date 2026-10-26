import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_fonts.dart';
import '../../data/repositories/kana_repository.dart';

/// Pola putar saat huruf yang sama diputar berulang. true = lambat.
enum AudioPattern {
  normalNormalSlow('Normal, normal, slow', [false, false, true]),
  normalSlow('Normal, slow, normal, slow', [false, true]),
  alwaysNormal('Always normal', [false]),
  alwaysSlow('Always slow', [true]);

  const AudioPattern(this.label, this.cycle);
  final String label;
  final List<bool> cycle;
}

/// Pengaturan pengguna. Disimpan di tabel meta, dimuat sekali saat app mulai.
class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final instance = AppSettings._();

  static const goalChoices = [5, 10, 15, 20, 30];

  /// Jumlah kartu/soal per sesi: minimal 10, kelipatan 5.
  static const minSessionSize = 10;
  static const maxSessionSize = 60;

  int goalMinutes = 10;
  int sessionSize = minSessionSize;

  /// Tampilkan arti kata setelah menjawab (hanya untuk kata yang punya arti).
  bool showMeaning = true;

  /// Default mengikuti pengaturan sistem; pengguna tetap bisa memilih Light
  /// atau Dark di Settings.
  ThemeMode themeMode = ThemeMode.system;
  bool autoPlay = true;

  /// Warna aksen (mono = hitam-putih bawaan) dan font huruf Jepang.
  AppAccent accent = AppAccent.mono;
  String fontId = AppFonts.defaultId;

  AudioPattern audioPattern = AudioPattern.normalNormalSlow;

  final _repo = KanaRepository.instance;

  Future<void> load() async {
    goalMinutes = int.tryParse(await _repo.getMeta('goal_minutes') ?? '') ?? 10;
    themeMode = switch (await _repo.getMeta('theme_mode')) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    sessionSize = (int.tryParse(await _repo.getMeta('session_size') ?? '') ??
            minSessionSize)
        .clamp(minSessionSize, maxSessionSize)
        .toInt();
    accent = AppAccent.byName(await _repo.getMeta('accent'));
    fontId = AppFonts.byId(await _repo.getMeta('kana_font')).id;
    _applyLook();
    showMeaning = (await _repo.getMeta('show_meaning')) != '0';
    autoPlay = (await _repo.getMeta('audio_autoplay')) != '0';
    final pattern = await _repo.getMeta('audio_pattern');
    audioPattern = AudioPattern.values.firstWhere(
      (p) => p.name == pattern,
      orElse: () => AudioPattern.normalNormalSlow,
    );
  }

  Future<void> setGoalMinutes(int v) async {
    goalMinutes = v;
    notifyListeners();
    await _repo.setMeta('goal_minutes', '$v');
  }

  Future<void> setSessionSize(int v) async {
    sessionSize = v.clamp(minSessionSize, maxSessionSize).toInt();
    notifyListeners();
    await _repo.setMeta('session_size', '$sessionSize');
  }

  Future<void> setShowMeaning(bool v) async {
    showMeaning = v;
    notifyListeners();
    await _repo.setMeta('show_meaning', v ? '1' : '0');
  }

  Future<void> setThemeMode(ThemeMode m) async {
    themeMode = m;
    notifyListeners();
    await _repo.setMeta('theme_mode', m.name);
  }

  /// Menyalin pilihan tampilan ke [AppColors] / [AppFonts], yang dibaca widget.
  void _applyLook() {
    AppColors.accent = accent;
    AppFonts.selectedId = fontId;
  }

  Future<void> setAccent(AppAccent a) async {
    accent = a;
    _applyLook();
    notifyListeners();
    await _repo.setMeta('accent', a.name);
  }

  Future<void> setFont(String id) async {
    fontId = AppFonts.byId(id).id;
    _applyLook();
    notifyListeners();
    await _repo.setMeta('kana_font', fontId);
  }

  Future<void> setAutoPlay(bool v) async {
    autoPlay = v;
    notifyListeners();
    await _repo.setMeta('audio_autoplay', v ? '1' : '0');
  }

  Future<void> setAudioPattern(AudioPattern p) async {
    audioPattern = p;
    notifyListeners();
    await _repo.setMeta('audio_pattern', p.name);
  }
}
