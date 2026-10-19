import '../../core/audio/kana_audio_service.dart';
import '../../data/repositories/word_repository.dart';
import '../../data/seed/word_data.dart';

/// Memutar suara sebuah kata: rekaman utuh kalau ada, kalau tidak huruf-hurufnya
/// dibunyikan berurutan. Mengikuti pola normal/lambat dari Settings.
void playWordSound(Word word) {
  final audio = KanaAudioService.instance;
  if (word.hasAudio) {
    audio.playWordCycle(word);
  } else {
    audio.playKanaSequence(WordRepository.kanaOf(word.text), key: word.text);
  }
}
