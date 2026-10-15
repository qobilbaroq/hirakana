/// Lapisan kecil yang menyembunyikan perbedaan penyimpanan database antar
/// platform, supaya [LocalDatabase] tidak perlu tahu-menahu soal native/ffi/web.
///
/// - Android/iOS/macOS : `sqflite` (plugin native, bawaan Flutter).
/// - Linux/Windows    : `sqflite_common_ffi` (SQLite lewat dynamic library).
/// - Web              : `sqflite_common_ffi_web` (SQLite WASM + IndexedDB).
///
/// Di Android/iOS/macOS kode di bawah ini tetap memakai `sqflite` asli, jadi
/// perilakunya tidak berubah dari versi sebelumnya.
library;

export 'database_factory_io.dart' if (dart.library.js_interop) 'database_factory_web.dart';