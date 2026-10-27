
import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../core/audio/kana_audio_service.dart';
import '../../core/settings/app_settings.dart';
import '../../core/widgets/answer_option.dart';
import '../../core/widgets/choice_stage.dart';
import '../../core/widgets/kana_character.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/session_header.dart';
import '../../data/repositories/kana_repository.dart';
import '../../data/repositories/word_repository.dart';
import '../../data/seed/kana_data.dart';
import '../../data/seed/word_data.dart';
import '../learn/session_controller.dart';
import 'word_questions.dart';

/// Latihan baca: lihat kata, rangkaian huruf, atau satu huruf, lalu pilih cara
/// bacanya (romaji). Soal diambil dari huruf pilihan pengguna; kata yang
/// belum pernah / paling lama tidak muncul diutamakan. Tidak menanyakan arti.
class WordPracticeScreen extends StatefulWidget {
  const WordPracticeScreen({super.key, required this.args});

  final SessionArgs args;

  @override
  State<WordPracticeScreen> createState() => _WordPracticeScreenState();
}

class _WordPracticeScreenState extends State<WordPracticeScreen> {
  final _repo = KanaRepository.instance;
  final _clock = Stopwatch();

  final List<ReadQuestion> _questions = [];
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
    KanaAudioService.instance.stopSequence();
    if (!_finished) _save();
    super.dispose();
  }

  Future<void> _start() async {
    _questions.addAll(await buildReadingSession(
      type: widget.args.type,
      size: AppSettings.instance.sessionSize,
      vocabLevel: widget.args.vocabLevel,
      onlyTexts: widget.args.onlyTexts,
    ));
    _sessionId = await _repo.startSession('words', widget.args.type);
    _clock.start();
    if (!mounted) return;
    setState(() => _loaded = true);
  }

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
    if (q.kind == ReadKind.word) {
      // Catat supaya kata ini tidak cepat muncul lagi, dan hitung benar/salahnya
      // untuk menu riwayat kata.
      WordRepository.instance.recordResult(q.text, correct: ok);
    }
    if (!ok && q.kind == ReadKind.single) {
      // Huruf yang tertukar dicatat untuk "Often mixed up".
      for (final k in allKana) {
        if (k.type == q.letters.first.type && k.romaji == option) {
          _repo.recordConfusion(q.letters.first, k);
          break;
        }
      }
    }
    // Suara baru diputar setelah menjawab, supaya tidak membocorkan jawaban.
    if (AppSettings.instance.autoPlay) _hear(q);
    await _save();
  }

  /// Satu huruf: rekaman huruf. Kata dengan rekaman utuh: rekaman kata.
  /// Selain itu (rangkaian huruf, kata tanpa rekaman): huruf dibunyikan berurutan.
  void _hear(ReadQuestion q) {
    final audio = KanaAudioService.instance;
    if (q.kind == ReadKind.single) {
      audio.playCycle(q.letters.first);
    } else if (q.hasWholeWordAudio) {
      audio.playWordCycle(q.word!);
    } else {
      audio.playKanaSequence(q.letters, key: q.text);
    }
  }

  void _next() {
    KanaAudioService.instance.stopSequence();
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

  String _prompt(ReadQuestion q) => switch (q.kind) {
        ReadKind.word => 'How do you read this word?',
        ReadKind.chunk => 'How do you read these letters?',
        ReadKind.single => 'What is the romaji of this letter?',
      };

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
                title: 'Reading · ${_index + 1} / ${_questions.length}',
                progress: (_index + 1) / _questions.length,
                leadingIcon: Icons.close,
                leadingLabel: 'Dismiss',
                onLeading: () => Navigator.pop(context),
                trailing: IconButton(
                  tooltip: 'Play sound',
                  icon: const Icon(Icons.volume_up_outlined, size: 20),
                  onPressed: _answered ? () => _hear(q) : null,
                ),
              ),
              // Soal + pilihan di tengah-atas layar (zona jempol), jauh dari
              // Next. Umpan balik muncul di bawah pilihan.
              Expanded(
                child: ChoiceStage(
                  prompt: Text(
                    _prompt(q),
                    textAlign: TextAlign.center,
                    style: AppText.section.copyWith(
                      fontSize: 21,
                      height: 1.25,
                      letterSpacing: -0.3,
                    ),
                  ),
                  card: PromptPanel(
                    height: ChoiceStage.cardHeight(context),
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: KanaCharacter(q.text, size: 72),
                      ),
                    ),
                  ),
                  choices: _grid(q),
                  feedback: _feedback(q),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_answered)
                PrimaryButton(
                  label: last ? 'Finish' : 'Next',
                  trailing: Icons.arrow_forward,
                  onPressed: _next,
                )
              else
                const SizedBox(height: 52),
            ],
          ),
        ),
      ),
    );
  }

  Widget _grid(ReadQuestion q) {
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
        textSize: 26,
        minHeight: ChoiceStage.optionHeight(context, large: true),
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

  Widget _feedback(ReadQuestion q) {
    if (!_answered) return const SizedBox.shrink();
    final ok = _picked == q.answer;
    final meaning = q.word?.meaning ?? '';
    final showMeaning =
        q.word != null && AppSettings.instance.showMeaning && meaning.isNotEmpty;
    return Column(
      children: [
        if (!ok) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.clay,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('Not quite.', style: AppText.body),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (showMeaning) ...[
          Text(
            meaning,
            textAlign: TextAlign.center,
            style: AppText.section.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            q.answer,
            textAlign: TextAlign.center,
            style: AppText.body.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.muted,
            ),
          ),
        ] else ...[
          Text(
            q.answer,
            textAlign: TextAlign.center,
            style: AppText.section.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
        if (q.word != null && q.word!.level.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              vocabLevelLabel(q.word!.level),
              textAlign: TextAlign.center,
              style: AppText.muted,
            ),
          ),
        TextButton.icon(
          onPressed: () => _hear(q),
          icon: const Icon(Icons.volume_up_outlined, size: 20),
          label: const Text('Hear it again'),
        ),
      ],
    );
  }
}
