class StudySession {
  const StudySession({
    required this.id,
    required this.mode,
    required this.kanaType,
    required this.startedAt,
    required this.durationSeconds,
    required this.cards,
    required this.correct,
  });

  final int id;
  final String mode; // flashcard | quiz | writing | words | meaning | build_*
  final String kanaType;
  final DateTime startedAt;
  final int durationSeconds;
  final int cards;
  final int correct;

  factory StudySession.fromMap(Map<String, Object?> m) => StudySession(
        id: m['id'] as int,
        mode: m['mode'] as String,
        kanaType: m['kana_type'] as String,
        startedAt:
            DateTime.fromMillisecondsSinceEpoch(m['started_at'] as int),
        durationSeconds: m['duration_sec'] as int,
        cards: m['cards'] as int,
        correct: m['correct'] as int,
      );
}
