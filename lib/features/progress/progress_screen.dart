import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/kana_character.dart';
import '../../core/widgets/kana_group_row.dart';
import '../../core/widgets/mastery_indicator.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/progress_bar.dart';
import '../../data/seed/kana_data.dart';
import '../learn/quiz_question.dart';
import '../learn/session_controller.dart';
import '../learn/session_launcher.dart';
import 'progress_controller.dart';

/// Label ramah untuk mode sesi di daftar "Recent sessions".
String _modeLabel(String mode) => switch (mode) {
  'build_romaji' => 'Build romaji',
  'build_kana' => 'Build kana',
  '' => 'Session',
  _ => '${mode[0].toUpperCase()}${mode.substring(1)}',
};

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final _controller = ProgressController();
  bool _showHiragana = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final s = _controller.stats;
          if (s == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = _showHiragana ? hiraganaList : katakanaList;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const SizedBox(height: AppSpacing.sm),
              Text('Your progress', style: AppText.title),
              const SizedBox(height: AppSpacing.xs),
              Text('Small steps add up.', style: AppText.muted),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Known kana',
                      value: '${s.knownCount} / ${s.totalCount}',
                      caption: 'Hiragana & Katakana',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _StatCard(
                      label: 'Study time',
                      value: formatDuration(s.weekSeconds),
                      caption: 'This week',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _Panel(
                color: AppColors.card,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kana mastery', style: AppText.section),
                    const SizedBox(height: AppSpacing.md),
                    _MasteryRow('Hiragana', s.hiraganaMastery),
                    const SizedBox(height: AppSpacing.md),
                    _MasteryRow('Katakana', s.katakanaMastery),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _Panel(
                color: AppColors.sand,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Needs another look', style: AppText.section),
                    const SizedBox(height: AppSpacing.sm),
                    if (s.weak.isEmpty)
                      Text(
                        'Nothing here yet. Characters you mix up will show up here.',
                        style: AppText.muted,
                      )
                    else ...[
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final k in s.weak)
                            Container(
                              width: 64,
                              height: 52,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: KanaCharacter(k.character, size: 26),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Characters you mix up will appear more often.',
                        style: AppText.muted,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _Panel(
                color: AppColors.card,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Often mixed up', style: AppText.section),
                    const SizedBox(height: AppSpacing.sm),
                    if (s.confusions.isEmpty)
                      Text(
                        'Nothing yet. Pairs you swap in quizzes will show up here.',
                        style: AppText.muted,
                      )
                    else ...[
                      for (final c in s.confusions)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Row(
                            children: [
                              _PairChip(c.a.character),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                ),
                                child: Icon(
                                  Icons.swap_horiz,
                                  color: AppColors.muted,
                                ),
                              ),
                              _PairChip(c.b.character),
                              const Spacer(),
                              Text('${c.count}×', style: AppText.muted),
                            ],
                          ),
                        ),
                      const SizedBox(height: AppSpacing.xs),
                      PrimaryButton(
                        label: 'Practice look-alikes',
                        kind: ButtonKind.secondary,
                        onPressed: () => launchSession(
                          context,
                          mode: 'quiz',
                          args: const SessionArgs(
                            type: 'mixed',
                            quizKind: QuizKind.lookalike,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Text('All characters', style: AppText.section),
                  ),
                  SegmentedButton<bool>(
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    segments: const [
                      ButtonSegment(value: true, label: Text('あ')),
                      ButtonSegment(value: false, label: Text('ア')),
                    ],
                    selected: {_showHiragana},
                    onSelectionChanged: (v) =>
                        setState(() => _showHiragana = v.first),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              // Tabel gojuon selebar layar: tiap baris mengisi lebar penuh.
              for (final group in groupKana(list))
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: kanaGroupRow(
                    group,
                    (k) => Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          KanaCharacter(
                            k.character,
                            size: k.character.length > 1 ? 18 : 22,
                          ),
                          const SizedBox(height: 4),
                          MasteryIndicator(level: s.levels[k.id] ?? 0),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              Text('Recent sessions', style: AppText.section),
              const SizedBox(height: AppSpacing.sm),
              if (s.recent.isEmpty)
                Text('No sessions yet.', style: AppText.muted)
              else
                for (final r in s.recent)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _Panel(
                      color: AppColors.card,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_modeLabel(r.mode)} · ${r.kanaType}',
                                  style: AppText.body,
                                ),
                                Text(
                                  shortDate(r.startedAt),
                                  style: AppText.muted,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${r.cards} cards · ${formatDuration(r.durationSeconds)}',
                            style: AppText.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _PairChip extends StatelessWidget {
  const _PairChip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.sand,
        borderRadius: BorderRadius.circular(12),
      ),
      child: KanaCharacter(text, size: text.length > 1 ? 18 : 24),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: child,
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.caption,
  });

  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      color: AppColors.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.muted),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(caption, style: TextStyle(fontSize: 12, color: AppColors.sage)),
        ],
      ),
    );
  }
}

class _MasteryRow extends StatelessWidget {
  const _MasteryRow(this.label, this.value);

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppText.body),
            Text('${(value * 100).round()}%', style: AppText.muted),
          ],
        ),
        const SizedBox(height: 6),
        ProgressBar(value: value),
      ],
    );
  }
}
