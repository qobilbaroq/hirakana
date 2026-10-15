import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _dbFileName = 'kana_quest.db';

/// True kalau platform ini sudah punya plugin `sqflite` bawaan.
bool get _hasNativeSqflite =>
    Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

/// Menyiapkan database factory untuk platform ini dan mengembalikan lokasi
/// file database (sudah termasuk nama filenya).
Future<String> initDatabaseFactory() async {
  if (_hasNativeSqflite) {
    // Plugin native men-register dirinya sendiri, tidak perlu disetel apa-apa.
    return p.join(await getDatabasesPath(), _dbFileName);
  }

  // Linux & Windows: SQLite dari dynamic library sistem (libsqlite3).
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final dir = await getApplicationSupportDirectory();
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return p.join(dir.path, _dbFileName);
}