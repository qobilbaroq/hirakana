import 'package:audioplayers/audioplayers.dart';

import '../../data/models/kana.dart';
import '../../data/seed/word_data.dart';
import '../settings/app_settings.dart';

/// Memutar suara dari file audio yang ikut di dalam aplikasi (offline):
///   assets/audio/<romaji>.mp3             huruf, normal (rekaman asli)
///   assets/audio/slow/<romaji>.mp3        huruf, lambat
///   assets/audio/words/<cara-baca>.mp3    kata utuh, normal (suara sintesis)
///   assets/audio/words/<cara-baca>_slow.mp3  kata utuh, lambat
/// Hiragana dan katakana dengan romaji sama memakai suara yang sama.
class KanaAudioService {
  KanaAudioService._();
  static final instance = KanaAudioService._();

  AudioPlayer? _player;
  String? _cycleKey;
  int _count = 0;

  /// Mengembalikan false kalau gagal, supaya latihan visual tetap jalan.
  Future<bool> _playAsset(String path, {String? fallback}) async {
    final player = _player ??= AudioPlayer();
    try {
      await player.stop();
      await player.play(AssetSource(path));
      return true;
    } catch (_) {
      if (fallback != null) return _playAsset(fallback);
      return false;
    }
  }

  Future<bool> play(String romaji, {bool slow = false}) => _playAsset(
        slow ? 'audio/slow/$romaji.mp3' : 'audio/$romaji.mp3',
        fallback: slow ? 'audio/$romaji.mp3' : null,
      );

  Future<bool> playWord(String reading, {bool slow = false}) => _playAsset(
        slow ? 'audio/words/${reading}_slow.mp3' : 'audio/words/$reading.mp3',
        fallback: slow ? 'audio/words/$reading.mp3' : null,
      );

  /// Pola normal/lambat dari Settings, dihitung per [key] (huruf atau kata).
  /// Berganti [key] = mulai lagi dari putaran pertama.
  bool _nextIsSlow(String key) {
    if (_cycleKey != key) {
      _cycleKey = key;
      _count = 0;
    }
    final cycle = AppSettings.instance.audioPattern.cycle;
    final slow = cycle[_count % cycle.length];
    _count++;
    return slow;
  }

  /// Putar huruf mengikuti pola putar (default: normal, normal, lambat).
  Future<bool> playCycle(Kana kana) =>
      play(kana.romaji, slow: _nextIsSlow('kana:${kana.id}'));

  /// Putar kata utuh mengikuti pola putar yang sama.
  Future<bool> playWordCycle(Word word) =>
      playWord(word.reading, slow: _nextIsSlow('word:${word.text}'));

  /// Panggil saat pindah ke kartu/soal berikutnya.
  void resetCycle() {
    _cycleKey = null;
    _count = 0;
  }
}
