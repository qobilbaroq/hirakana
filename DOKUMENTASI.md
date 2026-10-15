# Dokumentasi Kana Quest

Aplikasi belajar Hiragana & Katakana. Offline-first, multi-platform
(Android, Linux, Windows, macOS, iOS, Web).

Isi dokumen:

1. [Gambaran umum](#1-gambaran-umum)
2. [Sistem belajar (spaced repetition)](#2-sistem-belajar-spaced-repetition)
3. [Cara menyusun antrean sesi](#3-cara-menusun-antrean-sesi)
4. [Penilaian jawaban](#4-penilaian-jawaban)
5. [Fitur per layar](#5-fitur-per-layar)
6. [Aset](#6-aset)
7. [Database](#7-database)
8. [Batasan yang perlu diketahui](#8-batasan-yang-perlu-diketahui)

---

## 1. Gambaran umum

Total **208 huruf** = 104 Hiragana + 104 Katakana. Hurufnya dikelompokkan ke
**27 grup**, dipecah menjadi:

| Jenis | Jumlah | Isi |
| --- | --- | --- |
| Dasar | 46 | vokal (5), k,s,t,n,h,m,y,r,w (33), `ん` (1), `を` (1) |
| Dakuten + handakuten | 25 | `がぎぐげご`, `ざじずぜぞ`, `だぢづでど`, `ばびぶべぼ`, `ぱぴぷぺぽ` |
| Yōon / kombinasi | 33 | `きゃ`, `しゃ`, `ちゃ`, `にゃ`, `ひゃ`, `みゃ`, `りゃ`, `ぎゃ`, `じゃ`, `びゃ`, `ぴゃ` (11 grup × 3) |

Tiap huruf punya identitas unik `hiragana_a` / `katakana_a`, dan punya
**contoh kata** (kata, cara baca, arti bahasa Indonesia), misalnya
`か` → `かさ / kasa / payung`.

Struktur navigasi: 4 tab di `MainShell` — **Home, Learn, Practice, Progress**.
Tiga mode belajar (Flashcard, Quiz, Writing) dipanggil di luar tab, lalu
selesai ke layar **Summary**.

---

## 2. Sistem belajar (spaced repetition)

Inti app ada di `lib/data/repositories/kana_repository.dart`. Algoritmanya
spaced repetition sederhana bergaya Leitner, **dengan sengaja tanpa streak,
tanpa penalti, dan tanpa hukuman**. Sifatnya sengaja dibuat ringan supaya
tidak terasa menghukum, jadi begitu salah, huruf itu dijadwalkan ulang.
salah, huruf itu dijadwalkan ulang — bukan dihukum.

### Jeda pengulangan (spaced repetition)

Jeda ditentukan oleh jumlah jawaban benar **berturut-turut** untuk satu huruf:

| Benar berturut-turut | Jeda sampai tampil lagi |
| --- | --- |
| ke-1 | 10 menit |
| ke-2 | 1 hari |
| ke-3 | 3 hari |
| ke-4 | 7 hari |
| ke-5 dan seterusnya | 14 hari |

Kalau jawaban salah, huruf itu **dijadwalkan ulang**:

- salah **1×** berturut → tampil lagi dalam **1 menit**
- salah **2×** berturut → **langsung tampil di sesi berikutnya** (`next = now`)

### Tingkat penguasaan (mastery level)

`mastery_level` bernilai 0–3:

| Level | Arti | Syarat |
| --- | --- | --- |
| 0 | baru | belum pernah dibuka |
| 1 | sedang belajar | sudah pernah dijawab |
| 2 | mulai familiar | benar di ≥ 2 sesi berbeda |
| 3 | dikuasai | benar di ≥ 3 sesi **dan** benar 2× berturut dalam sesi terakhir |

Level 3 dipakai sebagai indikator "Known kana" di layar Progress, dan
menghitung persen mastery per script.

### Peran "terlalu cepat" (`fast`)

Kalau huruf dijawab benar dalam **kurang dari 1,5 detik**, jawaban itu
**tidak dihitung** sebagai bukti penguasaan lintas sesi (`sessionsCorrect`
tidak naik), walau `correctCount` tetap naik. Ini mencegah huruf yang asal
tebak cepat dianggap sudah dikuasai.

---

## 3. Cara menyusun antrean sesi

Fungsi `buildQueue()` menyusun antrean maks **10 kartu** (`sessionSize`):

**Langkah 1 — Jatuh tempo (due).** Huruf yang sudah pernah dipelajari dan
sudah melewati jadwalnya. Diurutkan dari yang **paling sering salah**
(`wrongCount` turun). Ini membuat huruf yang bermasalah selalu muncul duluan.

**Langkah 2 — Huruf baru.** Tambahkan huruf yang belum pernah dibuka, **maks
5 per sesi** (`newPerSession`). Dilewati kalau mode *quick*.

**Langkah 3 — Sisanya.** Kalau masih kurang dari 10, diisi huruf yang paling
lama tidak jatuh tempo (diurutkan `nextReviewAt` terkecil).

**Langkah 4 — Cadangan.** Kalau *quick review* dijalankan padahal belum ada
huruf yang pernah dipelajari, sesi diisi huruf baru.

> Catatan desain: tidak ada pesan "ketinggalan hari" / hutang. Kalau kamu
> absences 3 hari, tidak ada penalti — antrean tetap wajar.

---

## 4. Penilaian jawaban

### Di dalam sesi (`SessionController`)

- Salah → kartu di-**sisipkan ulang** 3 posisi ke depan (`min(index+3, length)`),
  maksimal **2× per huruf** supaya tidak berulang-ulang tanpa batas.
- Setiap jawaban langsung ditulis ke database per kartu, jadi kalau aplikasi
  ditutup di tengah, progres tetap aman.
- Waktu belajar dihitung **per jawaban** dan dibatasi 90 detik per langkah
  (120 detik di mode Writing), supaya HP yang ditinggal tidak menggelembungkan
  waktu belajar.

### Bentuk kuis

Empat jenis soal (`QuizKind`), dipilih **acak tiap kartu** kalau sesi dibuka
dari Learn/Home, atau **dipilih manual** dari tab Practice:

| Jenis | Tanya | Jawab |
| --- | --- | --- |
| `kanaToSound` | Lihat karakter → pilih bunyinya | 4 pilihan romaji |
| `soundToKana` | Dengar bunyi → pilih karakternya | 4 pilihan kana |
| `kanaToRomaji` | Lihat karakter → ketik romaji | input teks |
| `scriptDiff` | Bunyi sama, script mana? | 4 pilihan |

Detail yang membuat kuisnya adil:

- Opsi diambil dari huruf dengan **script yang sama**, jadi `kanaToSound`
  tidak pernah bocor jawaban lewat perbedaan script.
- Di `kanaToSound`, romaji **tidak** ditulis di bawah pilihan — kalau ditulis,
  kamu bisa menebak dari bentuk huruf tanpa benar-benar mengingat.
- Ada tabel **alternatif romaji** (`si/ti`, `tu`, `hu/fu`, `zi/ji`, `sya`,
  `tya`, `zya`, dll.) supaya jawaban dianggap benar walau ejaan lain.
- Audio **tidak boleh diputar sebelum menjawab** kalau membocorkan jawaban
  (ikon speaker nonaktif). Exception: `soundToKana` dan `scriptDiff`, karena
  bunyi justru bagian dari soalnya.
- Kalau salah, jawaban benar **diputar otomatis**.

---

## 5. Fitur per layar

### Home (`home_screen.dart`)

- Sapaan `おはよう!`, nama hari, dan hitungan **DAY nn** (hari ke-berapa sejak
  pertama dibuka, dihitung dari `first_open`).
- **Daily goal 10 menit** dengan progress bar dan pesan yang menyesuaikan:
  *"Let's start small."* → *"A small start counts."* → *"You're getting there."*
  → *"Goal reached. Keep going only if you feel like it."*
- Tombol **Continue learning** — melanjutkan mode & script terakhir.
- Dua kartu kategori: **Hiragana** / **Katakana** (tiap-tiap 104 huruf).
- **Quick review** — flashcard campuran yang hanya reviewing huruf yang paling
  rawan terlupakan, tanpa huruf baru.

### Learn (`learn_screen.dart`)

Pilih set (Hiragana / Katakana / Mixed Review), lalu **bottom sheet** memilih
cara belajar: **Flashcards** atau **Quick quiz**.

Saat pertama kali membuka sesi muncul dialog *"Welcome 👋"* yang menjelaskan
sesi dimulai dari 5 huruf saja.

### Flashcard (`flashcard_screen.dart`)

1. Sisi depan: karakter besar + *"What sound does this make?"* + *"Tap to reveal"*.
2. Ketuk kartu atau tombol **Reveal answer** → kartu **berflip 3D** (220 ms,
   dan dimatikan kalau perangkat menyetel "kurangi animasi"), audio **diput
   ar otomatis**.
3. Sisi belakang: karakter (kecil) + romaji besar + **contoh kata** dengan
   cara baca dan artinya.
4. Nilai dengan **Again** atau **Got it**.
5. Header menampilkan `HIRAGANA · 03 / 10` + progress bar, dan ikon speaker
   untuk memutar ulang suara.

Kalau huruf ini tidak punya contoh kata, sisi belakang hanya menampilkan romaji.

### Quick quiz (`quiz_screen.dart`)

4 pilihan dalam grid 2×2, atau field ketik romaji (auto-focus, autocorrect
dimatikan). Setelah menjawab: pilihan benar hijau, pilihan kamu merah,
sisanya diredupkan; kalau salah, jawaban benar + bunyinya ditampilkan, lalu
tombol **Next** muncul.

### Practice (`practice_screen.dart`)

Latihan terpisah per jenis, dengan **ChoiceChip** Hiragana / Katakana / Mixed
untuk latihan yang mana:

- **Trace the character** → mode Writing
- 4 baris recognition, satu per jenis kuis (bisa memilih jenis spesifik)

### Writing (`writing_screen.dart`)

1. Karakter ditampilkan kecil di atas kanvas.
2. Kanvas menampilkan **guide goresan** dari KanjiVG dengan **nomor urut** di
   tiap awal goresan.
3. **Replay stroke order** — animasi hijau menunjukkan urutan benar
   (durasi ≥ 900 ms, ~650 ms per goresan).
4. Tulis dengan jari/kursor. Tombol **Undo** menghapus goresan terakhir,
   **Clear** menghapus semuanya.
5. **Check** → tulisanmu ditampilkanOverlay di atas guide dengan warna berbeda
   supaya bisa dibandingkan mata. Tidak ada skor numerik.
6. Navigasi **Next / Finish** (mode Writing memakai `max(120)` detik per tick
   waktu).

### Summary (`session_summary_screen.dart`)

Menampilkan jumlah karakter, benar (disembunyikan di mode Writing), waktu,
dan kotak **"Needs another look"** berisi huruf yang tadi salah. Tombol
**Done** kembali ke Home.

### Progress (`progress_screen.dart`)

- **Known kana** (level 3) dari total 208.
- **Study time** — total menit minggu berjalan (dihitung dari Senin).
- **Kana mastery** — persen untuk Hiragana dan Katakana
  (`sum(masteryLevel) / (jumlah × 3)`).
- **Needs another look** — maksimal 8 huruf yang pernah dijawab salah dan belum
  dikuasai, diurutkan paling sering salah.
- **All characters** — grid semua huruf dengan indikator 4 tingkat
  (`MasteryIndicator`), bisa toggle `あ` / `ア`.
- **Recent sessions** — 5 sesi terakhir: mode, tanggal, dan durasi.

---

## 6. Aset

```
assets/
├── audio/          104 file .mp3   (440 KB total)
└── strokes/
    └── kana_strokes.json          (41 KB)
```

### `assets/audio/` — 104 file mp3

| Aspek | Keterangan |
| --- | --- |
| Jumlah | **104** |
| Penamaan | Berdasarkan **romaji**: `a.mp3`, `ka.mp3`, `kya.mp3`, `n.mp3`, `shi.mp3`, ... |
| Total ukuran | 440 KB |
| Ukuran per file | 1.8 KB – 4.6 KB |
| Dibuat dengan | Open JTalk |
| Lisensi | pidato sintetis Open JTalk — tidak ada batasan hak cipta |

**Penting:** nama file memakai romaji, jadi **satu file dipakai bersama** oleh
Hiragana dan Katakana (`か` dan `カ` memakai `ka.mp3` yang sama). Karena ada
104 romaji dan 104 huruf per script, keduanya dicek silang: tidak ada romaji
tanpa mp3 dan tidak ada mp3 tanpa pasangan romaji.

Audio diputar lewat `KanaAudioService` (pakai `audioplayers`, sumber `Asset
Source`), **bukan** TTS perangkat — jadi tetap jalan offline dan suaranya
konsisten di semua perangkat. Kalau gagal, fungsi mengembalikan `false` dan
latihan visual tetap jalan; flashcard menampilkan SnackBar 2 detik (sekali per
sesi).

### `assets/strokes/kana_strokes.json` — urutan goresan

| Aspek | Keterangan |
| --- | --- |
| Sumber | **KanjiVG** — https://kanjivg.tagaini.net |
| Lisensi | **CC BY-SA 3.0** (kredit wajib, sudah ditampilkan di tab Practice) |
| Jumlah karakter | **148** (46 Hiragana + 102 Katakana) |
| Total goresan | **433** |
| Format | Array path SVG, ruang koordinat **109 × 109** |

Contoh isi (kunci = karakter):

```json
{ "あ": ["M31.01,33c0.88,...", "M50.13,20.5c1.2,...", "..."] }
```

Cara pakai (`StrokeRepository` di `lib/data/seed/stroke_data.dart`):

1. `load()` membaca JSON sekali lalu mem-parse tiap path dengan
   `parseSvgPathData` (dari `path_drawing`), lalu di-cache per karakter.
2. **Huruf biasa** (1 karakter) memakai path-nya langsung.
3. **Huruf kombinasi** (2 karakter, seperti `きゃ`) **dibangun saat runtime**
   dari huruf dasar + `ゃ/ゅ/ょ` kecil, karena KanjiVG tidak menyediakan data
   untuk kombinasinya:

   ```dart
   result = [
     for (final d in base)  _transform(d, 0.66, -6,  18),  // huruf dasar, kiri atas
     for (final d in small) _transform(d, 0.60, 46, 38),  // ya/yu/yo kecil, kanan bawah
   ];
   ```

4. Kalau datanya tidak ada, canvas jatuh ke **font guide** — outline karakter
   digambar dengan `TextPainter` sebagai placeholder.

### Lisensi yang perlu diperhatikan

- `kana_strokes.json`: **CC BY-SA 3.0** — kalau kamu memakai ulang, kamu wajib
  memakai lisensi serupa dan mencantumkan kredit.
- `assets/audio/`: pidato sintetis Open JTalk, tanpa batasan.

---

## 7. Database

SQLite lokal, 3 tabel (`lib/core/storage/local_database.dart`):

**`kana_progress`** — satu baris per huruf:

| Kolom | Arti |
| --- | --- |
| `kana_id` | primary key, mis. `hiragana_ka` |
| `correct_count` / `wrong_count` | total jawaban benar / salah |
| `consecutive_correct` / `consecutive_wrong` | streak saat ini |
| `sessions_correct` | jumlah **sesi berbeda** dijawab benar |
| `last_correct_session_id` | agar satu sesi tidak dihitung dua kali |
| `last_reviewed_at` / `next_review_at` | waktu terakhir & jadwal berikutnya |
| `mastery_level` | 0–3 |

**`study_sessions`** — riwayat sesi:

| Kolom | Arti |
| --- | --- |
| `mode` | `flashcard` / `quiz` / `writing` |
| `kana_type` | `hiragana` / `katakana` / `mixed` |
| `started_at`, `duration_sec` | kapan & berapa lama |
| `cards`, `correct` | kartu diproses & jawaban benar |

**`meta`** — key/value bebas (`first_open`, `onboarded`, `last_mode`,
`last_type`).

Lokasi file per platform:

| Platform | Lokasi |
| --- | --- |
| Android / iOS / macOS | folder databases aplikasi |
| Linux / Windows | `~/.local/share/dev.qobilul.kana_quest/kana_quest.db` |
| Web | IndexedDB (`kana_quest_web.db`) |

Semuanya lewat satu pintu: `KanaRepository extends ChangeNotifier`, jadi
layar Home dan Progress otomatis ikut ter-refresh setiap kali ada perubahan
data.

---

## 8. Batasan yang perlu diketahui

Hal-hal ini penting diketahui supaya ekspektasinya tidak keliru:

1. **Latihan Writing tidak dinilai dan tidak memengaruhi mastery.**
   Tombol **Check** hanya mengubah tampilan jadi mode perbandingan visual —
   tidak ada perhitungan akurasi, skor, atau penalti. `recordAnswer()` tidak
   pernah dipanggil di mode Writing, jadi `kana_progress` untuk huruf yang
   ditulis **tidak berubah**. Sesi Writing tetap tercatat di `study_sessions`
   dengan `correct = 0`, dan layar Summary menyembunyikan angka "Correct" untuk
   mode ini. Tulisan yang kamu buat **tidak disimpan** setelah aplikasi ditutup.

2. **Tidak ada sinkronisasi antar perangkat.** Data purely lokal, tidak ada
   akun, tidak ada cloud. Menghapus data aplikasi = progress hilang.

3. **Tutorial awal cuma sekali.** Dialog "Welcome" muncul berdasarkan flag
   `onboarded` di tabel `meta`.

4. **Contoh kata hanya ada untuk sebagian huruf.** Tidak semua 104 romaji punya
   entry contoh kata, jadi di flashcard sisi belakang kadang tidak menampilkan
   contoh.

5. **Satu sesi = maks 10 huruf, maks 5 huruf baru.** Sesi pendek dipakai
   sengaja supaya beban belajar ringan.