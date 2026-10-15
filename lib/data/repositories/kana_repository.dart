import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/storage/local_database.dart';
import '../models/kana.dart';
import '../models/kana_progress.dart';
import '../models/study_session.dart';
import '../seed/kana_data.dart';

class ConfusionPair {
  const ConfusionPair(this.a, this.b, this.count);
  final Kana a;
  final Kana b;
  final int count;
}

class HomeStats {
  const HomeStats({
    required this.todaySeconds,
    required this.dayNumber,
    required this.lastMode,
    required this.lastType,
    required this.hasStudied,
  });
  final int todaySeconds;
  final int dayNumber;
  final String lastMode;
  final String lastType;
  final bool hasStudied;
}

class ProgressStats {
  const ProgressStats({
    required this.knownCount,
    required this.totalCount,
    required this.weekSeconds,
    required this.hiraganaMastery,
    required this.katakanaMastery,
    required this.weak,
    required this.levels,
    required this.recent,
    required this.confusions,
  });
  final int knownCount;
  final int totalCount;
  final int weekSeconds;
  final double hiraganaMastery; // 0..1
  final double katakanaMastery; // 0..1
  final List<Kana> weak;
  final Map<String, int> levels; // kanaId -> masteryLevel
  final List<StudySession> recent;
  final List<ConfusionPair> confusions;
}

/// Satu-satunya pintu ke database. Memberi tahu listener (Home, Progress)
/// setiap kali data berubah.
class KanaRepository extends ChangeNotifier {
  KanaRepository._();
  static final instance = KanaRepository._();

  /// Pasangan baru ditampilkan / dilatih kalau sudah tertukar sekian kali.
  static const confusionMin = 2;

  static final Map<String, Kana> _byId = {for (final k in allKana) k.id: k};
  static const starterCount = 5;
  static const sessionSize = 10;

  // Jeda pengulangan sesuai jumlah jawaban benar berturut-turut.
  static const _intervals = [
    Duration(minutes: 10),
    Duration(days: 1),
    Duration(days: 3),
    Duration(days: 7),
    Duration(days: 14),
  ];

  final _store = LocalDatabase.instance;

  Future<void> init() async {
    await _store.database;
    final first = await getMeta('first_open');
    if (first == null) {
      await setMeta('first_open', DateTime.now().millisecondsSinceEpoch.toString());
    }
  }

  List<Kana> kanaOf(String type) {
    if (type == 'hiragana') return hiraganaList;
    if (type == 'katakana') return katakanaList;
    return allKana;
  }

  // ---------------------------------------------------------------- meta

  Future<String?> getMeta(String key) async {
    final db = await _store.database;
    final rows = await db.query('meta', where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> setMeta(String key, String value) async {
    final db = await _store.database;
    await db.insert('meta', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ------------------------------------------------------------ progress

  Future<Map<String, KanaProgress>> loadProgress() async {
    final db = await _store.database;
    final rows = await db.query('kana_progress');
    return {
      for (final r in rows) r['kana_id'] as String: KanaProgress.fromMap(r),
    };
  }

  Future<KanaProgress> _progressOf(String id) async {
    final db = await _store.database;
    final rows =
        await db.query('kana_progress', where: 'kana_id = ?', whereArgs: [id]);
    return rows.isEmpty ? KanaProgress(kanaId: id) : KanaProgress.fromMap(rows.first);
  }

  // ------------------------------------------------- huruf yang dipelajari

  /// Huruf yang dipilih pengguna. Huruf baru TIDAK pernah masuk otomatis.
  Future<Set<String>> activeIds() async {
    final raw = await getMeta('active_ids');
    if (raw == null) {
      // Migrasi dari versi lama: semua huruf yang sudah pernah dipelajari.
      final p = await loadProgress();
      final ids = p.entries
          .where((e) => e.value.reviewed)
          .map((e) => e.key)
          .toSet();
      if (ids.isNotEmpty) await setMeta('active_ids', ids.join(','));
      return ids;
    }
    return raw.isEmpty ? <String>{} : raw.split(',').toSet();
  }

  Future<void> setActiveIds(Set<String> ids) async {
    await setMeta('active_ids', ids.join(','));
    notifyListeners();
  }

  /// Huruf aktif untuk satu set. Kalau set itu belum punya huruf aktif sama
  /// sekali, baris pertamanya dipakai sebagai awalan.
  Future<List<Kana>> activeKana(String type) async {
    var ids = await activeIds();
    final pool = kanaOf(type);
    if (!pool.any((k) => ids.contains(k.id))) {
      final starter = pool.take(starterCount).map((k) => k.id);
      ids = {...ids, ...starter};
      await setActiveIds(ids);
    }
    return pool.where((k) => ids.contains(k.id)).toList();
  }

  /// Menambah [count] huruf berikutnya (urut seperti di dataset) ke set aktif.
  Future<List<Kana>> addNextLetters(String type, {int count = starterCount}) async {
    final ids = await activeIds();
    final next =
        kanaOf(type).where((k) => !ids.contains(k.id)).take(count).toList();
    if (next.isEmpty) return next;
    await setActiveIds({...ids, ...next.map((k) => k.id)});
    return next;
  }

  /// Berapa huruf aktif yang sudah pernah dilihat (syarat untuk kuis).
  Future<int> reviewedActiveCount(String type) async {
    final progress = await loadProgress();
    final active = await activeKana(type);
    return active.where((k) => progress[k.id]?.reviewed ?? false).length;
  }

  /// Menyusun antrean sesi dari huruf aktif saja: yang jatuh tempo dulu
  /// (yang sering salah di depan), lalu yang belum pernah dilihat, lalu sisanya
  /// dari yang paling lama tidak dibuka. Kalau huruf aktif <= [size], semuanya
  /// ikut, jadi kamu bisa mengulang set kecil yang sama sampai hafal.
  Future<List<Kana>> buildQueue({
    required String type,
    bool quick = false,
    bool reviewedOnly = false,
    int size = sessionSize,
    bool shuffle = true,
    Random? rng,
  }) async {
    final progress = await loadProgress();
    final active = await activeKana(type);
    final now = DateTime.now();

    bool seen(Kana k) => progress[k.id]?.reviewed ?? false;

    var pool = active;
    if (reviewedOnly) {
      pool = active.where(seen).toList();
    } else if (quick) {
      final reviewed = active.where(seen).toList();
      if (reviewed.isNotEmpty) pool = reviewed;
    }

    // Prioritas TIDAK diacak: yang menentukan huruf APA yang dipilih.
    // 1. due       = jatuh tempo / sering salah
    // 2. fresh     = belum pernah dilihat
    // 3. rest      = yang paling lama tidak jatuh tempo
    final due = pool.where((k) {
      if (!seen(k)) return false;
      final next = progress[k.id]!.nextReviewAt;
      return next == null || !next.isAfter(now);
    }).toList()
      ..sort((a, b) =>
          progress[b.id]!.wrongCount.compareTo(progress[a.id]!.wrongCount));

    final fresh = pool.where((k) => !seen(k)).toList();

    final rest = pool.where((k) => seen(k) && !due.contains(k)).toList()
      ..sort((a, b) {
        final an = progress[a.id]!.nextReviewAt ?? now;
        final bn = progress[b.id]!.nextReviewAt ?? now;
        return an.compareTo(bn);
      });

    final chosen = [...due, ...fresh, ...rest].take(size).toList();

    // Affiliative rule: huruf yang SAMA tidak boleh muncul dua kali berturut.
    if (shuffle) _spreadNoRepeat(chosen, rng ?? Random());
    return chosen;
  }

  /// Mengacak [items] tanpa pernah menyisipkan nilai yang sama di sebelahnya.
  void _spreadNoRepeat(List<Kana> items, Random rng) {
    if (items.length < 2) return;
    items.shuffle(rng);
    for (var pass = 0; pass < 12; pass++) {
      var bad = false;
      for (var i = 1; i < items.length; i++) {
        if (items[i].id != items[i - 1].id) continue;
        bad = true;
        // Cari posisi lain yang tidak bersebelahan dengan elemen yang sama.
        for (var j = items.length - 1; j > 0; j--) {
          if (items[j].id != items[i].id) continue;
          final clash = (j - 1 >= 0 && items[j - 1].id == items[i].id) ||
              (j + 1 < items.length && items[j + 1].id == items[i].id);
          if (clash) continue;
          final tmp = items[i];
          items[i] = items[j];
          items[j] = tmp;
          break;
        }
      }
      if (!bad) return;
    }
  }

  /// Mencatat satu jawaban. [fast] = terlalu cepat, jadi tidak dihitung
  /// sebagai bukti penguasaan lintas sesi.
  Future<void> recordAnswer({
    required int sessionId,
    required Kana kana,
    required bool correct,
    required bool fast,
    bool retry = false,
  }) async {
    final db = await _store.database;
    final p = await _progressOf(kana.id);
    final now = DateTime.now();

    var correctCount = p.correctCount;
    var wrongCount = p.wrongCount;
    var consCorrect = p.consecutiveCorrect;
    var consWrong = p.consecutiveWrong;
    var sessionsCorrect = p.sessionsCorrect;
    var lastSession = p.lastCorrectSessionId;
    DateTime next;

    if (correct && retry) {
      // Benar di "second look" setelah Again: kartu ditutup di sesi ini, tapi
      // belum dihitung sebagai bukti penguasaan. Muncul lagi sebentar lagi.
      correctCount++;
      consWrong = 0;
      next = now.add(const Duration(minutes: 10));
    } else if (correct) {
      correctCount++;
      consCorrect++;
      consWrong = 0;
      if (!fast && lastSession != sessionId) {
        sessionsCorrect++;
        lastSession = sessionId;
      }
      next = now.add(_intervals[min(consCorrect - 1, _intervals.length - 1)]);
    } else {
      wrongCount++;
      consWrong++;
      consCorrect = 0;
      // Dua salah beruntun: langsung jadwalkan untuk sesi berikutnya.
      next = consWrong >= 2 ? now : now.add(const Duration(minutes: 1));
    }

    final int level;
    if (sessionsCorrect >= 3 && consCorrect >= 2) {
      level = 3;
    } else if (sessionsCorrect >= 2) {
      level = 2;
    } else {
      level = 1;
    }

    await db.insert(
      'kana_progress',
      KanaProgress(
        kanaId: kana.id,
        correctCount: correctCount,
        wrongCount: wrongCount,
        consecutiveCorrect: consCorrect,
        consecutiveWrong: consWrong,
        sessionsCorrect: sessionsCorrect,
        lastCorrectSessionId: lastSession,
        lastReviewedAt: now,
        nextReviewAt: next,
        masteryLevel: level,
      ).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    notifyListeners();
  }

  // --------------------------------------------------------- tertukar

  /// Mencatat bahwa [picked] dipilih padahal jawaban benar [target].
  Future<void> recordConfusion(Kana target, Kana picked) async {
    if (target.id == picked.id) return;
    final ids = [target.id, picked.id]..sort();
    final db = await _store.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final updated = await db.rawUpdate(
      'UPDATE confusions SET count = count + 1, last_at = ? WHERE a_id = ? AND b_id = ?',
      [now, ids[0], ids[1]],
    );
    if (updated == 0) {
      await db.insert('confusions',
          {'a_id': ids[0], 'b_id': ids[1], 'count': 1, 'last_at': now});
    }
    notifyListeners();
  }

  Future<List<ConfusionPair>> topConfusions({int limit = 6, int minCount = 1}) async {
    final db = await _store.database;
    final rows = await db.query(
      'confusions',
      where: 'count >= ?',
      whereArgs: [minCount],
      orderBy: 'count DESC, last_at DESC',
      limit: limit,
    );
    final result = <ConfusionPair>[];
    for (final r in rows) {
      final a = _byId[r['a_id']];
      final b = _byId[r['b_id']];
      if (a != null && b != null) result.add(ConfusionPair(a, b, r['count'] as int));
    }
    return result;
  }

  /// Huruf -> pasangan yang sering tertukar dengannya (dipakai sebagai
  /// pengecoh utama di kuis).
  Future<Map<String, List<Kana>>> confusionPartners() async {
    final pairs = await topConfusions(limit: 100);
    final map = <String, List<Kana>>{};
    for (final p in pairs) {
      map.putIfAbsent(p.a.id, () => []).add(p.b);
      map.putIfAbsent(p.b.id, () => []).add(p.a);
    }
    return map;
  }

  /// Antrean "look-alike drill": anggota pasangan yang sering tertukar.
  Future<List<Kana>> confusableQueue({int size = sessionSize}) async {
    final pairs = await topConfusions(limit: 8, minCount: confusionMin);
    final seen = <String>{};
    final result = <Kana>[];
    for (final p in pairs) {
      for (final k in [p.a, p.b]) {
        if (seen.add(k.id)) result.add(k);
      }
    }
    return result.take(size).toList();
  }

  // ------------------------------------------------------------ sessions

  Future<int> startSession(String mode, String type) async {
    final db = await _store.database;
    return db.insert('study_sessions', {
      'mode': mode,
      'kana_type': type,
      'started_at': DateTime.now().millisecondsSinceEpoch,
      'duration_sec': 0,
      'cards': 0,
      'correct': 0,
    });
  }

  Future<void> updateSession(
    int id, {
    required int seconds,
    required int cards,
    required int correct,
  }) async {
    final db = await _store.database;
    await db.update(
      'study_sessions',
      {'duration_sec': seconds, 'cards': cards, 'correct': correct},
      where: 'id = ?',
      whereArgs: [id],
    );
    notifyListeners();
  }

  Future<int> _secondsSince(DateTime from) async {
    final db = await _store.database;
    final r = await db.rawQuery(
      'SELECT COALESCE(SUM(duration_sec), 0) AS s FROM study_sessions WHERE started_at >= ?',
      [from.millisecondsSinceEpoch],
    );
    return (r.first['s'] as num).toInt();
  }

  Future<bool> hasStudied() async {
    final db = await _store.database;
    final r = await db.rawQuery('SELECT COUNT(*) AS c FROM kana_progress');
    return (r.first['c'] as int) > 0;
  }

  // --------------------------------------------------------------- stats

  Future<HomeStats> homeStats() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final firstMs = int.tryParse(await getMeta('first_open') ?? '') ??
        now.millisecondsSinceEpoch;
    final first = DateTime.fromMillisecondsSinceEpoch(firstMs);
    final firstDay = DateTime(first.year, first.month, first.day);
    return HomeStats(
      todaySeconds: await _secondsSince(midnight),
      dayNumber: midnight.difference(firstDay).inDays + 1,
      lastMode: await getMeta('last_mode') ?? 'flashcard',
      lastType: await getMeta('last_type') ?? 'hiragana',
      hasStudied: await hasStudied(),
    );
  }

  Future<ProgressStats> progressStats() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final monday = midnight.subtract(Duration(days: now.weekday - 1));
    final progress = await loadProgress();

    double mastery(List<Kana> list) {
      final sum =
          list.fold<int>(0, (s, k) => s + (progress[k.id]?.masteryLevel ?? 0));
      return sum / (list.length * 3);
    }

    final weak = allKana.where((k) => progress[k.id]?.needsAnotherLook ?? false).toList()
      ..sort((a, b) =>
          progress[b.id]!.wrongCount.compareTo(progress[a.id]!.wrongCount));

    final db = await _store.database;
    final rows = await db.query('study_sessions',
        where: 'cards > 0', orderBy: 'started_at DESC', limit: 5);

    return ProgressStats(
      knownCount: allKana.where((k) => progress[k.id]?.isMastered ?? false).length,
      totalCount: allKana.length,
      weekSeconds: await _secondsSince(monday),
      hiraganaMastery: mastery(hiraganaList),
      katakanaMastery: mastery(katakanaList),
      weak: weak.take(8).toList(),
      levels: {for (final e in progress.entries) e.key: e.value.masteryLevel},
      recent: rows.map(StudySession.fromMap).toList(),
      confusions: await topConfusions(limit: 6, minCount: confusionMin),
    );
  }
}
