import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../core/audio/kana_audio_service.dart';
import '../../core/settings/app_settings.dart';
import '../../core/widgets/answer_option.dart';
import '../../core/widgets/kana_character.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/session_header.dart';
import '../../data/repositories/kana_repository.dart';
import '../../data/repositories/word_repository.dart';
import '../../data/seed/word_data.dart';
import '../learn/session_controller.dart';

class _WordQuestion {
  const _WordQuestion({
    required this.word,
    required this.options,
  });

  final Word word;
  final List<String> options; // cara baca (romaji), salah satunya benar
  String get answer => word.reading;
}

/// Pilihan jawaban untuk satu kata: [answer] selalu ikut, sisanya dipilih dari
/// kata lain yang panjang romajinya mirip supaya tidak bisa ditebak dari
/// panjang saja. Dipisah dari widget supaya bisa diuji langsung.
List<String> buildWordOptions(
  Word w,
  List<Word> available,
  Random rng,
) {
  int gap(Word x) => (x.reading.length - w.reading.length).abs();
  final others = [...available, ...allWords]
    ..removeWhere((x) => x.text == w.text);
  others.shuffle(rng);
  others.sort((a, b) => gap(a).compareTo(gap(b)));

  final options = <String>{w.reading};
  for (final x in others) {
    options.add(x.reading);
    if (options.length == 4) break;
  }
  final result = options.toList()..shuffle(rng);
  assert(
    result.contains(w.reading) && result.length == 4,
    'Pilihan kata tidak sah untuk "${w.text}" (${w.reading}): $result',
  );
  return result;
}

/// Latihan membaca kata: lihat kata, pilih cara baca atau artinya.
/// Hanya memakai kata yang tersusun dari huruf pilihan pengguna.
class WordPracticeScreen extends StatefulWidget {
  const WordPracticeScreen({super.key, required this.args});

  final SessionArgs args;

  @override
  State<WordPracticeScreen> createState() => _WordPracticeScreenState();
}

class _WordPracticeScreenState extends State<WordPracticeScreen> {
  final _repo = KanaRepository.instance;
  final _rng = Random();
  final _clock = Stopwatch();

  final List<_WordQuestion> _questions = [];
  bool _loaded = false;
  int _index = 0;
  int _correct = 0;
  int _answeredCount = 0;
  bool _answered = false;
  String? _picked;
  int? _sessionId;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    if (!_finished) _save();
    super.dispose();
  }

  Future<void> _start() async {
    final pool = await WordRepository.instance.available(widget.args.type);
    pool.shuffle(_rng);
    final chosen = pool.take(WordRepository.sessionSize).toList();
    for (final w in chosen) {
      _questions.add(_build(w, pool));
    }
    _sessionId = await _repo.startSession('words', widget.args.type);
    _clock.start();
    if (!mounted) return;
    setState(() => _loaded = true);
  }

  _WordQuestion _build(Word w, List<Word> available) =>
      _WordQuestion(word: w, options: buildWordOptions(w, available, _rng));

  Future<void> _save() async {
    final id = _sessionId;
    if (id == null) return;
    await _repo.updateSession(id,
        seconds: _clock.elapsed.inSeconds,
        cards: _answeredCount,
        correct: _correct);
  }

  Future<void> _answer(String option) async {
    if (_answered) return;
    final q = _questions[_index];
    final ok = option == q.answer;
    setState(() {
      _answered = true;
      _picked = option;
      _answeredCount++;
      if (ok) _correct++;
    });
    // Suara baru diputar setelah menjawab, supaya tidak membocorkan jawaban.
    if (AppSettings.instance.autoPlay) _hear(q);
    await _save();
  }

  /// Putar kata utuh (normal, normal, lambat sesuai Settings).
  void _hear(_WordQuestion q) {
    KanaAudioService.instance.playWordCycle(q.word);
  }

  void _next() {
    KanaAudioService.instance.resetCycle();
    if (_index + 1 >= _questions.length) {
      _finished = true;
      _save();
      Navigator.pushReplacementNamed(
        context,
        AppRouter.summary,
        arguments: SessionResult(
          mode: 'words',
          args: widget.args,
          cards: _questions.length,
          correct: _correct,
          answered: _answeredCount,
          needsReview: const [],
          seconds: _clock.elapsed.inSeconds,
        ),
      );
      return;
    }
    setState(() {
      _index++;
      _answered = false;
      _picked = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final q = _questions[_index];
    final last = _index + 1 >= _questions.length;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              SessionHeader(
                title: 'WORDS · ${_index + 1} / ${_questions.length}',
                progress: _index / _questions.length,
                leadingIcon: Icons.arrow_back,
                onLeading: () => Navigator.pop(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  child: Column(
                    children: [
                      Text(
                        'How do you read this word?',
                        textAlign: TextAlign.center,
                        style: AppText.section,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: KanaCharacter(q.word.text, size: 64),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _grid(q),
                      const SizedBox(height: AppSpacing.md),
                      _feedback(q),
                    ],
                  ),
                ),
              ),
              if (_answered)
                PrimaryButton(
                  label: last ? 'Finish' : 'Next',
                  trailing: Icons.arrow_forward,
                  onPressed: _next,
                )
              else
                Text(
                  'Pilih satu jawaban. Feedback muncul setelah kamu menjawab.',
                  style: AppText.muted,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _grid(_WordQuestion q) {
    Widget tile(String option) {
      var state = OptionState.idle;
      if (_answered) {
        if (option == q.answer) {
          state = OptionState.correct;
        } else if (option == _picked) {
          state = OptionState.wrong;
        } else {
          state = OptionState.dimmed;
        }
      }
      return AnswerOption(
        label: option,
        isKana: false,
        state: state,
        textSize: 22,
        onTap: _answered ? null : () => _answer(option),
      );
    }

    final o = q.options;
    final rows = <Widget>[];
    for (var i = 0; i < o.length; i += 2) {
      rows.add(Row(children: [
        Expanded(child: tile(o[i])),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: i + 1 < o.length ? tile(o[i + 1]) : const SizedBox()),
      ]));
      if (i + 2 < o.length) rows.add(const SizedBox(height: AppSpacing.sm));
    }
    return Column(children: rows);
  }

  Widget _feedback(_WordQuestion q) {
    if (!_answered) return const SizedBox(height: 24);
    final ok = _picked == q.answer;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              ok ? Icons.check_circle : Icons.info_outline,
              color: ok ? AppColors.sage : AppColors.clay,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(ok ? "Nice, that's right." : 'Not quite.', style: AppText.body),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${q.word.text}  ·  ${q.word.reading}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Noto Sans JP',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        // Arti baru dibuka setelah jawaban benar.
        if (ok) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(q.word.meaning, textAlign: TextAlign.center, style: AppText.muted),
        ],
        TextButton.icon(
          onPressed: () => _hear(q),
          icon: const Icon(Icons.volume_up_outlined, size: 20),
          label: const Text('Hear it again'),
        ),
      ],
    );
  }
}
