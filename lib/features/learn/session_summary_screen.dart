import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/kana_character.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/repositories/kana_repository.dart';
import 'session_controller.dart';

class SessionSummaryScreen extends StatefulWidget {
  const SessionSummaryScreen({super.key, required this.result});

  final SessionResult result;

  @override
  State<SessionSummaryScreen> createState() => _SessionSummaryScreenState();
}

class _SessionSummaryScreenState extends State<SessionSummaryScreen> {
  String? _addedLabel;

  SessionResult get result => widget.result;

  void _studyAgain() {
    final route = switch (result.mode) {
      'quiz' => AppRouter.quiz,
      'words' => AppRouter.words,
      'meaning' => AppRouter.meaning,
      'writing' => AppRouter.writing,
      _ => AppRouter.flashcard,
    };
    Navigator.pushReplacementNamed(context, route, arguments: result.args);
  }

  Future<void> _addMore() async {
    final added = await KanaRepository.instance.addNextLetters(result.args.type);
    if (!mounted) return;
    setState(() {
      _addedLabel = added.isEmpty
          ? 'All letters are already in your set.'
          : 'Added: ${added.map((k) => k.character).join(' ')}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWriting = result.mode == 'writing';
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.lg),
                      Text('SESSION COMPLETE', style: AppText.overline),
                      const SizedBox(height: AppSpacing.xs),
                      Text('Well done.', style: AppText.title),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        result.needsReview.isEmpty
                            ? 'Nice and steady. Go again, or add more letters when you feel ready.'
                            : "We'll bring a few of these back soon. Going again is a good idea.",
                        style: AppText.muted,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          _stat(result.mode == 'words' || result.mode == 'meaning' ? 'Words' : 'Characters', '${result.cards}'),
                          const SizedBox(width: AppSpacing.sm),
                          if (!isWriting) ...[
                            _stat('Correct',
                                '${result.correct} / ${result.answered}'),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          _stat('Time', formatDuration(result.seconds)),
                        ],
                      ),
                      if (result.needsReview.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.sand,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Needs another look',
                                  style: AppText.section),
                              const SizedBox(height: AppSpacing.sm),
                              Wrap(
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.sm,
                                children: [
                                  for (final k in result.needsReview)
                                    Container(
                                      width: 64,
                                      height: 56,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: AppColors.white,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: KanaCharacter(k.character,
                                          size: k.character.length > 1 ? 22 : 28),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (_addedLabel != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Center(
                      child: Text(
                        _addedLabel!,
                        style: AppText.muted.copyWith(
                          fontFamily: 'Noto Sans JP',
                        ),
                      ),
                    ),
                )
              else
                Center(
                  child: TextButton(
                    onPressed: _addMore,
                    child: const Text('Ready for more? Add the next 5 letters'),
                  ),
                ),
              PrimaryButton(label: 'Study again', onPressed: _studyAgain),
              const SizedBox(height: AppSpacing.sm),
              PrimaryButton(
                label: 'Done',
                kind: ButtonKind.secondary,
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppText.muted),
            const SizedBox(height: AppSpacing.xs),
            Text(value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
