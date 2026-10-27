import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/mode_card.dart';
import '../../core/widgets/pill_choice.dart';
import '../../core/widgets/screen_header.dart';
import '../learn/quiz_question.dart';
import '../learn/session_controller.dart';
import '../learn/session_launcher.dart';

/// Latihan kana: kartu, kuis, menulis, dan memilih huruf.
/// Latihan kata punya tab sendiri (Words).
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
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, AppSpacing.navClearance),
        children: [
          const ScreenHeader(
            title: 'Practice',
            subtitle: 'Short drills. One small set at a time.',
            bottomGap: AppSpacing.md,
          ),
          Text(
            'Script',
            style: AppText.caption.copyWith(color: AppColors.onGradientMuted),
          ),
          const SizedBox(height: AppSpacing.sm),
          PillChoiceWrap(
            children: [
              for (final t in const [
                ('hiragana', 'Hiragana'),
                ('katakana', 'Katakana'),
                ('mixed', 'Mixed'),
              ])
                PillChoice(
                  label: t.$2,
                  selected: _type == t.$1,
                  onTap: () => setState(() => _type = t.$1),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Kana', style: AppText.section),
          const SizedBox(height: AppSpacing.sm),
          ModeCard(
            icon: Icons.style_outlined,
            title: 'Flashcards',
            subtitle: 'Recall each character, then reveal.',
            onTap: () => launchSession(context,
                mode: 'flashcard', args: SessionArgs(type: _type)),
          ),
          const SizedBox(height: 10),
          ModeCard(
            icon: Icons.quiz_outlined,
            title: 'Quick quiz',
            subtitle: 'Only asks about letters you have already seen.',
            onTap: () => launchSession(context,
                mode: 'quiz', args: SessionArgs(type: _type)),
          ),
          const SizedBox(height: 10),
          Text('Writing', style: AppText.section),
          const SizedBox(height: AppSpacing.sm),
          ModeCard(
            icon: Icons.draw_outlined,
            title: 'Trace the character',
            subtitle: 'Write with your finger, follow the guide.',
            onTap: () => launchSession(context,
                mode: 'writing', args: SessionArgs(type: _type)),
          ),
          const SizedBox(height: 10),
          ModeCard(
            icon: Icons.tune,
            title: 'Choose letters',
            subtitle: 'Pick exactly which letters to study.',
            onTap: () => Navigator.pushNamed(context, AppRouter.chooseLetters,
                arguments: _type),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Recognition', style: AppText.section),
          const SizedBox(height: AppSpacing.sm),
          for (final kind in QuizKind.values) ...[
            ModeCard(
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
            if (kind != QuizKind.values.last) const SizedBox(height: 10),
          ],
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Stroke order data: KanjiVG (CC BY-SA 3.0), kanjivg.tagaini.net\n'
            'Letter voice: veardk/just-gojuon (MIT)\n'
            'Word voice: tohoku-f01, Tohoku Univ. ICN Lab (CC BY 4.0)',
            style: TextStyle(fontSize: 11, height: 1.5, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
