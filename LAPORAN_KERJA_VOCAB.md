# Laporan Kerja — Update Kosakata Kana Quest

## 1. Ringkasan

Berhasil. Paket `kana-quest-vocab-v2` diterapkan ke branch `develop-v02`: 860 kata kurasi
berkelompok (N5–N4 495 kata, N3 365 kata) dengan arti Bahasa Indonesia, tingkat, kategori, dan
1.028 file audio baru dari tohoku-f01. Semua 90 test lulus, `flutter analyze` 0 error/0 warning, dan
`flutter build apk --debug` berhasil.

Satu keputusan diambil setelah bertanya ke Anda: paket semula mengembalikan 8.391 kata dari kamus
yang 86% tidak punya arti — masalah yang justru Anda minta saya perbaiki sebelumnya. Sesuai pilihan
Anda, baris tanpa arti dibuang sehingga pool berisi **1.272 kata yang semuanya punya arti**, dan
dua test yang menjaga jaminan itu tetap lulus tanpa dilonggarkan.

## 2. Kondisi awal

- Branch: `develop-v02`
- Commit awal: `e80df4e` — "Kembalikan kosakata ke daftar kurasi 729 kata"
- git status awal: bersih (0 berkas berubah)

> Catatan: paket disusun dari `ee203cb` (1.3.0 asli), sedangkan repo sudah maju satu commit. Semua
> 729 kata dari commit `e80df4e` ternyata **ada semua** di dalam pool paket, jadi tidak ada data
> yang hilang saat patch diterapkan.

## 3. Langkah yang dijalankan

| No | Perintah | Hasil | Catatan |
| --- | --- | --- | --- |
| 1 | `git rev-parse --abbrev-ref HEAD`, `git status`, `git log --oneline -3` | OK | `develop-v02`, bersih, `e80df4e` |
| 2 | `bash <PAKET>/apply_patch.sh .` | OK | 1.043 file disalin (1.028 mp3 + 15 teks) |
| 3 | `python3 tools/verify_vocab.py` | OK | `masalah : 0` (dicoba pertama kali pada pool 9.663 baris) |
| 4 | `flutter pub get` | OK | 39 paket punya versi lebih baru di luar constraint |
| 5 | `flutter analyze` | OK | 0 error, 0 warning, 7 info (semuanya info lama) |
| 6 | `flutter test` | OK | 90 lulus, 0 gagal |
| 7 | `flutter build apk --debug` | OK | berhasil, 165 MB (debug, belum di-strip) |
| 8 | `git add -A && git commit` | OK | `65a654a` |
| 9 | Tulis laporan + commit | OK | commit ini |

**Langkah tambahan di luar urutan paket** (dipersetujui lewat pertanyaan):

| Perintah | Hasil | Catatan |
| --- | --- | --- |
| Pangkas `words.tsv` ke baris yang punya arti | OK | 9.663 → 1.272 baris; 8.391 dibuang |
| `python3 tools/verify_vocab.py` (ulang) | OK | `masalah : 0` pada pool final |
| Koreksi kredit lisensi di `settings_screen.dart` | OK | sebelumnya mengklaim JMdict |
| Sinkronkan `DOKUMENTASI.md`, `README.md`, `word_data.dart` | OK | angka & sumber data |

## 4. File yang berubah

- Jumlah file teks diubah/baru: **15**
- Jumlah file audio baru (`assets/audio/words`): **1.028**
- Total: **1.045 berkas berubah, +2.876 / −706 baris** (selebihnya biner mp3)

### Daftar file teks

```
assets/data/words.tsv                        (diubah)
lib/data/repositories/word_repository.dart   (diubah)
lib/data/seed/word_data.dart                 (diubah)
lib/features/learn/session_controller.dart   (diubah)
lib/features/practice/practice_screen.dart   (diubah)
lib/features/words/word_practice_screen.dart (diubah)
lib/features/words/word_questions.dart       (diubah)
DOKUMENTASI.md                               (diubah)
README.md                                    (diubah)
lib/features/settings/settings_screen.dart   (diubah oleh saya, bukan paket)
test/vocab_groups_test.dart                  (baru, 125 baris)
tools/build_vocab.py                         (baru, 147 baris)
tools/generate_audio.py                      (baru, 159 baris)
tools/verify_vocab.py                        (baru, 84 baris)
tools/vocab_lib.py                           (baru, 104 baris)
tools/vocab_source.txt                       (baru, 885 baris)
tools/out/verify_report.json                 (baru, hasil verifikasi)
```

### Ringkasan `git diff --stat`

```
 assets/audio/words/*.mp3    | 1028 file baru
 assets/data/words.tsv       | 1875 +++++-----
 lib/data/repositories/word_repository.dart   |    9 +-
 lib/data/seed/word_data.dart                 |   33 +-
 lib/features/learn/session_controller.dart   |    8 +-
 lib/features/practice/practice_screen.dart   |   28 +-
 lib/features/settings/settings_screen.dart   |    2 +-
 lib/features/words/word_practice_screen.dart |   11 +
 lib/features/words/word_questions.dart       |   15 +-
 test/vocab_groups_test.dart                  |  125 +++
 tools/                                      |  600 +++++
 1045 files changed, 2876 insertions(+), 706 deletions(-)
```

## 5. Hasil verifikasi

### `tools/verify_vocab.py`

```
baris words.tsv       : 1272
kata kurasi berkelompok: 860
  N5–N4 : 495
  N3    : 365
    N5–N4  Sehari-hari  : 122      N3  Pekerjaan   :  79
    N5–N4  Waktu       :  85      N3  Pendidikan  :  74
    N5–N4  Aktivitas   :  91      N3  Komunikasi  :  75
    N5–N4  Makanan    :  77      N3  Kesehatan   :  69
    N5–N4  Angka       :  68      N3  Perjalanan  :  68
    N5–N4  Keluarga    :  52
file audio kata       : 4404 (16.0 MB)
masalah               : 0
```

Verifikasi silang tambahan (di luar skrip paket):

| Yang diperiksa | Hasil |
| --- | --- |
| Baris `words.tsv` | 1.272 |
| Baris tanpa arti Indonesia | **0** |
| Baris dengan kolom audio bukan `1` | **0** |
| mp3 dibutuhkan (1.267 kata × 2) | 2.534 |
| mp3 dibutuhkan yang hilang | **0** |
| mp3 di repo tapi tidak terpakai | 1.870 (5,8 MB) |
| Kata duplikat / cara baca duplikat | 0 / 0 |

Sebaran pool terhadap huruf aktif: vowels 10 kata, +k 36, +s 69, +t 133, +n 169, seluruh hiragana
965, seluruh katakana 307, gabungan 1.272. **Jumlah kata naik monoton di setiap tahap huruf**
(tidak ada tahap stagnan atau turun).

### `flutter analyze`

```
7 issues found (ran in 2.5s)
```

- **error: 0**
- **warning: 0**
- **info: 7** — semuanya sudah ada sebelum paket ini dan tidak terkait:
  5× `unintended_html_in_doc_comment` (`kana_audio_service.dart`, `word_data.dart`),
  2× `deprecated_member_use` (`stroke_data.dart`)

Kode Dart di paket **tidak pernah dikompilasi di lingkungan pembuatnya** (sesuai catatan
`README_UPDATE.md` §3D). ternyata sudah benar — tidak ada satu pun error kompilasi.

### `flutter test`

```
00:18 +90: All tests passed!
```

- Lulus: **90**
- Gagal: **0**
- Dilewati: **0**

Yang diminta task, semuanya lulus:

| Berkas test | Hasil |
| --- | --- |
| `test/vocab_groups_test.dart` (baru dari paket) | **11/11 lulus** |
| `test/word_questions_test.dart` | **lulus** (sebelumnya 2 gagal,see §6) |
| `test/session_size_test.dart` | **lulus** |

Test total naik dari 79 → 90 (+11 dari `vocab_groups_test.dart`). **Tidak ada test lama yang
dihapus, di-skip, atau dilonggarkan.**

### `flutter build apk --debug`

Berhasil.

```
✓ Built build/app/outputs/flutter-apk/app-debug.apk
```

Ukuran **165 MB** — ini build debug tanpa `--split-per-abi`, jadi isinya mencakup debug symbols
untuk semua arsitektur. Angka ini tidak mewakili ukuran rilis; untuk perkiraan rilis pakai
`flutter build apk --split-per-abi`.

## 6. Masalah dan perbaikan

| File:baris | Masalah | Perbaikan | Status |
| --- | --- | --- | --- |
| `assets/data/words.tsv` | Paket mengembalikan 9.663 baris, hanya **13%** punya arti Indonesia. 8.391 baris dari kamus tidak punya arti — persis masalah yang Anda minta saya perbaiki di commit sebelumnya. | Baris tanpa arti dibuang → **1.272 baris, 100% punya arti**. Dipersetujui lewat pertanyaan, bukan diputuskan sepihak. | Selesai |
| `lib/features/settings/settings_screen.dart:150` | Kredit di dalam app berbunyi `'Word list: JMdict, EDRDG (CC BY-SA 4.0), edrdg.org'`. Ini **keliru**: pool sekarang karya sendiri, jadi app mengklaim sumber yang tidak dipakai (kewajiban-atribusi palsu), sekaligus tidak menyatakan bahwa daftar kata adalah karya sendiri. | Diganti `'Word list: written for this app, no external source'`. | Selesai |
| `DOKUMENTASI.md` | Angka dan sumber data usang: "sekitar 9 ribu kata", "kata kurasi + kata umum dari JMdict", tabel lisensi masih mencantumkan `data/words.tsv` bagian JMdict = CC BY-SA 4.0, dan ukuran aset salah. | Disinkronkan ke 1.272 kata karya sendiri; tabel lisensi, angka pool, dan tabel aset diperbarui. | Selesai |
| `README.md` | "sekitar 9 ribu kata"; tabel lisensi mencantumkan JMdict. | Disinkronkan; ditambah catatan bahwa daftar kata karya sendiri. | Selesai |
| `lib/data/seed/word_data.dart:48-53` | Doc comment masih menyebut "sekitar 9 ribu kata" dan "kamus JMdict (EDRDG, CC BY-SA 4.0)". | Diperbarui ke 1.272 kata karya sendiri. | Selesai |
| `test/word_questions_test.dart:43` | Test `setiap kata punya arti Bahasa Indonesia yang singkat` (dibuat di `e80df4e` sesuai permintaan Anda) gagal: 8.391 kata tanpa arti. | Tidak diubah. Berhasil setelah pool dipangkas. | Selesai |
| `test/word_questions_test.dart:53` | Test `kata ber-audio punya file normal dan lambat`, assertion `withAudio.length == real.length`, gagal: 2.265 dari 9.663. | Tidak diubah. Berhasil setelah pool dipangkas. | Selesai |

Tidak ada bug kompilasi di kode Dart paket — semua 90 test langsung lulus begitu dipangkas.

## 7. Belum selesai / butuh keputusan Anda

1. **1.870 file mp3 (5,8 MB) tidak terpakai.** Sesuai pilihan Anda, file-nya dibiarkan di repo.
   Perlu keputusan apakah nanti dibersihkan. Sebelum menghapus, pastikan `tools/verify_vocab.py`
   dan `flutter test` tetap hijau. Memangkas repo hanya menghemat ruang git, **tidak** mengurangi
   ukuran APK — APK hanya memuat asset yang dirujuk, dan `flutter build` sudah tidak mengikutsertakan
   file yang tidak terpakai.
2. ~~**8 kata cuma 1 kana masih ada**~~ — **DIPUTUSKAN Anda untuk dibiarkan.** Jumlahnya kini 10
   (paket menambah `ち` = darah dan `は` = gigi). Semuanya punya arti dan rekaman, jadi tetap dipakai.
3. ~~**412 kata sudah punya arti tapi belum dapat tingkat/kategori.**~~ — **SELESAI** di commit
   `e80c35f`. Semua 1.272 kata kini punya arti, tingkat, dan kategori (N5–N4 900, N3 372).
   Lima kategori baru diperkenalkan: Hewan, Alam, Tubuh, Pakaian, Rumah.
4. **Suara belum didengarkan satu per satu.** README paket menyatakan hanya pemeriksaan otomatis
   (Open JTalk membaca `は` sebagai partikel, jadi 3 kata dibuat ulang lewat tulisan katakana).
   1.028 mp3 baru belum didengar manusia — ini yang paling tidak bisa diverifikasi di sini.
5. **`word_history` di database lokal** masih menyimpan 9.356 kata dari pool lama. Tidak merusak
   apa pun (`pick()` hanya memprioritaskan yang belum pernah muncul), tapi isinya sudah basi.
6. **Dokumentasi paket (`README_UPDATE.md`, `OPENCODE_TASK.md`) tidak ikut diperbarui** — keduanya
   masih menyebut 9.663 kata dan "~860 kata". Keduanya di folder paket, bukan di repo.
7. **Tidak ada build rilis.** Hanya `flutter build apk --debug` (165 MB, semua arsitektur) yang
   dijalankan. `flutter build apk --split-per-abi` belum dicoba, jadi perkiraan ukuran APK rilis
   belum diketahui.

## 8. Commit

- `e80df4e` — "Kembalikan kosakata ke daftar kurasi 729 kata" (sebelum paket, sudah ada sebelumnya)
- `65a654a` — "Kosakata berkelompok N5-N4/N3 (860 kata), arti Indonesia, suara tohoku-f01, filter tingkat"
- `e80c35f` — "Tingkatkan 412 kata yang belum punya label; audit duplikat dan suara"
- `3f5d99c` — "Laporan kerja update kosakata"
- `<commit terakhir>` — "Perbarui laporan setelah tingkatkan semua kata"

**Konfirmasi: tidak ada `git push`.** Semua pekerjaan hanya di commit lokal. Branch `develop-v02`
tidak ter-push; `origin/develop-v02` masih menunjuk ke `ee203cb`.

Untuk membatalkan seluruh pekerjaan paket:

```bash
git reset --hard e80df4e
```