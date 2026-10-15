import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/kana_character.dart';
import '../../data/seed/kana_data.dart';
import 'session_controller.dart';
import 'session_launcher.dart';

/// Pilih cara belajar untuk satu jenis kana (dipakai Home dan Learn).
Future<void> showStudyModeSheet(
  BuildContext context, {
  required String type, // hiragana | katakana | mixed
  required String title,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppText.title),
            const SizedBox(height: AppSpacing.xs),
            Text('How do you want to study?', style: AppText.muted),
            const SizedBox(height: AppSpacing.md),
            _ModeTile(
              icon: Icons.style_outlined,
              title: 'Flashcards',
              subtitle: 'Recall each character, then reveal.',
              onTap: () {
                Navigator.pop(sheetContext);
                launchSession(context,
                    mode: 'flashcard', args: SessionArgs(type: type));
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _ModeTile(
              icon: Icons.quiz_outlined,
              title: 'Quick quiz',
              subtitle: 'Only asks about letters you have already seen.',
              onTap: () {
                Navigator.pop(sheetContext);
                launchSession(context,
                    mode: 'quiz', args: SessionArgs(type: type));
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _ModeTile(
              icon: Icons.tune,
              title: 'Choose letters',
              subtitle: 'Pick exactly which letters to study.',
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.pushNamed(context, AppRouter.chooseLetters,
                    arguments: type);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
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

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const SizedBox(height: AppSpacing.sm),
          Text('Learn', style: AppText.title),
          const SizedBox(height: AppSpacing.xs),
          Text('Pick a set and study at your own pace.',
              style: AppText.muted),
          const SizedBox(height: AppSpacing.lg),
          _LearnCard(
            glyph: 'あ',
            title: 'Hiragana',
            subtitle: '${hiraganaList.length} kana · basic, dakuten, combos',
            onTap: () => showStudyModeSheet(context,
                type: 'hiragana', title: 'Hiragana'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _LearnCard(
            glyph: 'ア',
            title: 'Katakana',
            subtitle: '${katakanaList.length} kana · basic, dakuten, combos',
            onTap: () => showStudyModeSheet(context,
                type: 'katakana', title: 'Katakana'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _LearnCard(
            glyph: 'あア',
            title: 'Mixed Review',
            subtitle: 'Both scripts together',
            onTap: () => showStudyModeSheet(context,
                type: 'mixed', title: 'Mixed Review'),
          ),
        ],
      ),
    );
  }
}

class _LearnCard extends StatelessWidget {
  const _LearnCard({
    required this.glyph,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String glyph;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.sand,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                child: KanaCharacter(glyph, size: 32, weight: FontWeight.w600),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.section),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppText.muted),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
