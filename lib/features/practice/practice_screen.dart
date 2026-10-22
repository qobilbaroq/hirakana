import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../data/seed/word_data.dart';
import '../learn/quiz_question.dart';
import '../learn/session_controller.dart';
import '../learn/session_launcher.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  String _type = 'hiragana';
  String? _vocabLevel; // null = semua kata

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const SizedBox(height: AppSpacing.sm),
          Text('Practice', style: AppText.title),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Writing, words, and recognition. One small drill at a time.',
            style: AppText.muted,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Script', style: AppText.overline),
          const SizedBox(height: AppSpacing.xs),
          _ScriptPicker(
            value: _type,
            onChanged: (value) => setState(() => _type = value),
          ),
          const SizedBox(height: AppSpacing.lg),

          const _SectionTitle('Writing'),
          const SizedBox(height: AppSpacing.sm),
          _PracticeGroup(
            children: [
              _PracticeRow(
                icon: Icons.draw_outlined,
                title: 'Trace the character',
                subtitle: 'Write with your finger, follow the guide.',
                onTap: () => launchSession(context,
                    mode: 'writing', args: SessionArgs(type: _type)),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),
          const _SectionTitle('Words'),
          const SizedBox(height: AppSpacing.sm),
          _VocabPicker(
            value: _vocabLevel,
            onChanged: (value) => setState(() => _vocabLevel = value),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'N5–N4 and N3 words appear once all their letters are in your set.',
            style: AppText.muted.copyWith(fontSize: 12),
          ),
          const SizedBox(height: AppSpacing.sm),
          _PracticeGroup(
            children: [
              _PracticeRow(
                icon: Icons.menu_book_outlined,
                title: 'Reading practice',
                subtitle: 'Words and letter groups. Pick the romaji.',
                onTap: () => launchSession(context,
                    mode: 'words',
                    args: SessionArgs(type: _type, vocabLevel: _vocabLevel)),
              ),
              _PracticeRow(
                icon: Icons.translate,
                title: 'Meaning practice',
                subtitle: 'See a word. Pick its meaning.',
                onTap: () => launchSession(context,
                    mode: 'meaning',
                    args: SessionArgs(type: _type, vocabLevel: _vocabLevel)),
              ),
              _PracticeRow(
                icon: Icons.spellcheck,
                title: 'Build the word: romaji',
                subtitle: 'See a Japanese word. Build its romaji.',
                onTap: () => launchSession(context,
                    mode: 'build_romaji',
                    args: SessionArgs(type: _type, vocabLevel: _vocabLevel)),
              ),
              _PracticeRow(
                icon: Icons.extension_outlined,
                title: 'Build the word: kana',
                subtitle: 'See the romaji. Build the word in kana.',
                onTap: () => launchSession(context,
                    mode: 'build_kana',
                    args: SessionArgs(type: _type, vocabLevel: _vocabLevel)),
              ),
              _PracticeRow(
                icon: Icons.history,
                title: 'Word history',
                subtitle: 'Words you have met. Review the ones you miss.',
                onTap: () =>
                    Navigator.pushNamed(context, AppRouter.wordHistory),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),
          const _SectionTitle('Recognition'),
          const SizedBox(height: AppSpacing.sm),
          _PracticeGroup(
            children: [
              for (final kind in QuizKind.values)
                _PracticeRow(
                  icon: switch (kind) {
                    QuizKind.kanaToSound => Icons.abc,
                    QuizKind.soundToKana => Icons.hearing,
                    QuizKind.lookalike => Icons.compare_arrows,
                  },
                  title: kind.title,
                  subtitle: kind.subtitle,
                  onTap: () => launchSession(
                    context,
                    mode: 'quiz',
                    args: SessionArgs(type: _type, quizKind: kind),
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),
          Text(
            'Stroke order data: KanjiVG (CC BY-SA 3.0), kanjivg.tagaini.net\n'
            'Letter voice: veardk/just-gojuon (MIT)\n'
            'Word voice: tohoku-f01, Tohoku Univ. ICN Lab (CC BY 4.0)',
            style: TextStyle(fontSize: 11, color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _ScriptPicker extends StatelessWidget {
  const _ScriptPicker({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      children: [
        for (final t in const [
          ('hiragana', 'Hiragana'),
          ('katakana', 'Katakana'),
          ('mixed', 'Mixed'),
        ])
          ChoiceChip(
            label: Text(t.$2),
            selected: value == t.$1,
            selectedColor: AppColors.sage.withValues(alpha: 0.35),
            backgroundColor: AppColors.sand,
            side: BorderSide.none,
            onSelected: (_) => onChanged(t.$1),
          ),
      ],
    );
  }
}

class _VocabPicker extends StatelessWidget {
  const _VocabPicker({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      children: [
        for (final l in <(String?, String)>[
          (null, 'All words'),
          for (final v in vocabLevels) (v.$1, v.$2),
        ])
          ChoiceChip(
            label: Text(l.$2),
            selected: value == l.$1,
            selectedColor: AppColors.sage.withValues(alpha: 0.35),
            backgroundColor: AppColors.sand,
            side: BorderSide.none,
            onSelected: (_) => onChanged(l.$1),
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppText.section);
  }
}

/// Kartu berisi beberapa baris menu, dipisah garis tipis supaya tidak perlu
/// satu kartu per item.
class _PracticeGroup extends StatelessWidget {
  const _PracticeGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 1, color: AppColors.line),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _PracticeRow extends StatelessWidget {
  const _PracticeRow({
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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + AppSpacing.xs,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.sage.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.sage),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppText.muted.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.muted.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}
