import 'dart:math';

import '../../core/settings/app_settings.dart';
import '../../data/models/kana.dart';
import '../../data/repositories/kana_repository.dart';
import 'quiz_question.dart';

class SessionArgs {
  const SessionArgs({
    this.type = 'hiragana',
    this.quick = false,
    this.quizKind,
    this.vocabLevel,
    this.onlyTexts,
  });

  final String type; // hiragana | katakana | mixed
  final bool quick;
  final QuizKind? quizKind; // null = campur semua tipe kuis
  final String? vocabLevel; // latihan baca: n5n4 | n3, null = semua kata
  // Latihan baca / tebak arti: hanya kata-kata ini (mengulang dari riwayat).
  // null = kata biasa dari huruf pilihan.
  final List<String>? onlyTexts;
}

class SessionResult {
  const SessionResult({
    required this.mode,
    required this.args,
    required this.cards,
    required this.correct,
    required this.answered,
    required this.needsReview,
    required this.seconds,
  });

  final String mode; // flashcard | quiz | writing
  final SessionArgs args;
  final int cards;
  final int correct;
  final int answered;
  final List<Kana> needsReview;
  final int seconds;
}

/// Mesin sesi yang dipakai flashcard dan kuis: antrean, pencatatan jawaban
/// per jawaban (aman kalau aplikasi ditutup), dan waktu belajar.
///
/// Aturan "Again": kartu disisipkan lagi setelah 2 kartu lain (maksimal 2 kali
/// per huruf) sebagai "second look". Hitungan posisi (03 / 05) memakai jumlah
/// huruf ASLI, jadi tidak melompat; ulangan ditampilkan sebagai "+N again".
class SessionController {
  SessionController({required this.mode, required this.args});

  final String mode;
  final SessionArgs args;

  String get type => args.type;

  final _repo = KanaRepository.instance;
  final List<Kana> queue = [];
  final List<bool> _retryFlags = []; // sejajar dengan queue: true = ulangan
  final Set<String> _seen = {};
  final Set<String> _struggled = {};
  final List<int> _slotIds = []; // sejajar dengan queue: nomor slot soal
  final Map<int, int> _retries = {}; // slot -> berapa kali diulang
  int _done = 0; // jumlah slot yang sudah selesai

  /// Huruf aktif untuk set ini (dipakai sebagai pilihan jawaban kuis).
  List<Kana> activePool = [];

  /// Huruf -> pasangan yang sering tertukar (pengecoh utama di kuis).
  Map<String, List<Kana>> partners = {};

  int total = 0;
  int index = 0;
  int correct = 0;
  int answered = 0;
  int _seconds = 0;
  int? _sessionId;
  DateTime _lastTick = DateTime.now();
  bool _closed = false;

  Future<void> start() async {
    if (args.quizKind == QuizKind.lookalike) {
      queue.addAll(
          await _repo.confusableQueue(size: AppSettings.instance.sessionSize));
    } else {
      queue.addAll(await _repo.buildQueue(
        type: type,
        quick: args.quick,
        reviewedOnly: mode == 'quiz',
        size: AppSettings.instance.sessionSize,
        fillToSize:
            AppSettings.instance.sessionSize > AppSettings.minSessionSize,
        // Pengenalan pertama pada flashcard tetap berurutan (あ い う え お)
        // supaya terasa natural. Selain itu urutannya diacak.
        shuffle: !(mode == 'flashcard' && await _allUnseen(type)),
      ));
    }
    partners = await _repo.confusionPartners();
    _retryFlags.addAll(List.filled(queue.length, false));
    _slotIds.addAll(List.generate(queue.length, (i) => i));
    total = queue.length;
    activePool = await _repo.activeKana(type);
    _sessionId = await _repo.startSession(mode, type);
    _lastTick = DateTime.now();
    await _repo.setMeta('last_mode', mode);
    await _repo.setMeta('last_type', type);
  }

  /// True kalau tidak satu pun huruf aktif yang belum pernah dibuka --
  /// yaitu sesi pengenalan pertama.
  Future<bool> _allUnseen(String type) async {
    final progress = await _repo.loadProgress();
    final active = await _repo.activeKana(type);
    return active.isNotEmpty &&
        active.every((k) => progress[k.id]?.reviewed != true);
  }

  Kana? get current => index < queue.length ? queue[index] : null;
  bool get finished => index >= queue.length;
  bool get currentIsRetry => index < _retryFlags.length && _retryFlags[index];

  /// Huruf yang sudah selesai di sesi ini (benar, atau ulangan sudah habis).
  int get completed => _done;
  int get position => min(completed + 1, max(total, 1));
  double get progress => total == 0 ? 0 : completed / total;

  /// Berapa ulangan "second look" yang masih menunggu di depan.
  int get retryPending => _retryFlags.skip(index).where((f) => f).length;

  void _tick() {
    final now = DateTime.now();
    // Dibatasi per jawaban supaya HP yang dibiarkan tidak menggelembungkan waktu belajar.
    _seconds += min(now.difference(_lastTick).inSeconds, 90);
    _lastTick = now;
  }

  Future<void> answer(bool ok, {bool fast = false}) async {
    final k = current;
    final id = _sessionId;
    if (k == null || id == null) return;

    final isRetry = _retryFlags[index];
    final slot = _slotIds[index];
    answered++;
    _seen.add(k.id);
    if (ok) {
      correct++;
      _done++;
    } else {
      _struggled.add(k.id);
      final retries = _retries[slot] ?? 0;
      if (retries < 2) {
        _retries[slot] = retries + 1;
        final at = min(index + 3, queue.length);
        queue.insert(at, k);
        _retryFlags.insert(at, true);
        _slotIds.insert(at, slot);
      } else {
        _done++; // ulangan habis, lanjut saja
      }
    }
    index++;
    _tick();

    await _repo.recordAnswer(
      sessionId: id,
      kana: k,
      correct: ok,
      fast: fast,
      retry: isRetry,
    );
    await _repo.updateSession(id,
        seconds: _seconds, cards: _seen.length, correct: correct);
  }

  /// Dipanggil saat pengguna keluar di tengah sesi.
  Future<void> flush() async {
    final id = _sessionId;
    if (_closed || id == null) return;
    _tick();
    await _repo.updateSession(id,
        seconds: _seconds, cards: _seen.length, correct: correct);
  }

  SessionResult finish() {
    _tick();
    _closed = true;
    final id = _sessionId;
    if (id != null) {
      _repo.updateSession(id,
          seconds: _seconds, cards: _seen.length, correct: correct);
    }
    return SessionResult(
      mode: mode,
      args: args,
      cards: _seen.length,
      correct: correct,
      answered: answered,
      needsReview: queue.where((k) => _struggled.contains(k.id)).toSet().toList(),
      seconds: _seconds,
    );
  }
}
