import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
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
                  onSelected: (_) => setState(() => _type = t.$1),
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
            title: 'Read words',
            subtitle: 'Real words made from your chosen letters.',
            onTap: () => launchSession(context,
                mode: 'words', args: SessionArgs(type: _type)),
          ),
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
