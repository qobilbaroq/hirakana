import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Suara TTS milik sistem (offline, sudah terpasang di HP).
///
/// Dipakai untuk membaca kata yang tidak punya rekaman di dalam aplikasi dan
/// untuk rangkaian huruf, supaya terdengar seperti membaca kata utuh -- bukan
/// huruf demi huruf yang lambat dan terputus-putus.
///
/// Semua pemanggilan dibungkus try/catch dan mengembalikan bool: kalau TTS
/// tidak ada atau gagal, pemanggil memakai cadangan sendiri (huruf demi
/// huruf).
class SystemTtsService {
  SystemTtsService._();
  static final instance = SystemTtsService._();

  FlutterTts? _tts;

  /// Hasil pemeriksaan bahasa: null = belum dicek.
  bool? _japaneseReady;

  /// true kalau platform ini punya flutter_tts yang bisa dipakai.
  /// Linux tidak punya;TTS desktop Linux tidak andal, jadi dianggap tidak
  /// tersedia dan pemindah memakai cadangan huruf demi huruf.
  bool get isSupportedPlatform {
    if (kIsWeb) return true;
    try {
      return Platform.isAndroid ||
          Platform.isIOS ||
          Platform.isMacOS ||
          Platform.isWindows;
    } catch (_) {
      // Platform tidak diketahui (mis. unit test): jangan pakai TTS.
      return false;
    }
  }

  FlutterTts? get _engine {
    _tts ??= isSupportedPlatform ? FlutterTts() : null;
    return _tts;
  }

  /// true kalau mesin sudah pernah dicek dan JEPANGNYA TERSEDIA.
  bool get japaneseVoiceAvailable => _japaneseReady == true;

  /// true kalau sudah dicek dan jelas tidak ada voice Jepang.
  bool get japaneseVoiceChecked => _japaneseReady != null;

  /// Kecepatan bicara. Android memakai rentang 0.0-1.0 dengan 0.5 = normal.
  /// iOS/macOS memakai skala berbeda (AVSpeechUtterance), jadi angkanya
  /// dinaikkan sedikit supaya tetap terdengar jelas.
  static double _rate(bool slow) {
    try {
      if (!Platform.isLinux && (Platform.isIOS || Platform.isMacOS)) {
        return slow ? 0.35 : 0.50;
      }
    } catch (_) {}
    return slow ? 0.30 : 0.50;
  }

  /// Menyiapkan mesin sekali saja dan mengecek apakah voice Japanese ada.
  /// Hasil di-cache supaya tidak memanggil TTS berulang kali.
  Future<bool> ensureAvailable() async {
    if (_japaneseReady != null) return _japaneseReady!;
    final tts = _engine;
    if (tts == null) {
      _japaneseReady = false;
      return false;
    }
    try {
      await tts.awaitSpeakCompletion(true);
      await tts.setVolume(1.0);
      await tts.setLanguage('ja-JP');
      final available = await tts.isLanguageAvailable('ja-JP');
      _japaneseReady = available == true;
    } catch (_) {
      _japaneseReady = false;
    }
    return _japaneseReady!;
  }

  /// Membacakan [text] sebagai satu ucapan. [slow]=true memakai kecepatan
  /// lambat. Selalu berhenti dulu supaya tidak tumpang tindih.
  /// Mengembalikan false kalau TTS tidak tersedia atau gagal.
  Future<bool> speak(String text, {required bool slow}) async {
    if (text.trim().isEmpty) return false;
    if (!await ensureAvailable()) return false;
    final tts = _engine;
    if (tts == null) return false;
    try {
      await tts.stop();
      await tts.setSpeechRate(_rate(slow));
      await tts.speak(text);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await _tts?.stop();
    } catch (_) {}
  }

  /// Hanya untuk pengujian: menyetel status ketersediaan tanpa TTS sungguhan.
  @visibleForTesting
  void debugSetJapaneseAvailable(bool? value) => _japaneseReady = value;
}