# Kana Quest

Aplikasi belajar Hiragana & Katakana. Flutter, offline-first, multi-platform.

Supported: **Android, Linux, Windows, macOS, iOS, Web**.

## Cara menjalankan

```bash
flutter pub get
flutter run -d <device>
```

Contoh: `flutter run -d linux`, `flutter run -d chrome`, `flutter run -d <id-android>`.

## Build

```bash
flutter build apk --release        # Android
flutter build appbundle --release  # Android (Play Store)
flutter build linux --release      # Linux
flutter build windows --release    # Windows
flutter build macos --release      # macOS
flutter build web --release        # Web
flutter build ipa --release        # iOS (harus di macOS + Xcode)
```

Hasil build ada di `build/<platform>/`. Untuk Android, file APK-nya:

```
build/app/outputs/flutter-apk/app-release.apk
```

## Isi

- 104 huruf per script: dasar (46), dakuten, handakuten, dan kombinasi (きゃ dst.).
- Suara: 104 file mp3 di `assets/audio/<romaji>.mp3` (dibuat dengan Open JTalk),
  dipakai bersama oleh hiragana dan katakana. Tidak butuh TTS HP / internet.
- Urutan goresan: `assets/strokes/kana_strokes.json` dari KanjiVG
  (CC BY-SA 3.0, https://kanjivg.tagaini.net). Dipakai untuk panduan bernomor,
  animasi Replay, dan perbandingan hasil tulisan.

## Database per platform

Progres belajar disimpan di SQLite lokal. Supaya satu kode bisa jalan di semua
platform, pemilihan "sqlite factory"nya dipisah di
`lib/core/storage/database_factory.dart` (memoakai conditional import):

| Platform | Implementasi | Lokasi database |
| --- | --- | --- |
| Android / iOS / macOS | `sqflite` (plugin native bawaan Flutter) | folder databases aplikasi |
| Linux / Windows | `sqflite_common_ffi` (SQLite dari `libsqlite3` sistem) | `getApplicationSupportDirectory()` |
| Web | `sqflite_common_ffi_web` (SQLite WASM, varian NoWebWorker) | IndexedDB |

Jadi di Android/iOS/macOS perilakunya persis seperti aplikasi Flutter biasa —
`databaseFactory` di-set sendiri oleh `SqflitePlugin.registerWith()` saat
plugin terdaftar, dan kode kita tidak menyentuhnya.

### Catatan web

- `web/sqlite3.wasm` **sudah ikut** di dalam repo, jadi tidak perlu unduh lagi.
  Kalau hilang / sqlite3 sudah di-upgrade, ambil dari
  [sqlite3.dart releases](https://github.com/simolus3/sqlite3.dart/releases).
- Versi ini memakai `databaseFactoryFfiWebNoWebWorker` (SQLite jalan di thread
  utama, bukan shared worker), karena `web/sqflite_sw.js` tidak bisa dibangun
  oleh `dart run sqflite_common_ffi_web:setup` — tool `webdev`-nya belum
  kompatibel dengan Dart SDK 3.10 yang dipakai sekarang. Datanya tetap
  persisten di IndexedDB. Kalau Dart SDK sudah lebih baru, tinggal ganti
  `databaseFactoryFfiWebNoWebWorker` -> `databaseFactoryFfiWeb`.

## Requirement Linux

Semua paket runtime sudah cukup, tapi untuk **compile** Linux desktop
dibutuhkan header GStreamer (dipakai oleh plugin `audioplayers`):

```bash
sudo dnf install -y gstreamer1-devel
```

Tanpa itu, `flutter build linux` berhenti dengan
`The following required packages were not found: - gstreamer-1.0`.
Semua versi `audioplayers` (termasuk yang terbaru) memakai GStreamer untuk
backend audio di Linux, jadi paket devel ini wajib ada.

Audio di Linux juga butuh PulseAudio/PipeWire aktif supaya suaranya terdengar.

Lokasi data di Linux: `~/.local/share/dev.qobilul.kana_quest/kana_quest.db`
(path_provider memakai application id dari `linux/CMakeLists.txt`).

### Troubleshooting

`flutter build linux` / `flutter run` gagal dengan:

```
file INSTALL cannot copy file ".../kana_quest" to "/usr/local/kana_quest": Permission denied.
```

Artinya `CMAKE_INSTALL_PREFIX` ikut memakai default CMake (`/usr/local`).
Normalnya template Flutter mengaturnya sendiri lewat penjaga
`CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT`, tapi penjaga itu hanya aktif
pada cache CMake yang benar-benar baru — begitu `build/linux` pernah ada,
prefix `/usr/local` ikut tersimpan dan dipakai lagi.

Di proyek ini `linux/CMakeLists.txt` sudah dipaksa memakai folder bundle
(`set(CMAKE_INSTALL_PREFIX "${BUILD_BUNDLE_DIR}" ... FORCE)`), jadi tidak
perlu tindakan manual. Kalau folder `linux/` pernah di-regenerate dan error ini
muncul lagi, perbaikannya cukup:

```bash
rm -rf build/linux
```

## Opsional: font Noto Sans JP

Tanpa font ini, huruf Jepang memakai font sistem Android. Untuk tampilan yang
seragam, taruh file font di `assets/fonts/` dan daftarkan dengan family
`Noto Sans JP` di `pubspec.yaml`.

## Struktur

```
lib/
  app/            router, theme
  core/           audio, storage (database factory per platform), widgets
  data/           model, repository, seed kana + data goresan
  features/       home, learn, practice, progress, writing, shell
```