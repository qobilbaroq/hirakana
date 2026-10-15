import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

const _dbFileName = 'kana_quest_web.db';

/// Menyiapkan database factory berbasis WebAssembly dan mengembalikan nama
/// file database yang disimpan di IndexedDB.
///
/// Memakai varian *NoWebWorker*: SQLite dijalankan di thread utama (bukan
/// shared worker `sqflite_sw.js`). Alasannya, `sqflite_sw.js` harus dibangun
/// dengan `dart run sqflite_common_ffi_web:setup`, dan tool `webdev`-nya belum
/// kompatibel dengan Dart SDK >= 3.10 yang dipakai proyek ini. Datanya tetap
/// persisten di IndexedDB; konsekuensinya hanya query yang panjang bisa
/// sesaat memblokir UI. Kalau nanti Dart SDK sudah lebih baru, tinggal ganti
/// ke `databaseFactoryFfiWeb` supaya query jalan di shared worker.
///
/// Butuh berkas `web/sqlite3.wasm` yang sudah ada di proyek ini.
Future<String> initDatabaseFactory() async {
  databaseFactory = databaseFactoryFfiWebNoWebWorker;
  return _dbFileName;
}