import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AndroidManifest mendeklarasikan TTS_SERVICE (syarat flutter_tts di Android 11+)', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    // Salah ketik "TTSSERVICE" (tanpa garis bawah) membuat mesin suara tidak
    // terlihat, sehingga TTS tidak pernah tersedia di HP.
    expect(manifest, contains('android.intent.action.TTS_SERVICE'));
    expect(manifest, isNot(contains('android.intent.action.TTSSERVICE')));
  });
}
