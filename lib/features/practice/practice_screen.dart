import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../data/repositories/word_repository.dart';
import '../learn/quiz_question.dart';
import '../learn/session_controller.dart';
import '../learn/session_launcher.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key, this.tabIndex});

  /// Dialirkan oleh MainShell. Halaman ini hidup terus di dalam IndexedStack,
  /// jadi initState hanya jalan sekali saat app dibuka. Tanpa sinyal ini,
  /// jumlah kata yang ditampilkan sudah basi begitu pengguna mengubah
  /// huruf aktif di Choose letters.
  final ValueListenable<int>? tabIndex;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  String _type = 'hiragana';

  /// Berapa kata yang bisa dipakai latihan baca untuk script aktif. Kalau
  /// sedikit, pengguna perlu menambah huruf supaya pool kata bertambah.
  int? _wordCount;

  /// Hitungan masih jalan; jangan mulai hitung kedua.
  Future<void>? _counting;

  @override
  void initState() {
    super.initState();
    widget.tabIndex?.addListener(_onTabChanged);
    _loadWordCount();
  }

  @override
  void didUpdateWidget(covariant PracticeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tabIndex != widget.tabIndex) {
      oldWidget.tabIndex?.removeListener(_onTabChanged);
      widget.tabIndex?.addListener(_onTabChanged);
    }
  }

  @override
  void dispose() {
    widget.tabIndex?.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (widget.tabIndex?.value == _practiceTabIndex) _loadWordCount();
  }

  /// Indeks tab Practice di MainShell.
  static const _practiceTabIndex = 2;

  Future<void> _loadWordCount() {
    final running = _counting;
    if (running != null) return running;
    return _counting = _countWords();
  }

  Future<void> _countWords() async {
    int? n;
    try {
      n = (await WordRepository.instance.available(_type)).length;
    } catch (_) {
      n = null;
    }
    _counting = null;
    if (mounted) setState(() => _wordCount = n);
  }

  /// Di bawah jumlah ini latihan baca jadi terlalu repetitive.
  static const _minComfortableWords = 20;

  void _setType(String t) {
    setState(() => _type = t);
    _loadWordCount();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const SizedBox(height: AppSpacing.sm),
          Text('Practice', style: AppText.title),
          const SizedBox(height: AppSpacing.xs),
          Text('Writing and recognition, one small drill at a time.',
              style: AppText.muted),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final t in const [
                ('hiragana', 'Hiragana'),
                ('katakana', 'Katakana'),
                ('mixed', 'Mixed'),
              ])
                ChoiceChip(
                  label: Text(t.$2),
                  selected: _type == t.$1,
                  selectedColor: AppColors.sage.withValues(alpha: 0.35),
                  backgroundColor: AppColors.sand,
                  side: BorderSide.none,
                  onSelected: (_) => _setType(t.$1),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Writing', style: AppText.section),
          const SizedBox(height: AppSpacing.sm),
          _PracticeTile(
            icon: Icons.draw_outlined,
            title: 'Trace the character',
            subtitle: 'Write with your finger, follow the guide.',
            onTap: () => launchSession(context,
                mode: 'writing', args: SessionArgs(type: _type)),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Words', style: AppText.section),
          const SizedBox(height: AppSpacing.sm),
          _PracticeTile(
            icon: Icons.menu_book_outlined,
            title: 'Reading practice',
            subtitle: 'Words and letter groups. Pick the romaji.',
            onTap: () => launchSession(context,
                mode: 'words', args: SessionArgs(type: _type)),
          ),
          if (_wordCount != null && _wordCount! < _minComfortableWords) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppColors.muted),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Tambah huruf untuk membuka lebih banyak kata.',
                    style: AppText.muted,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text('Recognition', style: AppText.section),
          const SizedBox(height: AppSpacing.sm),
          for (final kind in QuizKind.values) ...[
            _PracticeTile(
              icon: switch (kind) {
                QuizKind.kanaToRomaji => Icons.keyboard_outlined,
                QuizKind.lookalike => Icons.compare_arrows,
                _ => Icons.quiz_outlined,
              },
              title: kind.title,
              subtitle: kind.subtitle,
              onTap: () => launchSession(
                context,
                mode: 'quiz',
                args: SessionArgs(type: _type, quizKind: kind),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            'Stroke order data: KanjiVG (CC BY-SA 3.0), kanjivg.tagaini.net\nLetter voice: veardk/just-gojuon (MIT)\nWord voice: tohoku-f01, Tohoku Univ. ICN Lab (CC BY 4.0)',
            style: TextStyle(fontSize: 11, color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _PracticeTile extends StatelessWidget {
  const _PracticeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(icon, color: AppColors.sage),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.section),
                    Text(subtitle, style: AppText.muted),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
