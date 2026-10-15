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
import '../../data/seed/kana_data.dart';
import 'session_controller.dart';

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key, required this.args});

  final SessionArgs args;

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen>
    with SingleTickerProviderStateMixin {
  late final SessionController _session;
  late final AnimationController _flip;
  final _shown = Stopwatch();
  bool _loaded = false;
  bool _revealed = false;
  bool _busy = false;
  bool _audioWarned = false;

  @override
  void initState() {
    super.initState();
    _session = SessionController(mode: 'flashcard', args: widget.args);
    _flip = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _session.start().then((_) {
      if (!mounted) return;
      setState(() => _loaded = true);
      _shown.start();
    });
  }

  @override
  void dispose() {
    _flip.dispose();
    _session.flush();
    super.dispose();
  }

  Future<void> _speak() async {
    final kana = _session.current;
    if (kana == null) return;
    final ok = await KanaAudioService.instance.playCycle(kana);
    // Peringatan cukup sekali per sesi, dan hilang sendiri.
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

  void _reveal() {
    if (_revealed) return;
    // Hormati pengaturan "kurangi animasi" dari perangkat.
    _flip.duration = MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 220);
    setState(() => _revealed = true);
    _flip.forward();
    if (AppSettings.instance.autoPlay) _speak();
  }

  Future<void> _rate(bool ok) async {
    if (!_revealed || _busy) return;
    _busy = true;
    final fast = _shown.elapsedMilliseconds < 1500;
    await _session.answer(ok, fast: ok && fast);
    if (!mounted) return;
    if (_session.finished) {
      final result = _session.finish();
      Navigator.pushReplacementNamed(context, AppRouter.summary,
          arguments: result);
      return;
    }
    KanaAudioService.instance.resetCycle();
    _flip.value = 0;
    setState(() {
      _revealed = false;
      _busy = false;
    });
    _shown
      ..reset()
      ..start();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final kana = _session.current!;
    final typeLabel =
        widget.args.type == 'mixed' ? kana.typeLabel : widget.args.type;
    final pos = _session.position.toString().padLeft(2, '0');
    final total = _session.total.toString().padLeft(2, '0');
    final again = _session.retryPending > 0 ? ' · +${_session.retryPending} again' : '';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              SessionHeader(
                title: '${typeLabel.toUpperCase()} · $pos / $total$again',
                progress: _session.progress,
                onLeading: () => Navigator.pop(context),
                trailing: IconButton(
                  tooltip: 'Play sound',
                  icon: const Icon(Icons.volume_up_outlined),
                  onPressed: _speak,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _revealed ? _speak : _reveal,
                  child: _buildCard(kana),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _revealed
                    ? 'Tap the card or the speaker to hear it again. The 3rd time is slower.'
                    : 'Take your time. Recall before revealing.',
                textAlign: TextAlign.center,
                style: AppText.muted,
              ),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: 'Reveal answer',
                onPressed: _revealed ? null : _reveal,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: 'Again',
                      kind: ButtonKind.secondary,
                      onPressed: _revealed ? () => _rate(false) : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Got it',
                      kind: ButtonKind.sage,
                      onPressed: _revealed ? () => _rate(true) : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Kana kana) {
    final example = exampleFor(kana);

    final front = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_session.currentIsRetry) ...[
          Text('SECOND LOOK', style: AppText.overline),
          const SizedBox(height: AppSpacing.sm),
        ],
        Text('What sound does this make?', style: AppText.muted),
        const SizedBox(height: AppSpacing.md),
        KanaCharacter(kana.character, size: kana.character.length > 1 ? 88 : 120),
        const SizedBox(height: AppSpacing.md),
        Text('Tap to reveal', style: AppText.muted),
      ],
    );

    final back = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        KanaCharacter(kana.character, size: kana.character.length > 1 ? 56 : 72),
        const SizedBox(height: AppSpacing.sm),
        Text(
          kana.romaji,
          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w600),
        ),
        if (example != null) ...[
          const SizedBox(height: AppSpacing.lg),
          KanaCharacter(example.$1, size: 24),
          const SizedBox(height: AppSpacing.xs),
          Text('${example.$2} — ${example.$3}', style: AppText.muted),
        ],
      ],
    );

    return AnimatedBuilder(
      animation: _flip,
      builder: (context, _) {
        final angle = _flip.value * pi;
        final showBack = angle > pi / 2;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(showBack ? angle - pi : angle),
          child: Container(
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: SingleChildScrollView(
              child: Semantics(
                label: showBack
                    ? '${kana.character}, romaji ${kana.romaji}'
                    : 'Character ${kana.character}. Tap to reveal.',
                child: showBack ? back : front,
              ),
            ),
          ),
        );
      },
    );
  }
}
