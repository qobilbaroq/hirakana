# Panduan rilis Kana Quest (Android)

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
Di `pubspec.yaml`: `version: 1.2.0+3` = nama versi `1.2.0`, kode build `3`.
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
- [ ] Suara huruf dan suara kata keluar (aset audio ikut ter-bundle).
- [ ] Latihan menulis: panduan goresan dan Replay jalan.
- [ ] Ganti tema Light/Dark di Settings, semua layar berubah warna.
- [ ] Putar layar: tetap potret.
- [ ] Tutup app saat sesi berjalan, buka lagi: progres tidak hilang.
- [ ] Matikan internet: semua fitur tetap jalan (app sepenuhnya offline).

## 7. Catatan untuk Play Store
- App tidak meminta permission apa pun dan tidak mengirim data ke mana pun. Itu memudahkan isian
  "Data safety" (tidak ada data yang dikumpulkan atau dibagikan).
- Kredit pihak ketiga yang perlu dipertahankan (sudah tampil di Settings dan layar Practice):
  KanjiVG (CC BY-SA 3.0), suara huruf `veardk/just-gojuon` (MIT), suara kata HTS voice tohoku-f01 (CC BY 4.0).
- Lisensi rekaman suara huruf asalnya tidak dijelaskan di repo sumbernya. Untuk rilis publik,
  sebaiknya pastikan status lisensinya, atau ganti dengan rekaman milikmu sendiri
  (taruh dengan nama file yang sama di `assets/audio/`).
- Siapkan sendiri untuk halaman toko: screenshot, deskripsi, dan ikon 512x512
  (pakai `assets/icon/icon.png` yang diperkecil).
