# Usulan — Suara Huruf & Alternatif Anti-Monoton

Dua hal yang Anda ajukan. Bagian A sudah saya periksa kelayakannya di mesin ini,
bagian B adalah pilihan yang belum dikerjakan dan butuh persetujuan Anda.

---

## A. Suara huruf pakai htsvoice-tohoku-f01 (ganti just-gojuon)

### Apakah bisa?

**Bisa**, tapi tidak bisa saya kerjakan sendiri di sini karena dua hal:

| Kebutuhan | Status di mesin ini |
| --- | --- |
| `open-jtalk` | belum terpasang |
| kamus `naist-jdic` | belum terpasang |
| `ffmpeg` | sudah ada |
| `tohoku-f01-neutral.htsvoice` | belum ada |
| jaringan ke GitHub | ada (sudah saya tes) |
| `sudo` | butuh password, tidak bisa saya pakai |

Jadi dua perintah berikut harus Anda jalankan sendiri. Setelah itu saya lanjutkan
membuat file suaranya.

```bash
sudo apt install open-jtalk open-jtalk-mecab-naist-jdic ffmpeg
git clone https://github.com/icn-lab/htsvoice-tohoku-f01.git ~/htsvoice-tohoku-f01
```

Beri tahu kalau sudah, saya jalankan generatornya.

### Kenapa ini sebenarnya bagus — alasan yang belum Anda sebut

Dokumentasi kami sendiri mencatat ini sebagai **risiko rilis**:

> `audio/*.mp3` huruf (just-gojuon) — MIT untuk repo; **asal rekaman tidak dijelaskan,
> cek sebelum rilis publik**

Artinya lisensi MIT itu hanya menutupi repo-nya, sementara rekaman nyatari berasal dari
siapa tidak dijelaskan. Kalau app ini dirilis ke publik, itu pertanyaan yang belum
terjawab.

tohoku-f01 punya asal yang jelas: HTS voice dari Tohoku University ICN Lab, CC BY 4.0,
dan kreditnya **sudah tampil** di Settings. Maka mengganti ke sana:

- menghapus satu risiko lisensi yang belum terjawab, dan
- membuat semua suara app (huruf dan kata) dari satu sumber yang sama.

### Kekhawatiran Anda: takut terlalu cepat karena cuma satu huruf

Kekhawatiran itu wajar, dan memang hal yang harus ditangani. Saya ukur durasi yang
sekarang:

| | Durasi | Kualitas |
| --- | --- | --- |
| Huruf, just-gojuon normal (manusia) | 0,65–1,67 dtk, rata-rata 1,21 | 44,1 kHz mono |
| Huruf, just-gojuon lambat | 0,91–2,51 dtk, rata-rata 1,79 | 44,1 kHz mono |
| Kata, tohoku-f01 | 0,63–1,75 dtk, rata-rata 0,99 | 22,05 kHz mono |

File kata terpendek, `aa.mp3`, hanya 0,63 detik. Kalau `か` disintesis apa adanya,
suaranya bakal lebih pendek dari itu, dan itu memang terdengar seperti dibacakan
terburu-buru — persis yang Anda khawatirkan. Satu huruf memang tidak ergonomis kalau
diputar berdiri sendiri.

**Solusinya sudah jadi kebiasaan di buku pelajaran Jepang: tambah vokal di belakangnya.**

```
か  ->  かあ  (kaa)        く  ->  くう  (kuu)
し  ->  しあ  (shia)       つ  ->  つあ  (tsua)
```

Vokal tambahan menambah sekitar 0,3 sampai 0,5 detik dan terdengar jelas sebagai satu
suku kata yang utuh. Cara/Duration: begini cara buku pelajaran SD dan SMP mengucap
setiap kana satu per satu.

Hasilnya, `かあ` akan sekitar 0,8 sampai 1,0 detik — panjangnya sudah sebanding dengan
rekaman just-gojuon sekarang (1,21 detik), tapi dengan satu suara yang konsisten dengan
suara kata.

### Konsekuensi yang perlu disadari

| | |
| --- | --- |
| Kualitas suara huruf turun sedikit | just-gojuon adalah manusia yang sengaja mengucap tiap kana satu per satu dengan jelas; itu pedagogis ideal untuk belajar huruf. Sintesis untuk kana tunggal cenderung lebih mechanical |
| Semua 208 file huruf diganti | 104 normal dan 104 lambat, sekitar 29 MB baru |
| Pengaturan kecepatan berubah | `atempo=0.65` yang dipakai untuk versi lambat perlu disetel ulang |
| Tidak bisa diverifikasi dari sini | kualitas bunyi harus Anda dengar sendiri setelah di-generate |

### Yang perlu Anda putuskan

1. **Semua** 208 file diganti, atau cukup **104 file lambat** sehingga mode lambat tetap
   memakai rekaman manusia?
2. Vokal tambahan: **pakai** (`かあ`) atau **tanpa** (`か`)?
3. Kalau ternyata bunyinya kurang bagus, file lama masih ada di `git` dan bisa di-rollback.

---

## B. Alternatif supaya latihan baca tidak monoton

Sekarang setelah semua soal jadi kata, memang cuma ada satu jenis soal. Ini konsekuensi
yang sengaja kita ambil. Kalau huruf aktif masih sedikit, kata diulang, jadi rasa monoton
berasal dari **pool kata yang kecil**, bukan dari format soalnya.

### Urutan menurut saya

| # | Usulan | Kesulitan | Nilai |
| --- | --- | --- | --- |
| B1 | **Soal tebak arti** — tampilkan kata dan putar suaranya, pilih arti Indonesia dari 4 pilihan. Skill-nya berbeda total dari "tebak romaji". Semua data sudah ada | Rendah | Tinggi |
| B2 | **Prioritaskan kata yang sering salah** — `word_history` sekarang hanya mencatat `seen_count` dan `last_at`, tidak ada data benar/salah. Tambah kolom `wrong_count`, lalu kata yang sering salah dimunculkan lebih dulu | Sedang | Tinggi |
| B3 | **Campur N5-N4 dan N3 dalam satu sesi** — sekarang memilih tingkat memfilter semua kata. Mode campur membiarkan dua tingkat bercampur supaya sesi terasa lebih beragam | Rendah | Sedang |
| B4 | **Balik arah soal** — sekarang kana ke romaji. Tambahkan mode romaji ke kana | Sedang | Sedang |
| B5 | **Soal susun kata** — diberi tiga huruf, pilih kata yang bisa dibentuk | Sedang | Sedang |
| B6 | **Tampilkan kanji** di samping kana | Tinggi | Tinggi |

### Yang saya rekomendasikan

**B1 dulu.** Alasannya:

- Semua 1.272 kata sudah punya arti Bahasa Indonesia dan rekaman utuh, jadi tidak perlu
  data baru sama sekali.
- Itu menguji kemampuan yang benar-benar berbeda, yaitu memahami makna, bukan sekadar
  bisa membacakan huruf.
- Ini akan langsung terasa di pemakaian karena jumlah jenis soal jadi dua.
- Risikonya rendah, dan kalau ternyata tidak cocok tinggal dimatikan.

**B2 menyusul** kalau Anda memang mau sifat adaptif yang benar-benar bekerja, tapi perlu
migrasi database dari versi 3 ke 4.

### B1 secara lebih rinci, kalau dipilih

```
┌─────────────────────────────────┐
│                                 │
│            さかな                │   ← kata sungguhan, besar
│                                 │
│       ▶  Putar suara            │   ← rekaman utuh tohoku-f01
│                                 │
│      Apa artinya "さかな"?        │
│                                 │
│  ┌───────────┐ ┌───────────┐    │
│  │  ikan     │ │itig        │    │   ← 4 pilihan arti Indonesia
│  └───────────┘ │           │    │      pengecoh diambil dari kata
│  ┌───────────┐ │           │    │      lain di kategori yang SAMA
│  │  garam    │ └───────────┘    │      (mis. kata makanan lain)
│  └───────────┘ ┌───────────┐    │
│  ┌───────────┐ │ daging     │    │
│  │ udang     │ └───────────┘    │
│  └───────────┘                   │
└─────────────────────────────────┘
```

Semua yang dibutuhkan sudah ada. Pengerjaan: tambah `ReadKind.meaning`, tambah
`buildMeaningOptions()` dengan pengecoh dari kategori yang sama, lalu tambah test.

---

## C. Ringkasan

| | |
| --- | --- |
| A — suara huruf tohoku-f01 | Bisa. Butuh dua perintah dari Anda karena `sudo` terkunci. Sekaligus menyelesaikan risiko lisensi just-gojuon. Vokal tambahan perlu supaya tidak terlalu cepat |
| B1 — soal tebak arti | Sangat direkomendasikan, datanya sudah siap |
| B2 — prioritaskan kata yang sering salah | Perlu migrasi database |
| B3 sampai B6 | Opsional |