import 'package:flutter/material.dart';

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

  /// Tingkat kosakata yang dipakai di latihan baca.
enum WordLevel {
  n5('N5 only', 0),
  n5n4('N5-N4', 1),
  n5n4n3('N5-N3', 2);

  const WordLevel(this.label, this.maxRank);
  final String label;

  /// Level tertinggi yang ikut dipakai (0 = N5, 2 = N3).
  final int maxRank;

  bool includes(String level) {
    final rank = WordLevel._rankOf(level);
    return rank != null && rank <= maxRank;
  }

  static int? _rankOf(String level) => switch (level) {
        'N5' => 0,
        'N4' => 1,
        'N3' => 2,
        _ => null,
      };

  static WordLevel fromName(String? name) => WordLevel.values.firstWhere(
        (v) => v.name == name,
        orElse: () => WordLevel.n5n4n3,
      );
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

  /// Tampilkan arti kata setelah jawaban benar (hanya untuk kata yang punya arti).
  bool showMeaning = true;

  /// Tingkat kosakata JLPT yang dipakai di latihan baca.
  WordLevel wordLevel = WordLevel.n5n4n3;

  /// Kalau hidup, kata umum non-JLPT (level kosong) ikut dipakai.
  bool wordExtra = false;
  ThemeMode themeMode = ThemeMode.system;
  /// Hanya berlaku kalau tema aktif gelap.
  bool amoled = false;
  bool autoPlay = true;
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
    // DefaultNYA HIDUP. Kalau kunci belum pernah disimpan (pengguna baru),
    // pakai true; kalau sudah pernah disimpan, hormati pilihannya.
    wordLevel = WordLevel.fromName(await _repo.getMeta('word_level'));
    wordExtra = (await _repo.getMeta('word_extra')) == '1';
    final storedMeaning = await _repo.getMeta('show_meaning');
    showMeaning = storedMeaning == null ? true : storedMeaning == '1';
    amoled = (await _repo.getMeta('theme_amoled')) == '1';
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


  Future<void> setWordLevel(WordLevel v) async {
    wordLevel = v;
    notifyListeners();
    await _repo.setMeta('word_level', v.name);
  }

  Future<void> setWordExtra(bool v) async {
    wordExtra = v;
    notifyListeners();
    await _repo.setMeta('word_extra', v ? '1' : '0');
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

  Future<void> setAmoled(bool v) async {
    amoled = v;
    notifyListeners();
    await _repo.setMeta('theme_amoled', v ? '1' : '0');
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
