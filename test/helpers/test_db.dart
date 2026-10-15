import 'package:flutter_test/flutter_test.dart';
import 'package:kana_quest/core/storage/local_database.dart';
import 'package:kana_quest/data/models/kana.dart';
import 'package:kana_quest/data/models/kana_progress.dart';
import 'package:kana_quest/data/repositories/kana_repository.dart';
import 'package:kana_quest/data/seed/kana_data.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Database in-memory dengan skema asli aplikasi, untuk pengujian.
class TestDb {
  static bool _initialised = false;

  static Future<void> init() async {
    if (_initialised) return;
    _initialised = true;
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  /// Memulai database kosong (skema dibuat oleh LocalDatabase).
  static Future<void> reset() async {
    await init();
    await LocalDatabase.instance.debugUseDatabase(inMemoryDatabasePath);
    // Pastikan tabel dibuat dengan menyentuh handle database.
    await LocalDatabase.instance.database;
  }

  /// Handle database aktif, untuk penyiapan data manual saat pengujian.
  static Future<Database> get store => LocalDatabase.instance.database;

  /// Menandai huruf sebagai "sudah pernah dilihat" supaya kuis (reviewedOnly)
  /// punya antrean.
  static Future<void> markSeen(Iterable<Kana> kana) async {
    final db = await LocalDatabase.instance.database;
    for (final k in kana) {
      await db.insert(
        'kana_progress',
        KanaProgress(
          kanaId: k.id,
          correctCount: 1,
          consecutiveCorrect: 1,
          sessionsCorrect: 1,
          lastReviewedAt: DateTime.now(),
          nextReviewAt: DateTime.now().add(const Duration(days: 1)),
          masteryLevel: 1,
        ).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }
}

/// Huruf aktif sesuai laporan bug: あいうえお + かきくけこ.
List<Kana> get activeVowelsAndK =>
    hiraganaList.where((k) =>
        ['a', 'i', 'u', 'e', 'o', 'ka', 'ki', 'ku', 'ke', 'ko']
            .contains(k.romaji)).toList();

Kana kanaByRomaji(String romaji) =>
    hiraganaList.firstWhere((k) => k.romaji == romaji);

List<Kana> hiraganaByRomaji(List<String> romaji) =>
    hiraganaList.where((k) => romaji.contains(k.romaji)).toList();

/// Repository asli, dipakai setelah [TestDb.reset].
KanaRepository get repo => KanaRepository.instance;