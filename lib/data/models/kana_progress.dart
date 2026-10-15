class KanaProgress {
  const KanaProgress({
    required this.kanaId,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.consecutiveCorrect = 0,
    this.consecutiveWrong = 0,
    this.sessionsCorrect = 0,
    this.lastCorrectSessionId,
    this.lastReviewedAt,
    this.nextReviewAt,
    this.masteryLevel = 0,
  });

  final String kanaId;
  final int correctCount;
  final int wrongCount;
  final int consecutiveCorrect;
  final int consecutiveWrong;

  /// Jumlah sesi BERBEDA tempat huruf ini dijawab benar (dengan tenang).
  final int sessionsCorrect;
  final int? lastCorrectSessionId;
  final DateTime? lastReviewedAt;
  final DateTime? nextReviewAt;

  /// 0 = baru, 1 = belajar, 2 = mulai familiar, 3 = dikuasai.
  final int masteryLevel;

  bool get reviewed => lastReviewedAt != null;
  bool get isMastered => masteryLevel >= 3;
  bool get needsAnotherLook => reviewed && wrongCount > 0 && !isMastered;

  Map<String, Object?> toMap() => {
        'kana_id': kanaId,
        'correct_count': correctCount,
        'wrong_count': wrongCount,
        'consecutive_correct': consecutiveCorrect,
        'consecutive_wrong': consecutiveWrong,
        'sessions_correct': sessionsCorrect,
        'last_correct_session_id': lastCorrectSessionId,
        'last_reviewed_at': lastReviewedAt?.millisecondsSinceEpoch,
        'next_review_at': nextReviewAt?.millisecondsSinceEpoch,
        'mastery_level': masteryLevel,
      };

  factory KanaProgress.fromMap(Map<String, Object?> m) {
    DateTime? date(Object? v) =>
        v == null ? null : DateTime.fromMillisecondsSinceEpoch(v as int);
    return KanaProgress(
      kanaId: m['kana_id'] as String,
      correctCount: m['correct_count'] as int,
      wrongCount: m['wrong_count'] as int,
      consecutiveCorrect: m['consecutive_correct'] as int,
      consecutiveWrong: m['consecutive_wrong'] as int,
      sessionsCorrect: m['sessions_correct'] as int,
      lastCorrectSessionId: m['last_correct_session_id'] as int?,
      lastReviewedAt: date(m['last_reviewed_at']),
      nextReviewAt: date(m['next_review_at']),
      masteryLevel: m['mastery_level'] as int,
    );
  }
}
