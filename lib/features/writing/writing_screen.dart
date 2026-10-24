import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../core/settings/app_settings.dart';
import '../../core/widgets/kana_character.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/session_header.dart';
import '../../data/models/kana.dart';
import '../../data/repositories/kana_repository.dart';
import '../../data/seed/stroke_data.dart';
import '../learn/session_controller.dart';
import 'kana_tracing_canvas.dart';

class WritingScreen extends StatefulWidget {
  const WritingScreen({super.key, required this.args});

  final SessionArgs args;

  @override
  State<WritingScreen> createState() => _WritingScreenState();
}

class _WritingScreenState extends State<WritingScreen>
    with SingleTickerProviderStateMixin {
  final _repo = KanaRepository.instance;
  final _tracing = TracingController();
  final List<Kana> _queue = [];
  late final AnimationController _replay;
  bool _replayActive = false;

  bool _loaded = false;
  bool _comparing = false;
  bool _revealed = false;
  bool _closed = false;
  int _index = 0;
  int _seconds = 0;
  int? _sessionId;
  DateTime _lastTick = DateTime.now();

  @override
  void initState() {
    super.initState();
    _replay = AnimationController(vsync: this);
    _start();
  }

  Future<void> _start() async {
    await StrokeRepository.instance.load();
    final size = AppSettings.instance.sessionSize;
    _queue.addAll(await _repo.buildQueue(
      type: widget.args.type,
      size: size,
      fillToSize: size > AppSettings.minSessionSize,
    ));
    putKanaFirst(_queue, widget.args.firstKanaId);
    _sessionId = await _repo.startSession('writing', widget.args.type);
    _lastTick = DateTime.now();
    if (!mounted) return;
    setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _tracing.dispose();
    _replay.dispose();
    if (!_closed) _save();
    super.dispose();
  }

  void _tick() {
    final now = DateTime.now();
    _seconds += min(now.difference(_lastTick).inSeconds, 120);
    _lastTick = now;
  }

  Future<void> _save() async {
    final id = _sessionId;
    if (id == null) return;
    _tick();
    await _repo.updateSession(id,
        seconds: _seconds, cards: _comparing ? _index + 1 : _index, correct: 0);
  }

  Future<void> _next() async {
    await _save();
    if (_index + 1 >= _queue.length) {
      _closed = true;
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        AppRouter.summary,
        arguments: SessionResult(
          mode: 'writing',
          args: widget.args,
          cards: _queue.length,
          correct: 0,
          answered: 0,
          needsReview: const [],
          seconds: _seconds,
        ),
      );
      return;
    }
    _tracing.clear();
    _replay.value = 0;
    setState(() {
      _index++;
      _comparing = false;
      _revealed = false;
      _replayActive = false;
    });
  }

  /// Animasi urutan goresan yang benar.
  void _playReplay(Kana kana) {
    final paths = StrokeRepository.instance.pathsFor(kana.character);
    if (paths == null) return;
    final reduce = MediaQuery.of(context).disableAnimations;
    _replay.duration =
        reduce ? Duration.zero : Duration(milliseconds: max(900, paths.length * 650));
    setState(() => _replayActive = true);
    _replay.forward(from: 0).whenComplete(() async {
      await Future<void>.delayed(Duration(milliseconds: reduce ? 1200 : 500));
      if (mounted) setState(() => _replayActive = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final kana = _queue[_index];
    final last = _index + 1 >= _queue.length;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              SessionHeader(
                title: 'Writing · ${_index + 1} / ${_queue.length}',
                progress: (_index + 1) / _queue.length,
                leadingIcon: Icons.close,
                leadingLabel: 'Dismiss',
                onLeading: () => Navigator.pop(context),
                trailing: IconButton(
                  tooltip: 'Undo last stroke',
                  icon: const Icon(Icons.undo, size: 20),
                  onPressed: _comparing ? null : _tracing.undo,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Trace the character', style: AppText.caption),
              const SizedBox(height: 2),
              KanaCharacter(kana.character, size: 36),
              SizedBox(
                height: 26,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: _revealed
                        ? Text(
                            kana.romaji,
                            key: const ValueKey('romaji'),
                            style: AppText.section.copyWith(
                              fontSize: 18,
                              color: AppColors.sage,
                            ),
                          )
                        : Text(
                            'Guess the reading',
                            key: const ValueKey('guess'),
                            style: AppText.muted,
                          ),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _playReplay(kana),
                icon: const Icon(Icons.play_circle_outline, size: 20),
                label: const Text('Replay stroke order'),
              ),
              Expanded(
                child: KanaTracingCanvas(
                  character: kana.character,
                  strokes: StrokeRepository.instance.pathsFor(kana.character),
                  controller: _tracing,
                  comparing: _comparing,
                  replay: _replayActive ? _replay : null,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ListenableBuilder(
                listenable: _tracing,
                builder: (context, _) {
                  return Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          label: _comparing ? 'Try again' : 'Clear',
                          kind: ButtonKind.secondary,
                          onPressed: () {
                            _tracing.clear();
                            setState(() => _comparing = false);
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _comparing
                            ? PrimaryButton(
                                label: last ? 'Finish' : 'Next',
                                kind: ButtonKind.sage,
                                onPressed: _next,
                              )
                            : PrimaryButton(
                                label: 'Check',
                                kind: ButtonKind.sage,
                                onPressed: _tracing.isEmpty
                                    ? null
                                    : () => setState(() {
                                          _comparing = true;
                                          _revealed = true;
                                        }),
                              ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _comparing
                    ? 'Compare your strokes with the guide. Accuracy first, speed later.'
                    : 'Practice slowly. Accuracy first, speed later.',
                textAlign: TextAlign.center,
                style: AppText.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
