# Handoff — Kana Quest (sesi desain `develop-v03`)

Dokumen ini untuk melanjutkan pekerjaan di sesi OpenCode baru. Baca juga
`DOKUMENTASI.md` untuk detail fitur dan arsitektur.

## Status repo

- Remote: `github.com/qobilbaroq/hirakana`
- `main`: `fd729d0` — rilis 1.4.0 (tag `v1.4.0`)
- `develop-v02`: `3e20562` — perubahan fitur, sudah di-push
- `develop-v03`: `a35fe63` — branch desain, dibuat dari v02, sudah di-push.
  Commit `a35fe63` berisi desain dasar; **update desain lanjutan (busur 0,034,
  palet terang baru, noise, toggle melengkung) belum di-commit** (working tree kotor).
- Versi `pubspec.yaml`: `1.4.0+7` (jangan naikkan kecuali menyiapkan rilis)
- Update lanjutan belum di-commit/di-push. Review diff dulu, lalu commit hanya
  dengan persetujuan user.

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
- Tes: **143 lulus**; `flutter analyze` **7 info baseline** (bukan error).

## Desain `develop-v03`

Status: desain dasar sudah di-commit di `a35fe63`; pembaruan lanjutan di bawah
masih ada di working tree.

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
  memakai abu-abu, bukan hitam. **Tidak ada aksen hijau**: sage terang
  `#6B6D72`, sage gelap `#AAAAAA`. Tombol utama tetap inverted (`ink` di atas
  `paper`); `ButtonKind.sage` memakai `active`.
- Mode terang baru: paper `#EBECEE`, ink `#1B1B1D`, sand `#E0E1E4`,
  white `#F7F7F9`, muted `#5E6066`, line `#D0D1D5`, active `#B6B7BB`.
  Mode gelap: paper `#121311`, ink `#E7E6E1`, sand `#272826`,
  white `#1B1C1A`, active `#C9C9C3`.
- Latar semua layar memakai `AppBackground` global: gradien, ditambah
  `NoiseOverlay` halus (CustomPainter, tanpa aset). **Noise kembali aktif**:
  `AppColors.noiseIntensity` 1,0 di gelap dan 1,1 di terang.
  - Gelap: delapan stop lama (`#868686` → `#111111`) dicampur 60% dengan paper;
    puncaknya sekitar `#585857`.
  - Terang: sepuluh stop dari `#979898` di atas, cepat memudar ke `#EBECEE`,
    lalu berakhir `#EFF0F2` di bawah.
  Scaffold/AppBar transparan.
- Navigasi bawah memakai `CurvedNavBar` berbentuk busur: tengah lebih tinggi,
  ujung turun **≈3,4% lebar bar** (`defaultSagFactor` 0,034; sebelumnya 0,052),
  pil aktif ≈70% tebal bar dan ikut miring mengikuti lengkungan. Isi bar adalah
  kaca tembus pandang (tanpa blur/BackdropFilter), dengan pil aktif yang
  memanjang ke tab tujuan lalu mengecil kembali (560 ms). Bar diberi margin
  20 px kiri/kanan dan 8 px bawah; tap target tiap slot ≥48 px. Ikon: `あ`
  (Kana), grid (Practice), buku (Words), person (Profile). Tab tetap ditemukan
  tes lewat `Tooltip`.
- Keempat tab memakai `SafeArea(bottom: false)` sehingga konten bergulir di
  belakang navigasi; kaca nav tetap tembus pandang di Kana, Practice, Words, dan
  Profile. Padding bawah daftar tetap `AppSpacing.navClearance` supaya item
  terakhir tidak tertutup nav.
- Kaca nav, toggle/tombol, dan kartu dibuat sedikit lebih gelap di kedua tema:
  `glass` 8,6% putih (gelap) / 11% hitam (terang), `glassPill` 37%/46%,
  `segPill` 24%/25%, `card` 4% putih (gelap) / 66% putih (terang), dan
  `cardRaised` 7% putih (gelap) / 82% putih (terang).
- Animasi dibuat halus dan singkat: transisi halaman fade + geser tipis lewat
  `AppPageTransitionsBuilder`; pindah tab memudarkan/menggeser isi `IndexedStack`
  240 ms tanpa kehilangan state; kartu menu (`ModeCard`) masuk dengan fade +
  geser 240 ms; pil navigasi memanjang/menyusul 560 ms dan warna ikon memudar
  260 ms.
- Mastery kana memakai 4 pip kaca (bukan tiga titik / badge `M`):
  - huruf aktif yang belum pernah benar: kaca sangat tipis;
  - langkah 1–3: isi kaca makin kuat;
  - langkah 4 (dikuasai): kembali ke latar, hanya border kaca tipis.
  Langkah diturunkan read-only dari `masteryLevel` + `sessionsCorrect`; tidak ada
  migrasi DB.
- **Hanya huruf kana** yang memakai liquid glass: sel aktif/terpelajari dan
  pilihan huruf di Choose letters memakai `activeGlassGradient` (intensitas 0,7
  di Choose letters). Kartu (`AppCard`/`ModeCard`), pencarian, filter, kartu
  jawaban, Flashcard, ringkasan sesi, Reading/Meaning, Dismiss pill, dan surface
  lain memakai lapisan `card`/`cardRaised` tembus pandang **tanpa border**;
  border hanya muncul untuk status pilihan/jawaban dan tombol sekunder.
  `GlassSurface` sudah dihapus.
- Kartu memakai radius **16** (sheet besar 24, tombol 14); tidak lagi sangat
  membulat. Ikon memakai `IconTile` solid-tinted, bukan kaca.
- Kontrol bawah Kana (tombol bulat quiz, **toggle Hiragana/Katakana melengkung**,
  tombol romaji) berada **8 px di atas navigasi** dengan
  `bottomInset + 8`. `Scaffold.extendBody` sudah memasukkan tinggi navigasi ke
  padding bawah body, jadi tinggi nav tidak boleh dihitung dua kali. Toggle
  memakai `CurvedNavBar` yang sama dengan item teks (`thickness` 42,
  `slotWidth` 104), jadi pilnya ikut memanjang saat berpindah script. Tombol
  bulat 44 px memakai `glass`/`segPill` tanpa border dan **turun mengikuti
  `edgeDrop`** (sag busur navigasi), sehingga quiz/romaji sejajar dengan ujung
  nav yang lebih rendah. Padding bawah grid = kontrol + 58 px. Tab lain memakai
  `AppSpacing.navClearance`.
- **Choose letters**: tile terpilih memakai kaca lembut (intensitas 0,7) dan
  memudar masuk 220 ms, lalu membesar dari 0,97 ke 1 dengan `easeOutBack`.
  Tidak ada ikon centang tambahan; pip penguasaan diredupkan supaya tidak lebih
  terang daripada huruf.
- Quiz memakai Dismiss pill, progress segmen, dan 2×2 kartu jawaban. Progress
  sesi memakai posisi 1-based supaya segmen pertama langsung terisi.
- Writing: romaji tetap tersembunyi sampai **Check**. Build the word tetap
  berupa grid pilihan maksimal dua baris.
- Baris kombinasi (きゃ/きゅ/きょ) disejajarkan ke ritme 5 kolom; ukuran huruf
  kombinasi diperkecil di grid dan detail sheet supaya tidak overflow.
- Tombol disabled memakai `sand` + `muted` agar label tetap terbaca.
- Semantics kustom memakai `excludeSemantics` agar teks tidak dibaca ganda.
- String UI baru berbahasa Inggris; arti kata tetap Bahasa Indonesia (data).
- Visual check 360×720 (mode gelap, tab Kana/Practice) sudah dilakukan lewat
  Flutter web + Playwright; golden/harness sementara tidak di-commit.
- `test/main_shell_test.dart` mengecek 4 tab + Profile scroll tanpa overflow,
  serta konten Practice/Words/Profile bergulir di belakang navigasi.
- `test/practice_screen_test.dart` mengecek menu Practice dan Words.
- `test/theme_palette_test.dart` mengecek palet baru, kontras, gradien terang
  (abu sedang → terang), surface tembus pandang, scaffold transparan, tidak ada
  hijau, dan tidak ada AMOLED.
- `test/curved_nav_geometry_test.dart` mengecek lengkungan simetris, tap target,
  sudut item, animasi pil memanjang, kelengkungan 0,034, dan toggle teks.
- `test/mastery_indicator_test.dart` mengecek 4 langkah, mapping level lama, dan
  tidak overflow di tile sempit.

## Pembaruan desain lanjutan (di atas `a35fe63`)

Patch `desain_lanjut.patch` dibuat dari `28a497b`, jadi tidak diterapkan mentah.
Hasil patch digabung dengan commit `a35fe63`; bagian berikut sengaja
**dipertahankan dari commit lama**, bukan dikembalikan ke versi patch:

- kartu jawaban kuis idle tetap `AppColors.card` (patch sempat memakai `white`);
- Dismiss pill tetap `card` (bukan `sand`);
- ringkasan sesi tetap `card`/`cardRaised`; tile kecil Profile tetap
  `cardRaised` (bukan `sand`/`paper`);
- detail sheet Kana tetap `cardRaised` tanpa border;
- kontrol bawah Kana memakai `bottomInset + 8` (jarak visual 8 px). Patch
  mentah memakai `bottomInset + 4`; nilainya tidak salah secara geometri karena
  `Scaffold.extendBody` sudah memasukkan tinggi navigasi, tetapi terasa terlalu
  mepet. Jangan menambahkan `CurvedNavGeometry.height` lagi.

Perubahan baru yang dipakai: sag 0,034, toggle Hiragana/Katakana melengkung,
palet terang baru, noise 1,1 di terang, `ButtonKind.sage` → `active`, animasi
Choose letters, `SafeArea(bottom: false)` di keempat tab, serta kaca/kartu yang
sedikit lebih gelap. `HANDOFF.md` dari patch tidak dipakai karena dibuat dari
dokumen lama; bagian ini ditulis manual.

## Yang belum diuji di HP

- Tampilan popup pembaruan.
- Migrasi DB v3 → v4 pada data lama.
- Dua menu Practice baru + Build the word.
- Tampilan Writing (romaji muncul hanya setelah Check).
- Navigasi melengkung 0,034 + noise + kartu translusen, Profile
  (streak/milestone), Kana grid/detail sheet, dan Words.
- Toggle Hiragana/Katakana melengkung dan tombol bulat quiz/romaji di 360×640.
- Transparansi nav di Practice/Words/Profile serta kaca/kartu yang lebih gelap.
- Mode terang baru (gradasi abu sedang, palet netral tanpa hijau) dan
  pergantian System/Light/Dark.
- Quiz 2×2 + progress 1-based, serta tombol disabled di layar kecil.
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
  `app_background.dart`, `lib/core/widgets/noise_overlay.dart`
- Navigasi: `lib/core/widgets/curved_nav_bar.dart`, `curved_nav_geometry.dart`,
  `lib/features/shell/main_shell.dart`
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
- Golden/visual harness sementara tidak boleh di-commit; Playwright dipakai
  hanya untuk cek visual lokal.

## Cara mulai di sesi baru

```bash
cd /home/qobilul/Code/kana_quest
git status
git branch --show-current   # harus develop-v03
flutter test
```

Lalu baca file ini + `DOKUMENTASI.md`.
