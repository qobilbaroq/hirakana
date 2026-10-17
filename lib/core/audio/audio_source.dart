import '../../data/models/kana.dart';
import '../../data/seed/word_data.dart';

/// Dari mana suara sebuah soal latihan baca sebaiknya diambil.
enum AudioSource {
  /// Rekaman satu huruf: `assets/audio/romaji.mp3`
  letterClip,

  /// Rekaman kata utuh: `assets/audio/words/cara-baca.mp3`
  wordClip,

  /// TTS sistem membaca teks kana sebagai satu ucapan.
  systemTts,

  /// Cadangan terakhir: rekaman huruf diputar berurutan.
  letterSequence,
}

/// Memilih sumber suara untuk satu soal baca.
///
/// Aturannya:
/// 1. satu huruf              -> [letterClip]  (selalu, apa pun status TTS)
/// 2. kata yang punya rekaman -> [wordClip]    (selalu, apa pun status TTS)
/// 3. kata tanpa rekaman      -> [systemTts] kalau TTS Jalan,
///                               kalau tidak [letterSequence]
/// 4. rangkaian 2-3 huruf      -> [systemTts] kalau TTS jalan,
///                               kalau tidak [letterSequence]
///
/// [ttsAvailable] boleh null (TTS belum dicek) dan dianggap tidak tersedia.
///
/// Fungsi murni: tidak memutar audio apa pun, supaya bisa diuji langsung.
AudioSource pickReadAudioSource({
  required bool isSingleLetter,
  required bool isRealWord,
  required bool wordHasAudio,
  required bool? ttsAvailable,
}) {
  if (isSingleLetter) return AudioSource.letterClip;
  if (isRealWord && wordHasAudio) return AudioSource.wordClip;
  return ttsAvailable == true ? AudioSource.systemTts : AudioSource.letterSequence;
}

/// Bentuk convenience untuk satu soal baca.
///
/// [isSingleLetter] WAJIB diberikan dari jenis soalnya ([ReadKind.single]),
/// bukan ditebak dari jumlah kana. Menebak dari jumlah kana salah: kata
/// `ツー` cuma punya satu kana (tsu) + tanda panjang, jadi akan terbaca
/// sebagai satu huruf dan tidak pernah memakai rekaman kata-nya.
AudioSource pickReadAudioSourceFor({
  required List<Kana> letters,
  required Word? word,
  required bool isSingleLetter,
  required bool? ttsAvailable,
}) {
  return pickReadAudioSource(
    isSingleLetter: isSingleLetter,
    isRealWord: word != null,
    wordHasAudio: word?.hasAudio ?? false,
    ttsAvailable: ttsAvailable,
  );
}