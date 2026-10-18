# Dokumentasi Kana Quest

Penjelasan cara kerja app. Untuk cara menjalankan dan membangun, lihat [README.md](README.md);
untuk rilis Android, lihat [RELEASE.md](RELEASE.md).

Isi:

1. [Gambaran umum](#1-gambaran-umum)
2. [Memilih huruf yang dipelajari](#2-memilih-huruf-yang-dipelajari)
3. [Sistem belajar (spaced repetition)](#3-sistem-belajar-spaced-repetition)
4. [Menyusun antrean sesi](#4-menyusun-antrean-sesi)
5. [Penilaian jawaban dan kuis](#5-penilaian-jawaban-dan-kuis)
6. [Latihan baca](#6-latihan-baca)
7. [Fitur per layar](#7-fitur-per-layar)
8. [Pengaturan dan tema](#8-pengaturan-dan-tema)
9. [Aset](#9-aset)
10. [Database](#10-database)
11. [Pengujian](#11-pengujian)
12. [Batasan yang perlu diketahui](#12-batasan-yang-perlu-diketahui)

---

## 1. Gambaran umum

Total **208 huruf** = 104 Hiragana + 104 Katakana, dalam **27 grup**:

| Jenis | Jumlah | Isi |
| --- | --- | --- |
| Dasar | 46 | vokal (5), k, s, t, n, h, m, y, r, w, `ん`, `を` |
| Dakuten + handakuten | 25 | `がぎぐげご`, `ざじずぜぞ`, `だぢづでど`, `ばびぶべぼ`, `ぱぴぷぺぽ` |
| Yōon / kombinasi | 33 | `きゃ`, `しゃ`, `ちゃ`, `にゃ`, `ひゃ`, `みゃ`, `りゃ`, `ぎゃ`, `じゃ`, `びゃ`, `ぴゃ` (11 grup x 3) |

Setiap huruf punya id unik (`hiragana_a`, `katakana_a`). Hiragana dan katakana dengan romaji yang
sama memakai satu file suara yang sama.

Navigasi: 4 tab di `MainShell` (**Home, Learn, Practice, Progress**). Flashcard, Quiz, Writing, dan
Reading dibuka di luar tab, lalu selesai ke layar **Summary**. **Settings** dibuka dari ikon gerigi di Home.

Alur data: semua akses database lewat `KanaRepository` (`ChangeNotifier`), jadi Home dan Progress
otomatis ter-refresh saat data berubah. Pengaturan ada di `AppSettings` (juga `ChangeNotifier`).

---

## 2. Memilih huruf yang dipelajari

**Huruf baru tidak pernah masuk otomatis.** Kamu menentukan sendiri set huruf aktif lewat layar
**Choose letters** (Learn atau Home, pilih Hiragana/Katakana lalu *Choose letters*):

- ketuk huruf untuk memilih, ketuk judul baris untuk memilih satu baris;
- tombol **Add next 5** (menambah 5 huruf berikutnya sesuai urutan dataset), **Select all**, **Clear**;
- titik kecil di tiap huruf = tingkat penguasaan.

Set aktif disimpan di tabel `meta` (kunci `active_ids`, id dipisah koma). Awalnya hanya 5 huruf pertama
(`あいうえお` / `アイウエオ`). Kalau kamu mengosongkan semua huruf di satu script, baris pertamanya
dipakai lagi. Pengguna versi lama otomatis dimigrasi: huruf yang sudah pernah dipelajari menjadi aktif.

Flashcard, kuis, latihan menulis, dan latihan baca hanya memakai huruf aktif. Layar ringkasan sesi
punya tautan *Ready for more? Add the next 5 letters* (baru menambah kalau ditekan).

---

## 3. Sistem belajar (spaced repetition)

Inti app ada di `lib/data/repositories/kana_repository.dart`. Algoritmanya sederhana, bergaya Leitner,
**tanpa streak dan tanpa hukuman**: kalau salah, huruf itu dijadwalkan ulang, bukan dihukum.

### Jeda pengulangan

Ditentukan oleh jumlah jawaban benar **berturut-turut** untuk satu huruf:

| Benar berturut-turut | Jeda sampai tampil lagi |
| --- | --- |
| ke-1 | 10 menit |
| ke-2 | 1 hari |
| ke-3 | 3 hari |
| ke-4 | 7 hari |
| ke-5 dan seterusnya | 14 hari |

Kalau salah: **1x** berturut tampil lagi dalam 1 menit; **2x** berturut langsung tampil di sesi berikutnya.

### Tingkat penguasaan (`mastery_level`, 0-3)

| Level | Arti | Syarat |
| --- | --- | --- |
| 0 | baru | belum pernah dibuka |
| 1 | sedang belajar | sudah pernah dijawab |
| 2 | mulai familiar | benar di >= 2 sesi berbeda |
| 3 | dikuasai | benar di >= 3 sesi berbeda **dan** benar 2x berturut-turut |

Level 3 dipakai sebagai "Known kana" di Progress. Persen penguasaan per script =
`jumlah level / (jumlah huruf x 3)`.

### "Terlalu cepat"

Jawaban benar dalam **kurang dari 1,5 detik** tidak dihitung sebagai bukti penguasaan lintas sesi
(`sessions_correct` tidak naik), supaya tebakan cepat tidak dianggap hafal.

### "Second look" setelah Again

Kartu yang dijawab salah disisipkan lagi **3 posisi ke depan** (maksimal 2 kali per slot soal) dan
diberi tanda *SECOND LOOK*. Menjawab benar di *second look* hanya menutup kartu itu di sesi ini dan
menjadwalkan ulang 10 menit; itu **belum** dihitung sebagai bukti penguasaan.

---

## 4. Menyusun antrean sesi

`KanaRepository.buildQueue()` menyusun antrean dari **huruf aktif saja**:

1. **Jatuh tempo**: huruf yang pernah dipelajari dan sudah lewat jadwalnya, yang paling sering salah di depan.
2. **Belum pernah dilihat**: huruf aktif yang masih baru.
3. **Sisanya**: huruf yang paling lama tidak dibuka.

Lalu diambil sebanyak **ukuran sesi** (`size`). Ukuran ini diatur di **Settings -> Session length**
(minimal 10, kelipatan 5, sampai 60; default 10).

- **Diacak.** Prioritas di atas menentukan *huruf apa* yang masuk saat huruf aktif melebihi ukuran
  sesi; setelah itu urutannya diacak penuh dan huruf yang sama tidak muncul berurutan.
  Pengecualian: kalau semua huruf terpilih belum pernah dilihat dan modenya flashcard, urutan dataset
  dipertahankan (あ い う え お) supaya pengenalan pertama tetap berurutan.
- **Mengisi sampai penuh.** Kalau ukuran sesi di atas 10 dan huruf aktif lebih sedikit dari ukuran itu,
  huruf diulang dalam putaran acak sampai jumlahnya tercapai (`fillToSize`). Pada ukuran 10 perilakunya
  seperti biasa: sesi bisa lebih pendek kalau huruf aktif lebih sedikit.
- **Quiz** hanya memakai huruf yang sudah pernah dilihat di flashcard.
- **Quick review** hanya memakai huruf yang sudah pernah dipelajari.
- Tidak ada pesan "ketinggalan hari" atau hutang belajar.

Progres sesi (`03 / 10`) dihitung per **slot soal**, jadi tetap benar walau huruf berulang. Ulangan
dari Again ditampilkan sebagai `+N again`.

---

## 5. Penilaian jawaban dan kuis

- Setiap jawaban langsung ditulis ke database per kartu, jadi kalau app ditutup di tengah, progres aman.
- Waktu belajar dihitung per jawaban dan dibatasi 90 detik per langkah (120 detik di Writing).

Jenis soal (`QuizKind`), dipilih acak per soal dari Learn/Home (tidak lebih dari 2x berturut-turut jenis
yang sama), atau dipilih manual dari tab Practice:

| Jenis | Tanya | Jawab |
| --- | --- | --- |
| `kanaToSound` | lihat huruf, pilih bunyinya | 4 pilihan romaji |
| `soundToKana` | bunyi ("ku"), pilih hurufnya | 4 pilihan kana (tanpa romaji) |
| `kanaToRomaji` | lihat huruf, ketik romaji | input teks (ejaan alternatif diterima: `si`, `tu`, `sya`, ...) |
| `scriptDiff` | bunyi sama, script mana? | 4 pilihan: 2 bunyi x 2 script, tepat satu cocok bunyi **dan** script |
| `lookalike` | huruf yang sering tertukar | 4 pilihan kana; sesi sendiri, tidak ikut acakan |

Aturan keadilan: pilihan diambil dari huruf berscript sama, romaji tiap pilihan unik, jawaban benar
selalu ada di pilihan (dijaga `assert` dan test). Audio tidak diputar sebelum menjawab kalau
membocorkan jawaban. Kalau salah, jawaban benar ditampilkan dan diputar (kalau suara otomatis aktif).

### Huruf yang sering tertukar

Setiap jawaban salah di soal pilihan (atau ketik romaji, atau satu huruf di latihan baca) dicatat
sebagai pasangan (tanpa arah: ぬ-め = め-ぬ) di tabel `confusions`. Pasangan yang tertukar **minimal 2 kali**
tampil di Progress ("Often mixed up") dan menjadi bahan **Look-alike drill**. Pasangan ini juga
dipakai sebagai pengecoh di kuis biasa.

---

## 6. Latihan baca

Tab **Practice -> Reading practice**. Selalu menanyakan **cara baca (romaji)**, bukan arti.
Satu sesi (sebanyak ukuran sesi) berisi campuran:

| Jenis | Porsi | Contoh |
| --- | --- | --- |
| Kata sungguhan | ~60% | `さかな` -> sakana |
| Rangkaian 2-3 huruf acak | ~25% | `くあせ` -> kuase |
| Satu huruf | ~15% | `け` -> ke |

Kalau kata yang cocok sedikit, sisanya diisi rangkaian huruf, jadi sesi selalu penuh.

**Pilihan jawaban** dibuat dengan mengganti **satu huruf** pada soal dengan huruf lain dari script yang
sama (huruf yang sering tertukar diutamakan), sehingga pilihannya mirip dan tidak bisa ditebak dari
panjangnya. Selalu 4 pilihan unik yang memuat jawaban.

**Daftar kata** ada di `assets/data/words.tsv` (729 kata kurasi, dimuat sekali oleh `WordBank`).
Semua kata punya arti Bahasa Indonesia dan rekaman utuh. Sebuah kata hanya muncul kalau
**semua hurufnya ada di huruf aktif**. Jumlahnya dibuat merata per tahap huruf: dengan vowels + k + s
saja masih ada 49 kata, dan 457 kalau semua hiragana aktif.

**Tidak itu-itu saja.** Kata yang sudah muncul dicatat di tabel `word_history`. Saat memilih kata, yang
belum pernah muncul diutamakan (acak), lalu yang paling lama tidak muncul.

**Suara**: satu huruf memakai rekaman huruf; kata dengan rekaman utuh memakai rekaman kata
(`assets/audio/words/<romaji>.mp3`); rangkaian huruf dan kata tanpa rekaman dibunyikan huruf demi huruf.
Suara diputar setelah menjawab (supaya tidak membocorkan jawaban) dan mengikuti pola normal/lambat
di Settings.

**Arti** tidak ditanyakan. Setelah jawaban **benar**, arti bisa ditampilkan kalau *Show word meaning*
aktif di Settings (default mati) — dan karena semua kata kurasi punya arti, tidak ada soal yang
bisa dijawab tanpa penjelasan.

---

## 7. Fitur per layar

- **Home**: sapaan, hari ke-n, ikon Settings, kartu target harian + *Continue learning* (melanjutkan
  mode dan script terakhir), kartu Hiragana/Katakana, *Quick review*.
- **Learn**: Hiragana / Katakana / Mixed Review, lalu pilih *Flashcards*, *Quick quiz*, atau *Choose letters*.
- **Flashcard**: ketuk kartu atau *Reveal answer* (kartu flip 220 ms, dimatikan kalau perangkat
  menyetel kurangi animasi). Sisi belakang: huruf, romaji, dan contoh kata. Setelah terbuka, ketuk kartu
  atau ikon speaker untuk memutar suara lagi (normal, normal, lambat). *Again* / *Got it* baru aktif
  setelah reveal.
- **Quiz**: grid 2x2 atau kolom ketik romaji; pilihan benar hijau, pilihanmu salah berwarna clay.
- **Practice**: pilih Hiragana / Katakana / Mixed, lalu *Trace the character*, *Reading practice*, atau
  salah satu jenis kuis, termasuk *Look-alike drill*.
- **Writing**: guide goresan bernomor dari KanjiVG, *Replay stroke order*, Undo/Clear, *Check*
  menampilkan guide di atas tulisanmu untuk dibandingkan (tanpa skor).
- **Summary**: jumlah karakter, benar, waktu, kotak *Needs another look*; tombol *Study again* dan *Done*.
- **Progress**: *Known kana*, waktu belajar minggu ini, penguasaan per script, *Needs another look*,
  *Often mixed up*, **All characters** (tabel gojuon selebar layar, kolom sejajar), dan 5 sesi terakhir.
- **Settings**: lihat bagian berikut.

---

## 8. Pengaturan dan tema

Disimpan di tabel `meta`, dimuat saat app mulai (`AppSettings`):

| Pengaturan | Pilihan | Kunci `meta` |
| --- | --- | --- |
| Tema | System / Light / Dark | `theme_mode` |
| AMOLED black | hidup/mati (hanya berlaku di mode gelap) | `theme_amoled` |
| Session length | 10 sampai 60, kelipatan 5 | `session_size` |
| Show word meaning | hidup/mati | `show_meaning` |
| Daily goal | 5 / 10 / 15 / 20 / 30 menit | `goal_minutes` |
| Play sound automatically | hidup/mati | `audio_autoplay` |
| Replay pattern | normal-normal-lambat, normal-lambat, selalu normal, selalu lambat | `audio_pattern` |

### Palet warna

Tiga palet di `lib/app/theme/app_colors.dart` (`AppPalette.light`, `.dark`, `.amoled`). Semuanya satu
keluarga hangat (sage dan krem); `AppColors.*` adalah **getter** yang mengikuti tema aktif, jadi tidak
boleh dipakai di ekspresi `const`.

- **Gelap**: latar `#181A17`, teks krem lembut (bukan putih), aksen sage diredam, dan **tombol utama
  berwarna sage gelap** (`action` / `onAction`), bukan krem terang, supaya tidak ada blok yang menyilaukan.
- **AMOLED**: latar hitam sejati `#000000`; permukaan lain sedikit kehijauan (bukan abu netral) supaya
  selaras dengan hitamnya.
- `ColorScheme` dibuat eksplisit dari palet (`buildAppTheme`), jadi chip, switch, slider, dialog,
  snackbar, dan bottom sheet ikut palet.
- Saat tema berganti, `app.dart` menyuruh semua widget dibangun ulang sekali supaya warna layar yang
  sedang terbuka ikut berubah.

---

## 9. Aset

```
assets/
  audio/            104 huruf, versi normal
    slow/           104 huruf, versi lambat
    words/          rekaman kata: 1.688 cara baca x (normal + lambat)
  data/words.tsv    729 kata kurasi
  strokes/          kana_strokes.json (urutan goresan)
  icon/             ikon app dan splash
```

Ukuran kira-kira: audio 16 MB (kata 6 MB), data 0,1 MB, goresan 48 KB. Pakai
`flutter build apk --split-per-abi` supaya APK per arsitektur lebih kecil.

**Suara huruf**: berkas `<romaji>.mp3` (`ka.mp3`, `kya.mp3`, ...); rekaman penutur asli dari
`veardk/just-gojuon`, volume diseragamkan, versi lambat dibuat dengan `atempo=0.65`.

**Suara kata**: `<cara-baca>.mp3` dan `<cara-baca>_slow.mp3`, sintesis offline Open JTalk dengan suara
tohoku-f01. Kolom ketiga `words.tsv` (0/1) menandai kata yang punya rekaman utuh — untuk pool ini
seluruhnya `1`.

**Format `words.tsv`**: satu kata per baris, kolom dipisah TAB: `kata`, `cara baca`, `ada audio (0/1)`,
`arti Bahasa Indonesia`. Urutan baris mengikuti urutan gojuon (huruf awal sama dikelompokkan), bukan
alfabetis, supaya kata yang lebih mudah dibaca muncul lebih dulu.

### Lisensi

| Berkas | Lisensi |
| --- | --- |
| `strokes/kana_strokes.json` (KanjiVG) | CC BY-SA 3.0 |
| `audio/*.mp3` huruf (just-gojuon) | MIT untuk repo; asal rekaman tidak dijelaskan, cek sebelum rilis publik |
| `audio/words/` (tohoku-f01) | CC BY 4.0 (atribusi) |
| `data/words.tsv` | **karya sendiri** — 729 kata kurasi ditulis tangan untuk app ini, tanpa sumber eksternal |

`data/words.tsv` tidak pernah memakai kamus pihak ketiga, jadi tidak ada kewajiban lisensi data
yang perlu dipenuhi. Hanya audio dan goresan yang punya kewajiban.

---

## 10. Database

SQLite lokal, **versi 3** (`lib/core/storage/local_database.dart`, migrasi lewat `onUpgrade`).

**`kana_progress`**: satu baris per huruf.

| Kolom | Arti |
| --- | --- |
| `kana_id` | primary key, mis. `hiragana_ka` |
| `correct_count` / `wrong_count` | total benar / salah |
| `consecutive_correct` / `consecutive_wrong` | streak saat ini |
| `sessions_correct` | jumlah **sesi berbeda** dijawab benar |
| `last_correct_session_id` | supaya satu sesi tidak dihitung dua kali |
| `last_reviewed_at` / `next_review_at` | waktu terakhir dan jadwal berikutnya |
| `mastery_level` | 0-3 |

**`study_sessions`**: riwayat sesi (`mode` = `flashcard` / `quiz` / `writing` / `words`, `kana_type`,
`started_at`, `duration_sec`, `cards`, `correct`).

**`confusions`** (v2): pasangan huruf yang sering tertukar (`a_id` < `b_id`, `count`, `last_at`).

**`word_history`** (v3): kata yang sudah muncul di latihan baca (`text`, `seen_count`, `last_at`).

**`meta`**: key/value bebas: `first_open`, `onboarded`, `last_mode`, `last_type`, `active_ids`, dan
kunci pengaturan di bagian 8.

Lokasi file per platform: lihat [README.md](README.md#catatan-platform).

---

## 11. Pengujian

```bash
flutter analyze
flutter test
```

Test memakai database SQLite in-memory (`test/helpers/test_db.dart`). Yang dicakup antara lain:

- `quiz_question_test.dart`: pilihan selalu 4, unik, dan memuat jawaban untuk semua jenis soal.
- `quiz_screen_layout_test.dart`: keempat pilihan terlihat di layar kecil.
- `queue_shuffle_test.dart`: antrean diacak, himpunan benar, aturan flashcard pertama.
- `session_size_test.dart`: batas ukuran sesi, `fillToSize`, progres dengan huruf berulang.
- `word_questions_test.dart`: data kata (semua bisa dibaca, file audio ada, cukup kata per tahap huruf),
  romaji, pilihan jawaban, sesi baca penuh, dan kata tidak berulang antar sesi.
- `amoled_test.dart`: palet (kontras teks, tombol utama tidak menyilaukan, AMOLED hitam sejati dan hangat)
  dan tema Material.

---

## 12. Batasan yang perlu diketahui

1. **Latihan Writing tidak dinilai dan tidak memengaruhi penguasaan.** *Check* hanya menampilkan
   perbandingan visual. Sesi Writing tercatat dengan `correct = 0`. Tulisanmu tidak disimpan.
2. **Latihan baca tidak mengubah penguasaan huruf.** Sesinya tercatat, tetapi `kana_progress` tidak berubah.
   Satu-satunya efek ke huruf adalah pencatatan huruf yang tertukar (soal satu huruf).
3. **Tidak ada sinkronisasi antar perangkat.** Data lokal murni, tanpa akun atau cloud. Menghapus data
   app berarti progres hilang.
4. **Suara kata adalah sintesis**, bukan penutur asli — rekaman HTS tohoku-f01, bukan rekaman manusia.
   Karena poolnya 729 kata kurasi, **seluruhnya** punya rekaman utuh (versi normal dan lambat),
   tidak ada kata yang harus dibunyikan huruf demi huruf.
5. **Kana kecil** (ぁ ぃ ぅ ぇ ぉ dan padanan katakananya) belum ada di data huruf, jadi kata yang memakainya
   (mis. ファ, ティ) tidak dimasukkan.
6. **Contoh kata di flashcard** hanya ada untuk sebagian huruf.
7. **Tutorial awal** hanya muncul sekali (flag `onboarded`).
