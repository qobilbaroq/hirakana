# Panduan rilis Kana Quest melalui GitHub (Android)

Isi: [deskripsi rilis](#deskripsi-rilis) - [catatan rilis](#catatan-rilis) -
langkah rilis dan pembaruan APK (bagian 1-7).

## Deskripsi rilis

Salin dan sesuaikan untuk deskripsi GitHub Release.

**Kana Quest: belajar Hiragana & Katakana dengan tenang.**
Tanpa akun, tanpa iklan, tanpa hukuman kalau kamu melewatkan sehari. Fitur belajar bisa dipakai offline.

- **208 huruf**: Hiragana dan Katakana lengkap (dasar, dakuten, handakuten, kombinasi).
- **Pilih sendiri huruf yang dipelajari**, huruf baru tidak masuk otomatis.
- **Flashcard** dengan pengulangan berjarak: ingat dulu, baru buka jawabannya.
- **Kuis** 5 jenis, termasuk membedakan hiragana vs katakana dan latihan huruf yang sering tertukar.
- **Latihan menulis** dengan jari: panduan goresan bernomor, animasi urutan goresan, dan perbandingan hasil.
- **Latihan baca**: tebak romaji dari 1.272 kata sungguhan yang semuanya punya arti Bahasa Indonesia dan
  rekaman utuh. Tiap soal adalah kata; kalau huruf aktif masih sedikit, kata diulang supaya sesi penuh.
- **Suara** untuk setiap huruf dan setiap kata, normal dan lambat, tersedia offline.
- **Kemajuan nyata**: penguasaan diukur lintas sesi, bukan sekali jawab benar.
- **Panjang sesi dan target harian bisa diatur.**
- **Tema Terang, Gelap, dan AMOLED** dengan palet hangat yang nyaman di mata.
- Offline-first dan privat: internet hanya dipakai untuk memeriksa serta mengunduh pembaruan dari GitHub.

## Catatan rilis

### 1.3.1 (kode build 5)
- Arti kosakata ditampilkan terpisah dari kategori dan aktif secara default.
- Settings memeriksa rilis GitHub, menampilkan catatan pembaruan, lalu mengunduh APK yang cocok untuk perangkat
  dan membuka installer Android.

### 1.3.0 (kode build 4)
- Panjang sesi bisa diatur di Settings (10 sampai 60; minimal 10). Huruf diulang kalau huruf aktif lebih sedikit.
- Latihan baca dirombak: **setiap soal adalah kata sungguhan** dengan rekaman utuh; tidak lagi ada soal
  rangkaian huruf acak atau satu huruf. Tidak lagi menanyakan arti
  (arti bisa ditampilkan setelah jawaban benar lewat Settings).
- Daftar kata disusun ulang jadi 729 kata kurasi yang **semuanya punya arti Bahasa Indonesia dan rekaman
  utuh**, tetap merata untuk semua tahap huruf. Kata yang belum pernah muncul diutamakan supaya tidak
  berulang. Pengecoh dibuat dengan mengganti satu huruf.
- Semua 729 kata punya rekaman suara normal dan lambat; tidak ada lagi kata yang dibunyikan huruf demi huruf.
- Warna mode gelap dirapikan: tombol utama tidak lagi krem yang menyilaukan; AMOLED memakai permukaan hangat
  yang selaras dengan latar hitam. Snackbar, dialog, switch, dan slider ikut palet.
- Tabel "All characters" di Progress dan layar Choose letters kini selebar layar dengan kolom sejajar.
- Database naik ke versi 3 (riwayat kata). Progres lama tetap aman.

### 1.2.0 (kode build 3)
- Ikon app, splash screen terang dan gelap, layar dikunci potret, panduan rilis.
- Daftar kata dan rekaman kata diperbanyak.

### Sebelumnya
- Pilih huruf sendiri, mode gelap dan AMOLED, Settings, pasangan huruf yang sering tertukar,
  latihan baca kata, suara asli per huruf (normal dan lambat).

Cara menulis catatan rilis berikutnya: tambahkan bagian baru di atas (versi, kode build, daftar perubahan
yang terlihat oleh pengguna), lalu naikkan `version` di `pubspec.yaml` (lihat bagian 4).

Semua perintah dijalankan di root proyek Flutter. Folder `android/` dibuat oleh `flutter create`,
jadi langkah 1 dan 3 mengubah file milikmu sendiri.

## 1. Nama app dan application ID

Application ID harus tetap sama di semua versi agar Android mengenali APK baru sebagai pembaruan aplikasi ini.

Cara cepat dengan paket `rename`:
```
dart pub global activate rename
rename setAppName --targets android --value "Kana Quest"
rename setBundleId --targets android --value "com.kanaquest.app"
```
Ganti `com.kanaquest.app` dengan ID milikmu sendiri (format `com.namakamu.kanaquest`).
Pilih sekali dan jangan diganti lagi setelah dipublikasikan.

Kalau `rename` bermasalah, ubah manual:
- `android/app/src/main/AndroidManifest.xml`: `android:label="Kana Quest"`
- `android/app/build.gradle(.kts)`: `namespace` dan `applicationId`
- pindahkan folder `MainActivity.kt` agar sesuai package baru, lalu ubah baris `package ...` di file itu.

## 2. Ikon dan splash
Sudah dikonfigurasi di `pubspec.yaml`:
```
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```
Jalankan ulang setiap kali file di `assets/icon/` diganti.

## 3. Tanda tangan rilis (signing)

Buat keystore SEKALI dan simpan baik-baik (kalau hilang, update app tidak bisa dipublikasikan lagi):
```
keytool -genkey -v -keystore ~/kanaquest-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
Buat `android/key.properties` (JANGAN di-commit ke git):
```
storePassword=<password keystore>
keyPassword=<password key>
keyAlias=upload
storeFile=/path/lengkap/ke/kanaquest-upload.jks
```
Tambahkan ke `.gitignore`: `android/key.properties` dan `*.jks`.

Hubungkan di `android/app/build.gradle.kts` (proyek Flutter terbaru memakai Kotlin DSL):
```kotlin
import java.io.FileInputStream
import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ... isi lain biarkan ...
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```
Kalau proyekmu memakai `build.gradle` (Groovy), sesuaikan sintaksnya, isinya sama:
baca `key.properties`, buat `signingConfigs.release`, dan pakai di `buildTypes.release`.
Aturan yang berlaku juga di dokumentasi Flutter "Build and release an Android app".

## 4. Naikkan versi
Di `pubspec.yaml`: `version: 1.3.1+5` = nama versi `1.3.1`, kode build `5`.
Setiap rilis harus memakai versi dan kode build yang lebih besar daripada rilis sebelumnya.

## 5. Build
```
flutter clean
flutter pub get
flutter build apk --release --split-per-abi      # APK per arsitektur, dipilih sesuai perangkat
```
Hasil APK ada di `build/app/outputs/flutter-apk/`.

## 6. Unggah rilis GitHub dan pembaruan APK

1. Buat GitHub Release dengan tag yang sama dengan versi di `pubspec.yaml`, misalnya `v1.3.1`.
2. Lampirkan APK dari folder `build/app/outputs/flutter-apk/`. Nama aset harus mempertahankan nama ABI,
   misalnya `kanaquest-1.3.1-arm64-v8a.apk` dan `kanaquest-1.3.1-armeabi-v7a.apk`.
   APK universal juga didukung jika namanya mengandung `universal`.
3. Pertahankan application ID dan sertifikat tanda tangan yang sama di setiap APK. Android menolak
   pembaruan jika APK baru ditandatangani dengan kunci berbeda.
4. Isi catatan rilis GitHub. Aplikasi menampilkan nama versi dan catatan rilis di Settings, lalu tombol
   **Unduh & instal** mengambil APK langsung dari GitHub. Android tetap meminta izin pemasangan dari
   Kana Quest (sekali saja) dan konfirmasi pemasangan.

Versi yang sudah terpasang sebelum fitur pembaruan tersedia tidak dapat memeriksa pembaruan otomatis.
Untuk peningkatan pertama, pasang APK versi 1.3.1 secara manual; versi selanjutnya dapat diunduh dari Settings.

## 7. Cek sebelum dibagikan (pakai build rilis, bukan debug)
- [ ] Ikon dan nama app tampil benar di launcher; splash terang dan gelap muncul.
- [ ] Suara huruf dan suara kata keluar (aset audio ikut ter-bundle), termasuk di Reading practice.
- [ ] Ganti ke AMOLED: latar hitam, dan tidak ada blok terang (tombol, snackbar, dialog) yang menyilaukan.
- [ ] Settings -> Session length 20: sesi benar-benar 20 soal.
- [ ] Latihan menulis: panduan goresan dan Replay jalan.
- [ ] Ganti tema Light/Dark di Settings, semua layar berubah warna.
- [ ] Putar layar: tetap potret.
- [ ] Tutup app saat sesi berjalan, buka lagi: progres tidak hilang.
- [ ] Matikan internet: fitur belajar tetap jalan; pemeriksaan pembaruan memerlukan internet.
- [ ] Settings memeriksa rilis terbaru dan mengunduh APK dari GitHub; installer Android dapat membuka APK
  dan menawarkan peningkatan untuk versi lama yang ditandatangani dengan kunci yang sama.
- Kredit pihak ketiga yang perlu dipertahankan (sudah tampil di Settings dan layar Practice):
  KanjiVG (CC BY-SA 3.0), suara huruf `veardk/just-gojuon` (MIT), suara kata HTS voice tohoku-f01 (CC BY 4.0).
  Daftar kata adalah karya sendiri (729 kata kurasi), jadi tidak ada kewajiban lisensi data.
- Lisensi rekaman suara huruf asalnya tidak dijelaskan di repo sumbernya. Untuk rilis publik,
  sebaiknya pastikan status lisensinya, atau ganti dengan rekaman milikmu sendiri
  (taruh dengan nama file yang sama di `assets/audio/`).
- Ukuran aset audio sekitar 19 MB; APK per arsitektur mengurangi ukuran unduhan.
