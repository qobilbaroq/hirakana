
import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../core/audio/kana_audio_service.dart';
import '../../core/audio/system_tts_service.dart';
import '../../core/settings/app_settings.dart';
import '../../core/widgets/answer_option.dart';
import '../../core/widgets/kana_character.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/session_header.dart';
import '../../data/repositories/kana_repository.dart';
import '../../data/repositories/word_repository.dart';
import '../../data/seed/kana_data.dart';
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
      // Catat supaya kata ini tidak cepat muncul lagi.
      WordRepository.instance.markSeen([q.text]);
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

  /// Rantai suara: satu huruf pakai rekaman huruf, kata berrekaman pakai rekaman
  /// kata, sisanya dibacakan TTS sistem sebagai satu ucapan, dan hanya kalau
  /// TTS tidak tersedia barulah huruf dibunyikan berurutan.
  ///
  /// Memanggil [_warnMissingJapaneseVoice] tepat satu kali per sesi kalau voice
  /// Jepang tidak terpasang di perangkat.
  Future<void> _hear(ReadQuestion q) async {
    final ok = await KanaAudioService.instance.playRead(
      letters: q.letters,
      word: q.word,
      text: q.text,
      key: q.text,
      // Jenis soalnya, bukan jumlah kana: kata seperti ツー cuma punya satu
      // kana dan harus tetap dibacakan utuh.
      isSingleLetter: q.kind == ReadKind.single,
    );
    if (!ok) _warnMissingJapaneseVoice();
  }

  /// Snackbar sekali per sesi: memberi tahu cara memasang voice Jepang.
  bool _warnedVoice = false;

  void _warnMissingJapaneseVoice() {
    if (_warnedVoice) return;
    // Pemanggilan ini datang dari _hear() setelah await (TTS + pemutaran).
    // Kalau pengguna sudah keluar dari sesi, context-nya tidak hidup lagi.
    if (!mounted) return;
    final tts = SystemTtsService.instance;
    // Jangan pesan kalau ini cuma soal satu huruf: tidak butuh TTS sama sekali.
    if (!tts.japaneseVoiceChecked) return;
    if (tts.japaneseVoiceAvailable) return;
    _warnedVoice = true;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(
        content: Text(
          'Suara Jepang belum terpasang di HP. '
          'Pasang di Pengaturan > Text-to-speech.',
        ),
      ));
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
                title: 'READING · ${_index + 1} / ${_questions.length}',
                progress: _index / _questions.length,
                leadingIcon: Icons.arrow_back,
                onLeading: () => Navigator.pop(context),
                trailing: IconButton(
                  tooltip: 'Play sound',
                  icon: const Icon(Icons.volume_up_outlined),
                  onPressed: _answered ? () => _hear(q) : null,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  child: Column(
                    children: [
                      Text(
                        _prompt(q),
                        textAlign: TextAlign.center,
                        style: AppText.section,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: KanaCharacter(q.text, size: 72),
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

  Widget _feedback(ReadQuestion q) {
    if (!_answered) return const SizedBox(height: 24);
    final ok = _picked == q.answer;
    // Arti muncul setelah menjawab, benar ATAU salah: kalau hanya muncul saat
    // benar, pengguna merasa artinya hilang saat masih belajar.
    final word = q.word;
    final showMeaning =
        AppSettings.instance.showMeaning && (word?.hasAnyMeaning ?? false);
    final meaningIsIndo = (word?.meaning ?? '').isNotEmpty;
    final meaning = word?.displayMeaning ?? '';
    final kanji = word?.kanji ?? '';
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
          '${q.text}  ·  ${q.answer}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Noto Sans JP',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        if (kanji.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            kanji,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Noto Sans JP',
              fontSize: 14,
              color: AppColors.muted,
            ),
          ),
        ],
        if (showMeaning) ...[
          const SizedBox(height: AppSpacing.xs),
          // Arti Indonesia; kalau kosong pakai arti Inggris berlabel EN.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!meaningIsIndo)
                Padding(
                  padding: const EdgeInsets.only(top: 3, right: 4),
                  child: Text('EN', style: AppText.overline),
                ),
              Flexible(
                child: Text(
                  meaning,
                  textAlign: TextAlign.center,
                  style: AppText.muted,
                ),
              ),
            ],
          ),
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
