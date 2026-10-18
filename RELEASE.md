# Panduan rilis Kana Quest (Android)

Isi: [fitur untuk halaman toko](#fitur-untuk-halaman-toko-dan-deskripsi-rilis) -
[catatan rilis](#catatan-rilis) - langkah rilis (bagian 1-7).

## Fitur untuk halaman toko dan deskripsi rilis

Salin dan sesuaikan untuk deskripsi Play Store / GitHub Release.

**Kana Quest: belajar Hiragana & Katakana dengan tenang.**
Tanpa akun, tanpa iklan, tanpa hukuman kalau kamu melewatkan sehari. Semua fitur jalan offline.

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
- Ringan dan privat: tidak meminta izin apa pun dan tidak mengirim data.

## Catatan rilis

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

Default hasil `flutter create` adalah nama `kana_quest` dan ID `com.example.kana_quest`.
ID berawalan `com.example` **tidak diterima Google Play**, ganti sebelum rilis.

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
Di `pubspec.yaml`: `version: 1.3.0+4` = nama versi `1.3.0`, kode build `4`.
Setiap upload ke Play Store butuh kode build (angka setelah `+`) yang lebih besar dari sebelumnya.

## 5. Build
```
flutter clean
flutter pub get
flutter build apk --release --split-per-abi      # APK untuk dibagikan langsung (lebih kecil per arsitektur)
flutter build appbundle --release                # file .aab untuk Google Play
```
Hasil: `build/app/outputs/flutter-apk/` dan `build/app/outputs/bundle/release/`.

## 6. Cek sebelum dibagikan (pakai build rilis, bukan debug)
- [ ] Ikon dan nama app tampil benar di launcher; splash terang dan gelap muncul.
- [ ] Suara huruf dan suara kata keluar (aset audio ikut ter-bundle), termasuk di Reading practice.
- [ ] Ganti ke AMOLED: latar hitam, dan tidak ada blok terang (tombol, snackbar, dialog) yang menyilaukan.
- [ ] Settings -> Session length 20: sesi benar-benar 20 soal.
- [ ] Latihan menulis: panduan goresan dan Replay jalan.
- [ ] Ganti tema Light/Dark di Settings, semua layar berubah warna.
- [ ] Putar layar: tetap potret.
- [ ] Tutup app saat sesi berjalan, buka lagi: progres tidak hilang.
- [ ] Matikan internet: semua fitur tetap jalan (app sepenuhnya offline).

## 7. Catatan untuk Play Store
- App tidak meminta permission apa pun dan tidak mengirim data ke mana pun. Itu memudahkan isian
  "Data safety" (tidak ada data yang dikumpulkan atau dibagikan).
- Kredit pihak ketiga yang perlu dipertahankan (sudah tampil di Settings dan layar Practice):
  KanjiVG (CC BY-SA 3.0), suara huruf dan kata HTS voice tohoku-f01 (CC BY 4.0).
  Daftar kata adalah karya sendiri (729 kata kurasi), jadi tidak ada kewajiban lisensi data.
- Lisensi rekaman suara huruf asalnya tidak dijelaskan di repo sumbernya. Untuk rilis publik,
  sebaiknya pastikan status lisensinya, atau ganti dengan rekaman milikmu sendiri
  (taruh dengan nama file yang sama di `assets/audio/`).
- Ukuran: aset audio sekitar 19 MB. Unggah `.aab` ke Play Store (ukuran unduhan per perangkat lebih kecil)
  atau bagikan APK `--split-per-abi`.
- Siapkan sendiri untuk halaman toko: screenshot, deskripsi, dan ikon 512x512
  (pakai `assets/icon/icon.png` yang diperkecil).
