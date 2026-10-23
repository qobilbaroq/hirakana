import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../core/audio/kana_audio_service.dart';
import '../../core/settings/app_settings.dart';
import '../../core/widgets/kana_character.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/session_header.dart';
import '../../data/models/kana.dart';
import '../../data/repositories/kana_repository.dart';
import '../../data/repositories/word_repository.dart';
import '../../data/seed/kana_data.dart';
import '../../data/seed/word_data.dart';
import '../learn/session_controller.dart';
import 'build_questions.dart';
import 'word_audio.dart';

/// Susun Kata: lihat arti dan soal, lalu susun jawabannya dari potongan.
///
/// - [BuildDirection.toRomaji]: tampil kata Jepang, susun romajinya.
/// - [BuildDirection.toKana]: tampil romaji, susun kananya.
///
/// Potongan yang tersedia = potongan benar + pengecoh dari huruf aktif.
/// Jumlah kotak jawaban sama dengan jumlah potongan benar.
class BuildWordScreen extends StatefulWidget {
  const BuildWordScreen({
    super.key,
    required this.args,
    required this.direction,
    this.questions,
  });

  final SessionArgs args;
  final BuildDirection direction;

  /// Soal khusus untuk tes tata letak; null = buat sesi seperti biasa.
  @visibleForTesting
  final List<BuildQuestion>? questions;

  @override
  State<BuildWordScreen> createState() => _BuildWordScreenState();
}

class _BuildWordScreenState extends State<BuildWordScreen> {
  final _repo = KanaRepository.instance;
  final _clock = Stopwatch();

  final List<BuildQuestion> _questions = [];
  bool _loaded = false;
  int _index = 0;
  int _correct = 0;
  int _answeredCount = 0;
  bool _answered = false;
  bool _lastOk = false;
  final List<int> _picked = []; // id potongan yang sudah dipilih, berurutan
  int? _sessionId;
  bool _finished = false;

  bool get _toKana => widget.direction == BuildDirection.toKana;
  String get _mode => _toKana ? 'build_kana' : 'build_romaji';

  static final Map<String, Kana> _byChar = {
    for (final k in allKana) k.character: k,
  };

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
    final injected = widget.questions;
    if (injected != null) {
      _questions.addAll(injected);
    } else {
      _questions.addAll(await createBuildSession(
        direction: widget.direction,
        type: widget.args.type,
        size: min(AppSettings.instance.sessionSize, buildSessionSize),
        vocabLevel: widget.args.vocabLevel,
      ));
    }
    if (_questions.isNotEmpty) {
      _sessionId = await _repo.startSession(_mode, widget.args.type);
      _clock.start();
    }
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

  String _labelOf(BuildQuestion q, int tileId) =>
      q.tiles.firstWhere((t) => t.id == tileId).label;

  void _pick(BuildQuestion q, int tileId) {
    if (_answered) return;
    if (_picked.length >= q.slotCount || _picked.contains(tileId)) return;
    setState(() => _picked.add(tileId));
  }

  void _unpick(int slot) {
    if (_answered || slot >= _picked.length) return;
    setState(() => _picked.removeAt(slot));
  }

  Future<void> _check() async {
    final q = _questions[_index];
    if (_answered || _picked.length != q.slotCount) return;
    final labels = [for (final id in _picked) _labelOf(q, id)];
    final ok = q.isCorrect(labels);
    setState(() {
      _answered = true;
      _lastOk = ok;
      _answeredCount++;
      if (ok) _correct++;
    });
    WordRepository.instance.recordResult(q.word.text, correct: ok);
    if (!ok && _toKana) {
      // Huruf yang tertukar dicatat untuk "Often mixed up" (maksimal 2 per soal).
      var recorded = 0;
      for (var i = 0; i < labels.length && recorded < 2; i++) {
        if (labels[i] == q.answerTiles[i]) continue;
        final target = _byChar[q.answerTiles[i]];
        final picked = _byChar[labels[i]];
        if (target != null && picked != null) {
          _repo.recordConfusion(target, picked);
          recorded++;
        }
      }
    }
    // Suara baru diputar setelah menjawab, supaya tidak membocorkan jawaban.
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
          mode: _mode,
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
      _lastOk = false;
      _picked.clear();
    });
  }

  Widget _label(String text, {Color? color, double? kanaSize}) {
    if (_toKana) {
      return KanaCharacter(text, size: kanaSize ?? 28, color: color);
    }
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.ink,
      ),
    );
  }

  Widget _slot(BuildQuestion q, int i) {
    final filled = i < _picked.length;
    final text = filled ? _labelOf(q, _picked[i]) : '';
    var border = Colors.transparent;
    var width = 1.5;
    if (_answered) {
      final match = _lastOk || (filled && text == q.answerTiles[i]);
      border = match ? AppColors.sage : AppColors.clay;
      width = 2;
    }
    return GestureDetector(
      onTap: filled && !_answered ? () => _unpick(i) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(color: border, width: width),
        ),
        child: filled
            ? FittedBox(fit: BoxFit.scaleDown, child: _label(text))
            : const SizedBox.shrink(),
      ),
    );
  }

  /// Kotak jawaban menyusut sedikit untuk kata panjang supaya tetap satu baris.
  /// Di layar sempit, batas 40 px membuatnya turun ke baris kedua.
  Widget _slotGrid(BuildQuestion q) {
    const gap = AppSpacing.xs;
    return LayoutBuilder(
      builder: (context, constraints) {
        final raw =
            (constraints.maxWidth - gap * (q.slotCount - 1)) / q.slotCount;
        final size = min(48.0, max(40.0, raw));
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < q.slotCount; i++)
              SizedBox(width: size, height: size, child: _slot(q, i)),
          ],
        );
      },
    );
  }

  Widget _tile(BuildQuestion q, BuildTile t) {
    final used = _picked.contains(t.id);
    return Opacity(
      opacity: used ? 0.25 : 1,
      child: Material(
        color: AppColors.cardRaised,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.button),
          onTap: used || _answered ? null : () => _pick(q, t.id),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: FittedBox(fit: BoxFit.scaleDown, child: _label(t.label)),
          ),
        ),
      ),
    );
  }

  /// Potongan disusun sebagai grid kecil dua baris supaya layar tidak perlu
  /// di-scroll. Jumlah kolom mengikuti jumlah potongan (8 -> 4, 10 -> 5,
  /// 12 -> 6), dan ukuran kotak dibatasi 56 px.
  Widget _tileGrid(BuildQuestion q) {
    const gap = AppSpacing.xs;
    final columns = (q.tiles.length / 2).ceil();
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(
          56.0,
          (constraints.maxWidth - gap * (columns - 1)) / columns,
        );
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final t in q.tiles)
              SizedBox(width: size, height: size, child: _tile(q, t)),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_questions.isEmpty) return _empty();

    final q = _questions[_index];
    final last = _index + 1 >= _questions.length;
    final full = _picked.length == q.slotCount;
    final meaning = q.word.meaning;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              SessionHeader(
                title: 'Build · ${_index + 1} / ${_questions.length}',
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
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Column(
                    children: [
                      Text(
                        _toKana
                            ? 'Build this word in kana'
                            : 'Build the romaji of this word',
                        textAlign: TextAlign.center,
                        style: AppText.muted,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (meaning.isNotEmpty)
                        Text(
                          meaning,
                          textAlign: TextAlign.center,
                          style: AppText.section.copyWith(fontSize: 20),
                        ),
                      if (q.word.category.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Text(q.word.category,
                              textAlign: TextAlign.center,
                              style: AppText.muted),
                        ),
                      const SizedBox(height: AppSpacing.md),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: _toKana
                            ? Text(
                                q.prompt,
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              )
                            : KanaCharacter(q.prompt, size: 56),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _slotGrid(q),
                      const SizedBox(height: AppSpacing.sm),
                      if (_answered)
                        _feedback(q)
                      else ...[
                        _tileGrid(q),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Tap a tile to fill · tap a slot to remove',
                          textAlign: TextAlign.center,
                          style: AppText.muted.copyWith(fontSize: 12),
                        ),
                      ],
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
                PrimaryButton(
                  label: 'Check',
                  onPressed: full ? _check : null,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _feedback(BuildQuestion q) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _lastOk ? Icons.check_circle : Icons.info_outline,
              color: _lastOk ? AppColors.sage : AppColors.clay,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(_lastOk ? "Nice, that's right." : 'Not quite.',
                  style: AppText.body),
            ),
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

  Widget _empty() {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            'No words can be built from your chosen letters yet. '
            'Add a few more letters, or try another word filter.',
            textAlign: TextAlign.center,
            style: AppText.body,
          ),
        ),
      ),
    );
  }
}
