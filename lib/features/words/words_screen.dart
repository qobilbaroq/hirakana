import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/mode_card.dart';
import '../../core/widgets/pill_choice.dart';
import '../../core/widgets/screen_header.dart';
import '../../data/seed/word_data.dart';
import '../learn/session_controller.dart';
import '../learn/session_launcher.dart';

/// Latihan kata: baca, arti, susun romaji/kana, dan riwayat kata.
class WordsScreen extends StatefulWidget {
  const WordsScreen({super.key});

  @override
  State<WordsScreen> createState() => _WordsScreenState();
}

class _WordsScreenState extends State<WordsScreen> {
  String _type = 'hiragana';
  String? _vocabLevel; // null = semua kata

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, AppSpacing.navClearance),
        children: [
          const ScreenHeader(
            title: 'Words',
            subtitle: 'Read, understand, and build real words.',
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
          Text('Vocabulary', style: AppText.section),
          const SizedBox(height: AppSpacing.sm),
          PillChoiceWrap(
            children: [
              for (final l in <(String?, String)>[
                (null, 'All words'),
                for (final v in vocabLevels) (v.$1, v.$2),
              ])
                PillChoice(
                  label: l.$2,
                  selected: _vocabLevel == l.$1,
                  onTap: () => setState(() => _vocabLevel = l.$1),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'N5–N4 and N3 words appear once all their letters are in your set.',
            style: AppText.caption,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Practice', style: AppText.section),
          const SizedBox(height: AppSpacing.sm),
          ModeCard(
            icon: Icons.menu_book_outlined,
            title: 'Reading practice',
            subtitle: 'Words and letter groups. Pick the romaji.',
            onTap: () => launchSession(context,
                mode: 'words',
                args: SessionArgs(type: _type, vocabLevel: _vocabLevel)),
          ),
          const SizedBox(height: 10),
          ModeCard(
            icon: Icons.translate,
            title: 'Meaning practice',
            subtitle: 'See a word. Pick its meaning.',
            onTap: () => launchSession(context,
                mode: 'meaning',
                args: SessionArgs(type: _type, vocabLevel: _vocabLevel)),
          ),
          const SizedBox(height: 10),
          ModeCard(
            icon: Icons.spellcheck,
            title: 'Build the word: romaji',
            subtitle: 'See a Japanese word. Build its romaji.',
            onTap: () => launchSession(context,
                mode: 'build_romaji',
                args: SessionArgs(type: _type, vocabLevel: _vocabLevel)),
          ),
          const SizedBox(height: 10),
          ModeCard(
            icon: Icons.extension_outlined,
            title: 'Build the word: kana',
            subtitle: 'See the romaji. Build the word in kana.',
            onTap: () => launchSession(context,
                mode: 'build_kana',
                args: SessionArgs(type: _type, vocabLevel: _vocabLevel)),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Review', style: AppText.section),
          const SizedBox(height: AppSpacing.sm),
          ModeCard(
            icon: Icons.history,
            title: 'Word history',
            subtitle: 'Words you have met. Review the ones you miss.',
            onTap: () => Navigator.pushNamed(context, AppRouter.wordHistory),
          ),
        ],
      ),
    );
  }
}
