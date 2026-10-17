import 'package:flutter_test/flutter_test.dart';
import 'package:kana_quest/core/audio/audio_source.dart';
import 'package:kana_quest/data/models/kana.dart';
import 'package:kana_quest/data/seed/kana_data.dart';
import 'package:kana_quest/data/seed/word_data.dart';

Kana _kana(String r) =>
    allKana.firstWhere((k) => k.romaji == r, orElse: () => hiraganaList.first);

void main() {
  group('pickReadAudioSource', () {
    test('satu huruf SELALU pakai rekaman huruf, apa pun status TTS', () {
      for (final tts in [true, false, null]) {
        expect(
          pickReadAudioSource(
            isSingleLetter: true,
            isRealWord: false,
            wordHasAudio: false,
            ttsAvailable: tts,
          ),
          AudioSource.letterClip,
          reason: 'ttsAvailable=$tts',
        );
      }
    });

    test('kata yang punya rekaman SELALU pakai rekaman kata', () {
      for (final tts in [true, false, null]) {
        expect(
          pickReadAudioSource(
            isSingleLetter: false,
            isRealWord: true,
            wordHasAudio: true,
            ttsAvailable: tts,
          ),
          AudioSource.wordClip,
          reason: 'ttsAvailable=$tts',
        );
      }
    });

    test('kata tanpa rekaman: TTS kalau tersedia', () {
      expect(
        pickReadAudioSource(
          isSingleLetter: false,
          isRealWord: true,
          wordHasAudio: false,
          ttsAvailable: true,
        ),
        AudioSource.systemTts,
      );
    });

    test('kata tanpa rekaman dan TTS tidak ada: huruf demi huruf', () {
      for (final tts in [false, null]) {
        expect(
          pickReadAudioSource(
            isSingleLetter: false,
            isRealWord: true,
            wordHasAudio: false,
            ttsAvailable: tts,
          ),
          AudioSource.letterSequence,
          reason: 'ttsAvailable=$tts',
        );
      }
    });

    test('rangkaian 2-3 huruf: TTS kalau tersedia', () {
      expect(
        pickReadAudioSource(
          isSingleLetter: false,
          isRealWord: false,
          wordHasAudio: false,
          ttsAvailable: true,
        ),
        AudioSource.systemTts,
      );
    });

    test('rangkaian huruf tanpa TTS: huruf demi huruf', () {
      expect(
        pickReadAudioSource(
          isSingleLetter: false,
          isRealWord: false,
          wordHasAudio: false,
          ttsAvailable: false,
        ),
        AudioSource.letterSequence,
      );
    });
  });

  group('pickReadAudioSourceFor', () {
    const tsuu = Word('ツー', 'tsuu', hasAudio: true);

    test('kata satu kana (ツー) TETAP pakai rekaman kata', () {
      // Bug: isSingleLetter pernah ditebak dari letters.length <= 1.
      // ツー cuma punya satu kana + tanda panjang, jadi kelihatan seperti
      // soal satu huruf dan hanya dibunyikan "tsu".
      expect(
        pickReadAudioSourceFor(
          letters: [_kana('tsu')],
          word: tsuu,
          isSingleLetter: false,
          ttsAvailable: false,
        ),
        AudioSource.wordClip,
      );
    });

    test('soal satu huruf tetap rekaman huruf walau letters cuma satu', () {
      expect(
        pickReadAudioSourceFor(
          letters: [_kana('a')],
          word: null,
          isSingleLetter: true,
          ttsAvailable: true,
        ),
        AudioSource.letterClip,
      );
    });

    test('kata tanpa rekaman dan TTS ada -> TTS', () {
      expect(
        pickReadAudioSourceFor(
          letters: [_kana('tsu')],
          word: const Word('つー', 'tsuu'),
          isSingleLetter: false,
          ttsAvailable: true,
        ),
        AudioSource.systemTts,
      );
    });
  });
}