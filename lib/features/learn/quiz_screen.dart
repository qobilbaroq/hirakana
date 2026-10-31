import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_fonts.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../core/audio/kana_audio_service.dart';
import '../../core/settings/app_settings.dart';
import '../../core/widgets/answer_option.dart';
import '../../core/widgets/choice_stage.dart';
import '../../core/widgets/kana_character.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/session_header.dart';
import '../../data/models/kana.dart';
import '../../data/repositories/kana_repository.dart';
import 'quiz_question.dart';
import 'session_controller.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.args});

  final SessionArgs args;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  // Kuis campuran: look-alike punya sesi sendiri, jadi tidak ikut diacak.
  static const _mixedKinds = [
    QuizKind.kanaToSound,
    QuizKind.soundToKana,
  ];

  final _rng = Random();
  final _shown = Stopwatch();
  late final SessionController _session;

  bool _loaded = false;
  QuizQuestion? _q;
  int _pos = 1;
  bool _answered = false;
  bool _audioWarned = false;
  bool _wasCorrect = false;
  String? _pickedId;
  // Riwayat tipe soal terakhir, supaya jenis yang sama tidak mendominasi.
  final _recentKinds = <QuizKind>[];
  // Jenis soal terakhir per huruf, supaya huruf yang muncul lagi di sesi yang
  // sama tidak ditanyakan dengan cara yang sama terus.
  final _lastKindByKana = <String, QuizKind>{};

  /// Type soal yang baru saja dipakai. Kalau [kind] sudah muncul
  /// [maxRepeat] kali berturut-turut, cari tipe lain yang belum dicapai.
  QuizKind _nextKind() {
    final forced = widget.args.quizKind;
    if (forced != null) return forced;
    const maxRepeat = 2;
    void run(QuizKind k) => _recentKinds.add(k);
    void trim() {
      while (_recentKinds.length > 3) {
        _recentKinds.removeAt(0);
      }
    }

    var kind = _mixedKinds[_rng.nextInt(_mixedKinds.length)];
    if (_recentKinds.where((k) => k == kind).length < maxRepeat) {
      run(kind);
      trim();
      return kind;
    }
    final ok = _mixedKinds
        .where((k) => _recentKinds.where((o) => o == k).length < maxRepeat)
        .toList();
    kind = ok.isEmpty ? _mixedKinds[_rng.nextInt(_mixedKinds.length)] : ok[_rng.nextInt(ok.length)];
    run(kind);
    trim();
    return kind;
  }

  @override
  void initState() {
    super.initState();
    // Tahan notifikasi Home/Progress selama kuis supaya Next tidak macet.
    KanaRepository.instance.holdNotifications();
    _session = SessionController(mode: 'quiz', args: widget.args);
    _session.start().then((_) {
      if (!mounted) return;
      if (_session.queue.isEmpty) {
        Navigator.pop(context);
        return;
      }
      _nextQuestion();
      setState(() => _loaded = true);
    });
  }

  @override
  void dispose() {
    _session.flush();
    KanaRepository.instance.releaseNotifications();
    super.dispose();
  }

  void _nextQuestion() {
    KanaAudioService.instance.resetCycle();
    final kana = _session.current!;
    var kind = _nextKind();
    // Huruf yang sama muncul lagi: pakai jenis soal yang berbeda kalau bisa.
    if (widget.args.quizKind == null && _lastKindByKana[kana.id] == kind) {
      kind = kind == QuizKind.kanaToSound
          ? QuizKind.soundToKana
          : QuizKind.kanaToSound;
    }
    if (_recentKinds.isNotEmpty) _recentKinds[_recentKinds.length - 1] = kind;
    _lastKindByKana[kana.id] = kind;
    final partners = _session.partners[kana.id] ?? const <Kana>[];
    try {
      _q = buildQuestion(kana, kind, _rng,
          pool: _session.activePool, partners: partners);
    } on StateError {
      // Jangan sampai layar macet: ulangi dengan pengecoh dari semua huruf.
      try {
        _q = buildQuestion(kana, kind, _rng, pool: null, partners: partners);
      } on StateError {
        // Pasangan tertukar yang rusak tidak boleh menghentikan kuis.
        _q = buildQuestion(kana, kind, _rng,
            pool: null, partners: const <Kana>[]);
      }
    }
    _pos = _session.position;
    _answered = false;
    _wasCorrect = false;
    _pickedId = null;
    _shown
      ..reset()
      ..start();
  }

  Future<void> _speak(Kana kana) async {
    final ok = await KanaAudioService.instance.playCycle(kana);
    if (!ok && mounted && !_audioWarned) {
      _audioWarned = true;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
          content: Text("Audio can't play right now. Tap the speaker to try again."),
          duration: Duration(seconds: 2),
        ));
    }
  }

  Future<void> _submit(bool ok, {String? pickedId}) async {
    if (_answered) return;
    final q = _q!;
    final fast = _shown.elapsedMilliseconds < 1500;
    setState(() {
      _answered = true;
      _wasCorrect = ok;
      _pickedId = pickedId;
    });
    if (!ok) {
      _recordConfusion(q, pickedId);
      if (AppSettings.instance.autoPlay) _speak(q.target); // salah: jawaban benar + audio
    }
    await _session.answer(ok, fast: ok && fast);
  }

  /// Catat huruf mana yang tertukar dengan jawaban benar (untuk fitur
  /// "Often mixed up" dan pengecoh kuis berikutnya).
  void _recordConfusion(QuizQuestion q, String? pickedId) {
    Kana? picked;
    if (pickedId != null) {
      for (final k in q.options) {
        if (k.id == pickedId) picked = k;
      }
    }
    if (picked != null) KanaRepository.instance.recordConfusion(q.target, picked);
  }

  void _next() {
    if (_session.finished) {
      final result = _session.finish();
      Navigator.pushReplacementNamed(context, AppRouter.summary,
          arguments: result);
      return;
    }
    setState(_nextQuestion);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final q = _q!;
    final total = _session.total.toString().padLeft(2, '0');
    final again = _session.retryPending > 0 ? ' · +${_session.retryPending} again' : '';
    final canPlay = _answered || q.audioBeforeAnswer;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              SessionHeader(
                title: 'Quick quiz · ${_pos.toString().padLeft(2, '0')} / $total$again',
                progress: _session.position / _session.total,
                leadingIcon: Icons.close,
                leadingLabel: 'Dismiss',
                onLeading: () => Navigator.pop(context),
                trailing: IconButton(
                  tooltip: 'Play sound',
                  icon: const Icon(Icons.volume_up_outlined, size: 20),
                  onPressed: canPlay ? () => _speak(q.target) : null,
                ),
              ),
              // Soal + pilihan dikelompokkan di tengah-atas layar (zona
              // jempol), jauh dari tombol Next di bawah. Umpan balik muncul
              // di bawah pilihan dengan ruang tetap, jadi pilihan tidak geser.
              Expanded(
                child: ChoiceStage(
                  prompt: Text(
                    q.prompt,
                    textAlign: TextAlign.center,
                    style: AppText.section.copyWith(
                      fontSize: 21,
                      height: 1.25,
                      letterSpacing: -0.3,
                    ),
                  ),
                  card: _PromptCard(
                    question: q,
                    height: ChoiceStage.cardHeight(context),
                  ),
                  choices: _choiceGrid(q, ChoiceStage.optionHeight(context)),
                  feedback: _feedback(q),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_answered)
                PrimaryButton(
                  label: _session.finished ? 'Finish' : 'Next',
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

  Widget _choiceGrid(QuizQuestion q, double optionHeight) {
    Widget tile(Kana k) {
      var state = OptionState.idle;
      if (_answered) {
        if (k.id == q.target.id) {
          state = OptionState.correct;
        } else if (k.id == _pickedId) {
          state = OptionState.wrong;
        } else {
          state = OptionState.dimmed;
        }
      }
      return AnswerOption(
        label: q.optionLabel(k),
        isKana: q.optionsAreKana,
        state: state,
        textSize: q.optionsAreKana ? 34 : 22,
        minHeight: optionHeight,
        onTap: _answered ? null : () => _submit(k.id == q.target.id, pickedId: k.id),
      );
    }

    final o = q.options;
    return Column(
      children: [
        Row(children: [
          Expanded(child: tile(o[0])),
          const SizedBox(width: 10),
          Expanded(child: tile(o[1])),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: tile(o[2])),
          const SizedBox(width: 10),
          Expanded(child: tile(o[3])),
        ]),
      ],
    );
  }

  Widget _feedback(QuizQuestion q) {
    if (!_answered) return const SizedBox.shrink();
    if (_wasCorrect) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: AppColors.sage, size: 20),
          SizedBox(width: AppSpacing.sm),
          Text('Nice, that\'s right.', style: AppText.body),
        ],
      );
    }
    return Column(
      children: [
        Text('Not quite — here\'s the answer:', style: AppText.muted),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${q.target.character}  ·  ${q.target.romaji}',
          style: TextStyle(
            fontFamily: AppFonts.kana,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.question, required this.height});

  final QuizQuestion question;
  final double height;

  @override
  Widget build(BuildContext context) {
    final kana = question.target.character;
    return Semantics(
      label: question.showKana ? kana : question.target.romaji,
      child: PromptPanel(
        height: height,
        child: question.showKana
            ? KanaCharacter(
                kana,
                size: kana.length > 1 ? 62 : 92,
                weight: FontWeight.w500,
              )
            : Text(
                question.target.romaji,
                style: TextStyle(
                  fontSize: 54,
                  height: 1,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -1.5,
                  color: AppColors.ink,
                ),
              ),
      ),
    );
  }
}
