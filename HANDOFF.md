# Handoff — Kana Quest (sesi desain `develop-v03`)

Dokumen ini untuk melanjutkan pekerjaan di sesi OpenCode baru. Baca juga
`DOKUMENTASI.md` untuk detail fitur dan arsitektur.

## Status repo

- Remote: `github.com/qobilbaroq/hirakana`
- `main`: `fd729d0` — rilis 1.4.0 (tag `v1.4.0`)
- `develop-v02`: `3e20562` — perubahan fitur, sudah di-push
- `develop-v03`: `3e20562` — branch desain, dibuat dari v02, sudah di-push
- Versi `pubspec.yaml`: `1.4.0+7` (jangan naikkan kecuali menyiapkan rilis)
- Setelah handoff di-commit: branch aktif `develop-v03`, working tree bersih.

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
- Practice: menu dikelompokkan **Writing / Words / Recognition**; filter kosakata
  dipindah tepat di atas daftar Words.
- Progress: label sesi `build_romaji` / `build_kana` di Recent sessions.
- Tes: **132 lulus**; `flutter analyze` **7 info baseline** (bukan error).

## Yang belum diuji di HP

- Tampilan popup pembaruan.
- Migrasi DB v3 → v4 pada data lama.
- Dua menu Practice baru + Build the word.
- Tampilan Writing (romaji muncul hanya setelah Check).
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

## Fokus berikutnya: desain keseluruhan (`develop-v03`)

File utama:
- Tema: `lib/app/theme/app_colors.dart`, `app_theme.dart`, `app_spacing.dart`
- Shell/navigasi: `lib/features/shell/main_shell.dart`
- Layar: `lib/features/home/`, `learn/`, `practice/`, `progress/`, `settings/`,
  `writing/`, `words/`
- Widget bersama: `lib/core/widgets/`

Batasan desain:
- Pertahankan perilaku/fitur dan tes; v03 hanya untuk desain.
- UI aplikasi berbahasa Inggris (beberapa empty state lama masih Indonesia).
- Palet hangat; tema Terang/Gelap/AMOLED; hindari blok terang menyilaukan.
- Huruf Jepang memakai Noto Sans JP.
- Target HP kecil (360×640): cek overflow, tap target ≥ 48 px, dan kontras.

Langkah yang disarankan:
1. Minta arah desain/referensi ke user (boleh gambar atau URL).
2. Audit layar dan catat inkonsistensi.
3. Implementasi di `develop-v03`, lalu jalankan `flutter analyze` + `flutter test`.
4. Uji tampilan di 360×640; minta screenshot user bila perlu.
5. Commit desain hanya di v03; jangan merge ke v02/main tanpa izin.

## Cara mulai di sesi baru

```bash
cd /home/qobilul/Code/kana_quest
git status
git branch --show-current   # harus develop-v03
flutter test
```

Lalu baca file ini + `DOKUMENTASI.md`.
