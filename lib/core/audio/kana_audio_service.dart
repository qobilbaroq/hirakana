import 'package:audioplayers/audioplayers.dart';

import '../../data/models/kana.dart';
import '../../data/seed/word_data.dart';
import '../settings/app_settings.dart';
import 'audio_source.dart';
import 'system_tts_service.dart';

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
  int _sequenceId = 0;

  /// Mengembalikan false kalau gagal, supaya latihan visual tetap jalan.
  Future<bool> _playAsset(String path, {String? fallback}) async {
    _sequenceId++; // membatalkan putaran berurutan yang masih jalan
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

  /// Memutar beberapa huruf berurutan. Ini CADANGAN TERAKHIR: hanya dipakai
  /// kalau TTS sistem tidak tersedia atau gagal. Jeda antar huruf sengaja
  /// pendek supaya terdengar menyambung, bukan terputus-putus.
  Future<void> playKanaSequence(
    List<Kana> letters, {
    required String key,
    bool? slowOverride,
  }) async {
    final slow = slowOverride ?? _nextIsSlow('seq:$key');
    final id = ++_sequenceId;
    final player = _player ??= AudioPlayer();
    for (final k in letters) {
      if (id != _sequenceId) return;
      try {
        await player.stop();
        final done = player.onPlayerComplete.first;
        await player.play(AssetSource(
            slow ? 'audio/slow/${k.romaji}.mp3' : 'audio/${k.romaji}.mp3'));
        await done.timeout(const Duration(seconds: 4));
      } catch (_) {}
      await Future<void>.delayed(Duration(milliseconds: slow ? 90 : 15));
    }
  }

  /// Memutar suara satu soal latihan baca, mengikuti rantai:
  /// rekaman huruf -> rekaman kata -> TTS sistem -> huruf demi huruf.
  ///
  /// Pola putar (normal, normal, lambat) dihitung SEKALI di sini supaya
  /// pergantian ke cadangan tidak memakai counter dua kali.
  Future<bool> playRead({
    required List<Kana> letters,
    required Word? word,
    required String text,
    required String key,
    required bool isSingleLetter,
  }) async {
    if (letters.isEmpty) return false;
    // Hanya periksa ketersediaan TTS kalau benar-benar dipakai. Kalau kata
    // ini punya rekaman (atau soalnya satu huruf), probing TTS menambah jeda
    // tanpa manfaat dan bisa membuat peringatan suara Jepang muncul
    // padahal TTS tidak akan dipakai.
    final needsTts = word == null || !word.hasAudio;
    final ttsReady =
        needsTts && await SystemTtsService.instance.ensureAvailable();
    final source = pickReadAudioSourceFor(
      letters: letters,
      word: word,
      isSingleLetter: isSingleLetter,
      ttsAvailable: ttsReady,
    );

    switch (source) {
      case AudioSource.letterClip:
        return play(letters.first.romaji, slow: _nextIsSlow('kana:${letters.first.id}'));

      case AudioSource.wordClip:
        return playWord(word!.reading, slow: _nextIsSlow('word:${word.text}'));

      case AudioSource.systemTts:
        final slow = _nextIsSlow('tts:$key');
        if (await SystemTtsService.instance.speak(text, slow: slow)) return true;
        // TTS gagal: pakai cadangan huruf demi huruf, dengan keputusan lambat
        // yang SUDAH dihitung di atas.
        await playKanaSequence(letters, key: key, slowOverride: slow);
        return false;

      case AudioSource.letterSequence:
        await playKanaSequence(letters, key: key);
        return true;
    }
  }

  void stopSequence() {
    _sequenceId++;
    _player?.stop();
  }

  /// Panggil saat pindah ke kartu/soal berikutnya.
  void resetCycle() {
    _cycleKey = null;
    _count = 0;
  }
}
