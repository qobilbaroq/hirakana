import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/kana_character.dart';
import '../../core/widgets/pill_choice.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/repositories/word_repository.dart';
import '../../data/seed/word_data.dart';
import '../learn/session_controller.dart';
import 'word_audio.dart';

enum WordHistoryFilter { all, struggling, fresh, mastered }

extension WordHistoryFilterX on WordHistoryFilter {
  String get label => switch (this) {
        WordHistoryFilter.all => 'All',
        WordHistoryFilter.struggling => 'Often wrong',
        WordHistoryFilter.fresh => 'New',
        WordHistoryFilter.mastered => 'Mastered',
      };

  bool matches(WordRecord r) => switch (this) {
        WordHistoryFilter.all => true,
        WordHistoryFilter.struggling => r.isStruggling,
        WordHistoryFilter.fresh => r.isNew,
        WordHistoryFilter.mastered => r.isMastered,
      };
}

/// Menyaring dan mengurutkan riwayat. "Often wrong" diurutkan dari yang paling
/// sering salah; filter lain mengikuti urutan terbaru dulu.
List<WordRecord> applyHistoryFilter(
    List<WordRecord> all, WordHistoryFilter filter) {
  final list = all.where(filter.matches).toList();
  if (filter == WordHistoryFilter.struggling) {
    list.sort((a, b) {
      final byWrong = b.wrongCount.compareTo(a.wrongCount);
      return byWrong != 0 ? byWrong : b.lastAt.compareTo(a.lastAt);
    });
  }
  return list;
}

/// Riwayat kata yang pernah muncul di latihan baca dan tebak arti. Bisa
/// disaring, diketuk untuk melihat arti dan suaranya, dan diulang lagi.
class WordHistoryScreen extends StatefulWidget {
  const WordHistoryScreen({super.key});

  @override
  State<WordHistoryScreen> createState() => _WordHistoryScreenState();
}

class _WordHistoryScreenState extends State<WordHistoryScreen> {
  /// Batas kata dalam satu sesi ulangan dari riwayat.
  static const _maxReview = 30;

  List<WordRecord> _all = const [];
  bool _loaded = false;
  WordHistoryFilter _filter = WordHistoryFilter.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final records = await WordRepository.instance.history();
    if (!mounted) return;
    setState(() {
      _all = records;
      _loaded = true;
    });
  }

  void _practice(String route, List<WordRecord> shown) {
    final texts = [for (final r in shown.take(_maxReview)) r.word.text];
    Navigator.pushNamed(
      context,
      route,
      arguments: SessionArgs(type: 'mixed', onlyTexts: texts),
    ).then((_) => _load());
  }

  void _showDetail(WordRecord r) {
    final w = r.word;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.paper,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KanaCharacter(w.text, size: 48),
            const SizedBox(height: AppSpacing.xs),
            Text(w.reading, style: AppText.section),
            const SizedBox(height: AppSpacing.xs),
            Text('Meaning: ${w.meaning}', style: AppText.body),
            if (w.level.isNotEmpty || w.category.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  [
                    if (w.level.isNotEmpty) vocabLevelLabel(w.level),
                    if (w.category.isNotEmpty) w.category,
                  ].join(' · '),
                  style: AppText.muted,
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Seen ${r.seenCount}×  ·  Correct ${r.correctCount}  ·  Wrong ${r.wrongCount}',
              style: AppText.muted,
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Hear it',
              kind: ButtonKind.secondary,
              trailing: Icons.volume_up_outlined,
              onPressed: () => playWordSound(w),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shown = applyHistoryFilter(_all, _filter);
    return Scaffold(
      appBar: AppBar(title: const Text('Word history')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : _all.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      'No words yet. Words that appear in Reading practice '
                      'and Meaning practice will be recorded here.',
                      textAlign: TextAlign.center,
                      style: AppText.muted,
                    ),
                  ),
                )
              : SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: PillChoiceWrap(
                            children: [
                              for (final f in WordHistoryFilter.values)
                                PillChoice(
                                  label: f.label,
                                  selected: _filter == f,
                                  onTap: () =>
                                      setState(() => _filter = f),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.md,
                            AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${shown.length} of ${_all.length} words',
                            style: AppText.muted,
                          ),
                        ),
                      ),
                      Expanded(
                        child: shown.isEmpty
                            ? Center(
                                child: Text('No words in this filter.',
                                    style: AppText.muted),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md),
                                itemCount: shown.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: AppSpacing.sm),
                                itemBuilder: (_, i) => _WordTile(
                                  record: shown[i],
                                  onTap: () => _showDetail(shown[i]),
                                ),
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            Expanded(
                              child: PrimaryButton(
                                label: 'Reading',
                                kind: ButtonKind.secondary,
                                onPressed: shown.isEmpty
                                    ? null
                                    : () => _practice(AppRouter.words, shown),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: PrimaryButton(
                                label: 'Meaning',
                                kind: ButtonKind.sage,
                                onPressed: shown.isEmpty
                                    ? null
                                    : () =>
                                        _practice(AppRouter.meaning, shown),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _WordTile extends StatelessWidget {
  const _WordTile({required this.record, required this.onTap});

  final WordRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final w = record.word;
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: KanaCharacter(w.text, size: 26),
              ),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(w.meaning, style: AppText.body),
                    Text(w.reading, style: AppText.muted),
                  ],
                ),
              ),
              Text(
                '${record.correctCount}✓  ${record.wrongCount}✗',
                style: AppText.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
