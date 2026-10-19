import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'database_factory.dart';

class LocalDatabase {
  LocalDatabase._();
  static final instance = LocalDatabase._();

  Database? _db;

  /// Lokasi file database untuk sesi ini. Diisi oleh [configurePath] saat app
  /// start supaya tiap platform bisa menetapkannya sendiri: Android/iOS/
  /// macOS memakai path bawaan plugin `sqflite`, Linux/Windows memakai app
  /// support dir, dan Web memakai IndexedDB.
  static String? _path;

  /// Menyiapkan database factory untuk platform ini. Harus dipanggil sebelum
  /// [database] dipakai (lihat `main()`).
  static Future<void> configurePath() async {
    _path ??= await initDatabaseFactory();
  }

  /// Hanya untuk pengujian: pakai database di [path] (mis. ':memory:') dan
  /// buang koneksi sebelumnya. Tidak dipakai di kode aplikasi.
  @visibleForTesting
  Future<void> debugUseDatabase(String path) async {
    await _db?.close();
    _db = null;
    _path = path;
  }

  Future<Database> get database async => _db ??= await _open();

  /// Pasangan huruf yang sering tertukar. a_id < b_id (urut) supaya
  /// "ぬ salah jadi め" dan "め salah jadi ぬ" dihitung sebagai satu pasangan.
  static Future<void> _createConfusions(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS confusions (
        a_id TEXT NOT NULL,
        b_id TEXT NOT NULL,
        count INTEGER NOT NULL DEFAULT 1,
        last_at INTEGER NOT NULL,
        PRIMARY KEY (a_id, b_id)
      )
    ''');
  }

  /// Riwayat kata yang sudah pernah muncul di latihan baca, supaya kata yang
  /// belum pernah / paling lama tidak muncul diutamakan.
  static Future<void> _createWordHistory(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS word_history (
        text TEXT PRIMARY KEY,
        seen_count INTEGER NOT NULL DEFAULT 1,
        last_at INTEGER NOT NULL
      )
    ''');
  }

  /// Versi 4: hitung berapa kali kata dijawab benar / salah (latihan baca dan
  /// tebak arti), dipakai menu riwayat kata untuk menyaring "sering salah"
  /// dan "sudah hafal". Kata lama mulai dari 0.
  static Future<void> _addWordHistoryResults(Database db) async {
    await db.execute(
        'ALTER TABLE word_history ADD COLUMN correct_count INTEGER NOT NULL DEFAULT 0');
    await db.execute(
        'ALTER TABLE word_history ADD COLUMN wrong_count INTEGER NOT NULL DEFAULT 0');
  }

  Future<Database> _open() async {
    final path = _path ?? join(await getDatabasesPath(), 'kana_quest.db');
    return openDatabase(
      path,
      version: 4,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _createConfusions(db);
        if (oldVersion < 3) await _createWordHistory(db);
        if (oldVersion < 4) await _addWordHistoryResults(db);
      },
      onCreate: (db, version) async {
        await _createConfusions(db);
        await _createWordHistory(db);
        await _addWordHistoryResults(db);
        await db.execute('''
          CREATE TABLE kana_progress (
            kana_id TEXT PRIMARY KEY,
            correct_count INTEGER NOT NULL DEFAULT 0,
            wrong_count INTEGER NOT NULL DEFAULT 0,
            consecutive_correct INTEGER NOT NULL DEFAULT 0,
            consecutive_wrong INTEGER NOT NULL DEFAULT 0,
            sessions_correct INTEGER NOT NULL DEFAULT 0,
            last_correct_session_id INTEGER,
            last_reviewed_at INTEGER,
            next_review_at INTEGER,
            mastery_level INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE study_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            mode TEXT NOT NULL,
            kana_type TEXT NOT NULL,
            started_at INTEGER NOT NULL,
            duration_sec INTEGER NOT NULL DEFAULT 0,
            cards INTEGER NOT NULL DEFAULT 0,
            correct INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE meta (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
    );
  }
}
