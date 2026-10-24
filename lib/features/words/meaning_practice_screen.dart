import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_fonts.dart';
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
import 'meaning_questions.dart';
import 'word_audio.dart';

/// Tebak arti: lihat kata, pilih arti Bahasa Indonesia yang benar. Suara baru
/// diputar setelah menjawab supaya cara bacanya tidak ikut membocorkan
/// jawaban. Hasilnya ikut dicatat ke riwayat kata.
class MeaningPracticeScreen extends StatefulWidget {
  const MeaningPracticeScreen({super.key, required this.args});

  final SessionArgs args;

  @override
  State<MeaningPracticeScreen> createState() => _MeaningPracticeScreenState();
}

class _MeaningPracticeScreenState extends State<MeaningPracticeScreen> {
  final _repo = KanaRepository.instance;
  final _clock = Stopwatch();

  final List<MeaningQuestion> _questions = [];
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
    _questions.addAll(await buildMeaningSession(
      type: widget.args.type,
      size: AppSettings.instance.sessionSize,
      vocabLevel: widget.args.vocabLevel,
      onlyTexts: widget.args.onlyTexts,
    ));
    if (!mounted) return;
    if (_questions.isEmpty) {
      Navigator.pop(context);
      return;
    }
    _sessionId = await _repo.startSession('meaning', widget.args.type);
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
    WordRepository.instance.recordResult(q.word.text, correct: ok);
    if (AppSettings.instance.autoPlay) playWordSound(q.word);
    await _save();
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
          mode: 'meaning',
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
                title: 'Meaning · ${_index + 1} / ${_questions.length}',
                progress: (_index + 1) / _questions.length,
                leadingIcon: Icons.close,
                leadingLabel: 'Dismiss',
                onLeading: () => Navigator.pop(context),
                trailing: IconButton(
                  tooltip: 'Play sound',
                  icon: const Icon(Icons.volume_up_outlined, size: 20),
                  onPressed: _answered ? () => playWordSound(q.word) : null,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  child: Column(
                    children: [
                      Text(
                        'What does this word mean?',
                        textAlign: TextAlign.center,
                        style: AppText.section.copyWith(
                          fontSize: 21,
                          height: 1.25,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm + 2),
                      Container(
                        width: double.infinity,
                        height: 128,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: KanaCharacter(q.word.text, size: 72),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _feedback(q),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _grid(q),
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

  Widget _grid(MeaningQuestion q) {
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
        textSize: 18,
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

  Widget _feedback(MeaningQuestion q) {
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
            Text(ok ? "Nice, that's right." : 'Not quite.',
                style: AppText.body),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${q.word.text}  ·  ${q.word.reading}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppFonts.kana,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text('Meaning: ${q.answer}',
            textAlign: TextAlign.center, style: AppText.body),
        if (q.word.level.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              vocabLevelLabel(q.word.level),
              textAlign: TextAlign.center,
              style: AppText.muted,
            ),
          ),
        TextButton.icon(
          onPressed: () => playWordSound(q.word),
          icon: const Icon(Icons.volume_up_outlined, size: 20),
          label: const Text('Hear it again'),
        ),
      ],
    );
  }
}
