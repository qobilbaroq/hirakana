# Kana Quest

Aplikasi belajar **Hiragana & Katakana** yang tenang dan ringan. Offline-first, tanpa akun,
tanpa iklan, tanpa hukuman kalau kamu melewatkan sehari. Dibuat dengan Flutter.

Platform: **Android, iOS, Linux, Windows, macOS, Web**.

<!-- Tambahkan screenshot di docs/screenshots/, lalu tampilkan di sini, contoh:
<p align="center">
  <img src="docs/screenshots/home.png" width="220" />
  <img src="docs/screenshots/flashcard.png" width="220" />
  <img src="docs/screenshots/reading.png" width="220" />
</p>
-->

## Fitur

**Belajar**
- 208 huruf: 104 Hiragana + 104 Katakana (dasar, dakuten, handakuten, dan kombinasi seperti きゃ).
- **Pilih sendiri huruf yang dipelajari.** Huruf baru tidak pernah masuk otomatis.
- **Flashcard** dengan pengulangan berjarak (spaced repetition): jawaban disembunyikan dulu,
  nilai dengan *Again* / *Got it*.
- **Kuis** 5 jenis: kana ke bunyi, bunyi ke kana, ketik romaji, hiragana vs katakana,
  dan *look-alike drill* untuk huruf yang sering tertukar.
- **Latihan menulis** dengan jari: panduan goresan bernomor, animasi *Replay*, dan perbandingan hasil.
- **Latihan baca**: tebak romaji dari 1.272 kata sungguhan yang **semuanya punya arti Bahasa Indonesia**
  dan punya rekaman utuh. Tidak ada soal rangkaian huruf acak — tiap soal adalah kata sungguhan.
  Kalau huruf aktif masih sedikit, kata diulang supaya sesi tetap penuh.
- **Saring kosakata per tingkat**: Practice → Words, pilih *All words* / *N5–N4* / *N3*.
- **Panjang sesi bisa diatur** (minimal 10, sampai 60).

**Suara (offline)**
- Rekaman suara untuk setiap huruf, versi normal dan lambat.
- Rekaman kata utuh untuk ribuan kata; kata lain dibunyikan huruf demi huruf.
- Pola putar ulang: normal, normal, lambat (bisa diganti di Settings).

**Kemajuan**
- Penguasaan per huruf (dikuasai setelah benar di beberapa sesi berbeda, bukan sekali saja).
- Tabel gojuon penguasaan, pasangan huruf yang sering tertukar, dan riwayat sesi.
- Target harian yang bisa diatur.

**Tampilan**
- Tema Terang, Gelap, dan **AMOLED** (hitam sejati), atau ikut sistem.
- Palet hangat yang sama di semua tema; tanpa blok terang yang menyilaukan di mode gelap.

## Mulai cepat

Butuh Flutter SDK (lihat `environment` di `pubspec.yaml`).

```bash
flutter pub get
flutter run -d <device>
```

Contoh: `flutter run -d linux`, `flutter run -d chrome`, `flutter run -d <id-android>`.

Cek kualitas kode:

```bash
flutter analyze
flutter test
```

## Build

```bash
flutter build apk --release --split-per-abi   # Android (APK per arsitektur, lebih kecil)
flutter build linux --release                 # Linux
flutter build windows --release               # Windows
flutter build macos --release                 # macOS
flutter build web --release                   # Web
flutter build ipa --release                   # iOS (harus di macOS + Xcode)
```

Hasil build ada di `build/<platform>/`. APK Android: `build/app/outputs/flutter-apk/`.
Di Android, Settings dapat memeriksa rilis GitHub terbaru dan mengunduh APK yang cocok
langsung untuk dipasang. Panduan lengkap rilis dan pembaruan Android ada di **[RELEASE.md](RELEASE.md)**.

## Dokumentasi

| Dokumen | Isi |
| --- | --- |
| [DOKUMENTASI.md](DOKUMENTASI.md) | Cara kerja app: sistem belajar, antrean sesi, kuis, latihan baca, layar, aset, database, batasan |
| [RELEASE.md](RELEASE.md) | Panduan rilis APK Android melalui GitHub dan catatan rilis |

## Struktur proyek

```
lib/
  app/        router dan tema (palet terang / gelap / AMOLED)
  core/       audio, pengaturan, storage (database per platform), widget bersama
  data/       model, repository (progres, kata), data huruf, goresan, kata
  features/   home, learn, practice, progress, settings, writing, words, shell
assets/
  audio/      suara huruf (normal + slow) dan suara kata (words/)
  strokes/    urutan goresan KanjiVG
  data/       daftar kata (words.tsv)
  icon/       ikon dan splash
test/         unit dan widget test
```

## Data, suara, dan lisensi

| Sumber | Dipakai untuk | Lisensi |
| --- | --- | --- |
| [KanjiVG](https://kanjivg.tagaini.net) | urutan goresan | CC BY-SA 3.0 |
| [veardk/just-gojuon](https://github.com/veardk/just-gojuon) | rekaman suara huruf | MIT (asal rekaman tidak dijelaskan di repo sumbernya) |
| HTS voice tohoku-f01, Tohoku University ICN Lab | suara kata (sintesis Open JTalk), termasuk kosakata N5–N4/N3 | CC BY 4.0 |

Daftar kata (1.272 kata) adalah **karya sendiri** — ditulis tangan untuk app ini, tanpa impor dari
kamus pihak ketiga, jadi tidak ada kewajiban lisensi data.

Kredit ini juga tampil di dalam app (Settings dan layar Practice). Kalau kamu membagikan app ini
secara publik, pertahankan kredit tersebut.

## Catatan platform

<details>
<summary><b>Database per platform</b></summary>

Progres belajar disimpan di SQLite lokal. Supaya satu kode bisa jalan di semua platform,
pemilihan "sqlite factory"-nya dipisah di `lib/core/storage/database_factory.dart`
(conditional import):

| Platform | Implementasi | Lokasi database |
| --- | --- | --- |
| Android / iOS / macOS | `sqflite` (plugin native bawaan Flutter) | folder databases aplikasi |
| Linux / Windows | `sqflite_common_ffi` (SQLite dari `libsqlite3` sistem) | `getApplicationSupportDirectory()` |
| Web | `sqflite_common_ffi_web` (SQLite WASM, varian NoWebWorker) | IndexedDB |

Di Android/iOS/macOS perilakunya seperti aplikasi Flutter biasa: `databaseFactory` di-set sendiri
oleh `SqflitePlugin.registerWith()` dan kode kita tidak menyentuhnya.

</details>

<details>
<summary><b>Web</b></summary>

- `web/sqlite3.wasm` **sudah ikut** di dalam repo. Kalau hilang atau sqlite3 di-upgrade, ambil dari
  [sqlite3.dart releases](https://github.com/simolus3/sqlite3.dart/releases).
- Versi ini memakai `databaseFactoryFfiWebNoWebWorker` (SQLite jalan di thread utama), karena
  `web/sqflite_sw.js` tidak bisa dibangun oleh `dart run sqflite_common_ffi_web:setup` (tool `webdev`
  belum kompatibel dengan Dart SDK 3.10). Data tetap persisten di IndexedDB. Kalau Dart SDK sudah
  lebih baru, ganti `databaseFactoryFfiWebNoWebWorker` menjadi `databaseFactoryFfiWeb`.

</details>

<details>
<summary><b>Linux: requirement dan troubleshooting</b></summary>

Untuk **compile** Linux desktop dibutuhkan header GStreamer (dipakai plugin `audioplayers`):

```bash
sudo dnf install -y gstreamer1-devel
```

Tanpa itu, `flutter build linux` berhenti dengan
`The following required packages were not found: - gstreamer-1.0`.
Audio di Linux juga butuh PulseAudio/PipeWire aktif.

Lokasi data: `~/.local/share/dev.qobilul.kana_quest/kana_quest.db`.

Kalau `flutter build linux` gagal dengan
`file INSTALL cannot copy file ".../kana_quest" to "/usr/local/kana_quest": Permission denied`,
itu karena `CMAKE_INSTALL_PREFIX` memakai default CMake. Di proyek ini `linux/CMakeLists.txt` sudah
dipaksa memakai folder bundle. Kalau folder `linux/` pernah di-regenerate dan error muncul lagi:

```bash
rm -rf build/linux
```

</details>

<details>
<summary><b>Opsional: font Noto Sans JP</b></summary>

Tanpa font ini, huruf Jepang memakai font sistem. Untuk tampilan yang seragam, taruh file font di
`assets/fonts/` dan daftarkan dengan family `Noto Sans JP` di `pubspec.yaml`.

</details>
