# Catatan rilis Kana Quest

Dokumen ini hanya berisi daftar versi dan apa yang berubah. Panduan teknis
publishing ke Play Store tidak disimpan di sini.

## Catatan rilis 1.4.0 (kode build 5)

### Untuk pengguna

- **Suara kata sekarang dibacakan utuh.** Kata yang tidak punya rekaman di dalam
  aplikasi, dan rangkaian 2-3 huruf, dibaca oleh text-to-speech (TTS) milik HP
  sebagai satu ucapan. Sebelumnya huruf dibunyikan satu per satu yang terdengar
  lambat dan terputus-putus.
- **Arti kata muncul setelah menjawab**, bukan hanya saat benar. Arti Bahasa
  Indonesia dipakai dulu; kalau belum ada, arti Inggris ditampilkan dengan
  label kecil `EN`.
- Latihan baca memakai kosakata JLPT N5, N4, dan N3 (bukan daftar kata umum):
  **2.865 kata**, semuanya sudah punya arti Bahasa Indonesia. Di Settings ada
  pilihan tingkat: N5 saja, N5-N4, atau N5-N3 (default), dan saklar
  *Include other common words*.
- Tab Practice menampilkan saran "Tambah huruf untuk membuka lebih banyak kata."
  kalau huruf aktif yang dipilih menghasilkan kata terlalu sedikit.
- Cadangan bunyi huruf demi huruf dipercepat (jeda 40 ms jadi 15 ms, versi lambat
  160 ms jadi 90 ms) supaya tidak terasa terlalu lambat.

### Untuk diperiksa sendiri

TTS bergantung pada voice bahasa Jepang yang terpasang di perangkat. Kalau
belum terpasang, aplikasi memberi tahu sekali per sesi dan memakai cadangan
huruf demi huruf. Kualitas suara berbeda antar HP dan antar vendor, jadi
sebagian besar suara kata **tidak** akan sama dengan rekaman aslinya.
Desktop Linux tidak memakai TTS sama sekali (selalu huruf demi huruf).

Arti Bahasa Indonesia hasil terjemahan sendiri, jadi ada mungkin istilah yang
kurang tepat. Arti Inggris dari sumber aslinya tetap dipakai sebagai cadangan
dan bisa dibandingkan lewat menu Settings.

## Catatan rilis 1.3.0 (kode build 4)

- Panjang sesi bisa diatur (10 sampai 60, kelipatan 5).
- Latihan baca dirombak: tebak romaji dari kata, rangkaian huruf, atau satu huruf.
- Mode gelap dan AMOLED dirapikan.
- Tabel All characters selebar layar.

## Catatan rilis 1.2.0 (kode build 3)

- Audio huruf rekaman (just-gojuon, MIT) dan versi lambat.
- Latihan baca kata pertama.
- Huruf aktif dipilih pengguna (Choose letters).
- Ikon adaptif, monokrom, dan splash terang/gelap.