# Handoff — Kana Quest (sesi desain `develop-v03`)

Dokumen ini untuk melanjutkan pekerjaan di sesi OpenCode baru. Baca juga
`DOKUMENTASI.md` untuk detail fitur dan arsitektur.

## Status repo

- Remote: `github.com/qobilbaroq/hirakana`
- `main`: `fd729d0` — rilis 1.4.0 (tag `v1.4.0`)
- `develop-v02`: `3e20562` — perubahan fitur, sudah di-push
- `develop-v03`: `132965b` — branch desain, dibuat dari v02, sudah di-push;
  **redesign sudah diimplementasikan tetapi belum di-commit** (working tree kotor)
- Versi `pubspec.yaml`: `1.4.0+7` (jangan naikkan kecuali menyiapkan rilis)
- Redesign belum di-commit/di-push. Review diff dulu, lalu commit hanya dengan
  persetujuan user.

## Aturan branch

- Perubahan fitur/logika/data → `develop-v02`.
- Perubahan desain/tampilan keseluruhan → `develop-v03`.
- `main` hanya untuk rilis; jangan commit fitur langsung ke `main`.
- Jangan ubah `RELEASE.md`; catatan rilis hanya di GitHub Release.
- Jangan push atau rilis tanpa persetujuan user.

## Yang sudah selesai

- 1.4.0: Meaning practice, Word history, DB v4, kuis 5 → 3 jenis, popup pembaruan ringkas.
- Writing: romaji huruf contoh tersembunyi sampai **Check**, lalu muncul.
- Data: 37 baris `words.tsv` diperbaiki (arti, kategori, cara baca); 8 audio di-rename.
- Build the word: romaji & kana (`build_romaji` / `build_kana`), pilihan berbentuk grid
  kecil maksimal dua baris supaya tidak perlu scroll.
- Practice: hanya latihan kana + Writing; latihan kata pindah ke tab **Words**.
- Progress: label sesi `build_romaji` / `build_kana` di Recent sessions.
- Tes: **132 lulus**; `flutter analyze` **7 info baseline** (bukan error).

## Desain `develop-v03` (belum di-commit)

- IA baru 4 tab: **Kana, Practice, Words, Profile**.
  - **Kana** menggantikan Learn: grid 5 kolom, pencarian, filter script/romaji,
    indikator mastery kaca, detail huruf, dan sheet pilihan mode belajar.
  - **Practice** hanya latihan kana: Flashcards, Quick quiz, Writing,
    Choose letters, dan 3 jenis Recognition.
  - **Words** memuat Reading, Meaning, Build the word, Word history, dan filter
    kosakata.
  - **Profile** menggabungkan Home + Progress: streak, goal harian, milestone
    5/25/50/100, total sesi, kata yang sudah ditemui, mastery per script,
    kartu progres 2×2, review weak/confusion, dan recent sessions. Ikon gerigi
    membuka Settings.
- Tema default **gelap**; pilihan **System / Light / Dark**. **AMOLED dihapus**
  karena mode gelap sekarang memakai gradien latar, bukan hitam sejati.
- Palet monokrom netral (sage/clay hanya sebagai aksen tipis); pilihan aktif
  memakai abu-abu, bukan hitam. Tombol utama tetap inverted (`ink` di atas
  `paper`).
- Latar semua layar memakai `AppBackground`: gradien bersih **tanpa texture
  noise**. Di gelap, stop gradien `#868686 → #4B4B4B → #2E2E2E → #201F1F →
  #181818 → #151414 → #111111` dicampur 60% dengan paper agar teks tetap
  terbaca; di terang tetap `#F8F8F4 → #E8E8E2`. Scaffold/AppBar transparan.
- Navigasi bawah kembali ke pill mengambang **solid** (tanpa lengkung, tanpa
  `BackdropFilter`): latar `AppColors.white`, border tipis, radius 26, tinggi 70,
  margin samping 20, bayangan lembut. Tombol terpilih 54×42 dan yang lain 42×42;
  ikon 20 px (glyph 19 px). Ikon: `あ` (Kana), grid 4 kotak (Practice), buku
  (Words), person (Profile). Pill terpilih memakai `AppColors.active` solid di
  kedua tema.
- Animasi dibuat halus dan singkat: transisi halaman fade + geser tipis lewat
  `AppPageTransitionsBuilder`; pindah tab memudarkan/menggeser isi `IndexedStack`
  240 ms tanpa kehilangan state; kartu menu (`ModeCard`) masuk dengan fade +
  geser 240 ms; ikon navigasi terpilih membesar 180 ms.
- Mastery kana memakai 4 pip kaca (bukan tiga titik / badge `M`):
  - huruf aktif yang belum pernah benar: kaca sangat tipis;
  - langkah 1–3: isi kaca makin kuat;
  - langkah 4 (dikuasai): kembali ke latar, hanya border kaca tipis.
  Langkah diturunkan read-only dari `masteryLevel` + `sessionsCorrect`; tidak ada
  migrasi DB.
- **Hanya huruf kana** yang memakai liquid glass: sel aktif/terpelajari dan
  pilihan huruf di Choose letters memakai `activeGlassGradient`. Kartu
  (`AppCard`/`ModeCard`), pencarian, filter, kontrol bawah, dan navigasi memakai
  permukaan solid biasa dengan border tipis. `GlassSurface` sudah dihapus.
- Kartu memakai radius **16** (sheet besar 24, tombol 14); tidak lagi sangat
  membulat. Ikon memakai `IconTile` solid-tinted, bukan kaca.
- Kontrol bawah Kana tetap mengambang: quiz, pil **Hiragana/Katakana**, dan
  toggle romaji, tetapi sekarang diletakkan **rapat di atas navigasi** (8 px).
  Padding bawah grid dirapatkan supaya tidak ada ruang kosong berlebihan. Tab
  lain memakai `AppSpacing.navClearance`.
- Quiz memakai Dismiss pill, progress segmen, dan 2×2 kartu jawaban. Progress
  sesi memakai posisi 1-based supaya segmen pertama langsung terisi.
- Writing: romaji tetap tersembunyi sampai **Check**. Build the word tetap
  berupa grid pilihan maksimal dua baris.
- Baris kombinasi (きゃ/きゅ/きょ) disejajarkan ke ritme 5 kolom; ukuran huruf
  kombinasi diperkecil di grid dan detail sheet supaya tidak overflow.
- Tombol disabled memakai `sand` + `muted` agar label tetap terbaca.
- Semantics kustom memakai `excludeSemantics` agar teks tidak dibaca ganda.
- String UI baru berbahasa Inggris; arti kata tetap Bahasa Indonesia (data).
- Visual check 360×720 sudah dilakukan lewat golden sementara (sudah dihapus).
- `test/main_shell_test.dart` mengecek 4 tab + Profile scroll tanpa overflow.
- `test/practice_screen_test.dart` mengecek menu Practice dan Words.
- `test/theme_palette_test.dart` mengecek palet, kontras, scaffold transparan,
  dan tidak ada AMOLED.
- `test/mastery_indicator_test.dart` mengecek 4 langkah, mapping level lama, dan
  tidak overflow di tile sempit.

## Yang belum diuji di HP

- Tampilan popup pembaruan.
- Migrasi DB v3 → v4 pada data lama.
- Dua menu Practice baru + Build the word.
- Tampilan Writing (romaji muncul hanya setelah Check).
- Navigasi pill solid + gradient, Profile (streak/milestone), Kana
  grid/detail sheet, dan Words.
- Quiz 2×2 + progress 1-based, serta tombol disabled di layar kecil.
- Tema gelap default dan pergantian System/Light/Dark setelah AMOLED dihapus.
- Belum ada keystore rilis; APK masih ditandatangani kunci debug.

## Catatan data

- `assets/data/words.tsv`: 1.272 kata; 1.271 bisa dipakai di Build the word.
- `ちょうちょ` tertulis dengan romaji `chouchou` (tidak konsisten) sehingga dilewati
  di Build. Belum diubah. Perbaikan aman: ubah teksnya menjadi `ちょうちょう`
  (bacaan dan audio `chouchou` tetap valid), lalu samakan `tools/vocab_source.txt`
  dan `tools/level_map.tsv`.
- Backup data lama: `~/Code/kana_quest_backup/2026-10-20-words/`.
- `words_fixed_romaji.tsv` di folder Downloads adalah sumber data resmi user;
  jangan ubah tanpa izin.

## Langkah berikutnya

1. Review diff redesign bersama user; belum ada commit desain.
2. Setelah disetujui, commit di `develop-v03` (jangan merge ke v02/main tanpa izin).
3. Uji di HP: 4 tab, Profile, Kana grid/detail, Words, quiz/writing, gradient,
   tema terang/gelap, dan alur update.
4. Perbarui `DOKUMENTASI.md` sebelum rilis (sudah disesuaikan dengan IA baru,
   tetapi cek ulang setelah uji perangkat).
5. Backlog data: perbaiki `ちょうちょ`/`chouchou` (lihat catatan data).

File utama redesign:
- Tema: `lib/app/theme/app_colors.dart`, `app_theme.dart`, `app_spacing.dart`,
  `app_background.dart`
- Shell/navigasi: `lib/features/shell/main_shell.dart`
- Layar: `lib/features/learn/`, `practice/`, `words/`, `profile/`, `settings/`,
  `writing/`, `progress/` (legacy), `home/` (legacy)
- Widget bersama: `lib/core/widgets/`

Batasan desain:
- Pertahankan perilaku/fitur dan tes; v03 hanya untuk desain.
- UI aplikasi berbahasa Inggris. Arti kata di `words.tsv` tetap Bahasa Indonesia.
- Palet monokrom gelap/terang; tema System/Light/Dark; hindari blok menyilaukan.
- Noto Sans JP hanya untuk huruf Jepang; teks Latin memakai font sistem/Roboto.
- Target HP kecil (360×640): cek overflow, tap target ≥ 48 px, dan kontras.
- Jangan ubah `RELEASE.md`, `update_installer_io.dart`, kode Kotlin,
  `checkForUpdate`, `compareAppVersions`, atau `selectApkAsset`.
- `update_service.dart` dan `update_installer_io.dart` masih memuat pesan
  Indonesia karena batasan di atas; string milik `update_prompt.dart` sudah Inggris.
- Golden/visual harness sementara sudah dihapus dan tidak boleh di-commit.
  Playwright tidak bisa dipakai karena binary Chrome belum tersedia.

## Cara mulai di sesi baru

```bash
cd /home/qobilul/Code/kana_quest
git status
git branch --show-current   # harus develop-v03
flutter test
```

Lalu baca file ini + `DOKUMENTASI.md`.
