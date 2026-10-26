import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/kana_character.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/utils/motion.dart';

/// Apa yang harus dilakukan setelah onboarding ditutup.
enum OnboardingResult { start, chooseLetters, skip }

/// Perkenalan 3 layar, hanya tampil sekali untuk pengguna baru:
/// 1) apa yang akan dipelajari, 2) level awal, 3) langkah pertama.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pageCount = 3;

  final _controller = PageController();
  int _page = 0;
  bool _beginner = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLast => _page == _pageCount - 1;

  void _next() {
    if (_isLast) {
      Navigator.pop(
        context,
        _beginner ? OnboardingResult.start : OnboardingResult.chooseLetters,
      );
      return;
    }
    _controller.nextPage(
      duration: motionDuration(context, const Duration(milliseconds: 260)),
      curve: Curves.easeOutCubic,
    );
  }

  void _skip() => Navigator.pop(context, OnboardingResult.skip);

  String get _buttonLabel {
    if (!_isLast) return 'Next';
    return _beginner ? 'Start Lesson 1' : 'Choose my letters';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            children: [
              SizedBox(
                height: 44,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _isLast
                      ? const SizedBox.shrink()
                      : TextButton(
                          onPressed: _skip,
                          child: Text(
                            'Skip',
                            style: AppText.muted.copyWith(
                              color: AppColors.onGradientMuted,
                            ),
                          ),
                        ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    const _IntroPage(),
                    _LevelPage(
                      beginner: _beginner,
                      onChanged: (v) => setState(() => _beginner = v),
                    ),
                    _FirstStepPage(beginner: _beginner),
                  ],
                ),
              ),
              _Dots(count: _pageCount, index: _page),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: _buttonLabel,
                onPressed: _next,
                trailing: Icons.arrow_forward,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageFrame extends StatelessWidget {
  const _PageFrame({
    required this.hero,
    required this.title,
    required this.body,
    this.extra,
  });

  final Widget hero;
  final String title;
  final String body;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Center(child: hero),
          const SizedBox(height: AppSpacing.xl),
          Text(title, style: AppText.title),
          const SizedBox(height: AppSpacing.sm),
          Text(
            body,
            style: AppText.muted.copyWith(
              fontSize: 16,
              color: AppColors.onGradientMuted,
            ),
          ),
          if (extra != null) ...[
            const SizedBox(height: AppSpacing.lg),
            extra!,
          ],
        ],
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage();

  @override
  Widget build(BuildContext context) {
    return _PageFrame(
      hero: KanaCharacter('あ ア', size: 84),
      title: 'Learn Hiragana & Katakana',
      body: 'Start from zero. You learn five letters at a time, '
          'and you decide when to add more. No pressure.',
      extra: _TryKana(),
    );
  }
}

/// Latihan kecil di halaman pertama: ketuk huruf untuk melihat bunyinya.
/// Mengajar lewat interaksi, bukan hanya teks.
class _TryKana extends StatefulWidget {
  const _TryKana();

  @override
  State<_TryKana> createState() => _TryKanaState();
}

class _TryKanaState extends State<_TryKana> {
  static const _letters = [('あ', 'a'), ('い', 'i'), ('う', 'u')];
  int? _picked;

  @override
  Widget build(BuildContext context) {
    final picked = _picked;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < _letters.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.sm),
              Semantics(
                button: true,
                selected: picked == i,
                label: _letters[i].$1,
                excludeSemantics: true,
                child: Material(
                  color: picked == i ? AppColors.active : AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    onTap: () => setState(() => _picked = i),
                    child: Container(
                      width: 64,
                      constraints: const BoxConstraints(minHeight: 64),
                      alignment: Alignment.center,
                      child: KanaCharacter(
                        _letters[i].$1,
                        size: 30,
                        color: picked == i ? AppColors.onActive : null,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          picked == null
              ? 'Tap a letter to see how it sounds.'
              : 'Sounds like "${_letters[picked].$2}".',
          style: AppText.bodyStrong.copyWith(color: AppColors.onGradientMuted),
        ),
      ],
    );
  }
}

class _LevelPage extends StatelessWidget {
  const _LevelPage({required this.beginner, required this.onChanged});

  final bool beginner;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _PageFrame(
      hero: Icon(Icons.signpost_outlined, size: 72, color: AppColors.ink),
      title: 'Where are you now?',
      body: 'This only decides your first step. You can change it later.',
      extra: Column(
        children: [
          _LevelOption(
            title: 'Complete beginner',
            subtitle: "I don't know any kana yet.",
            selected: beginner,
            onTap: () => onChanged(true),
          ),
          const SizedBox(height: AppSpacing.sm),
          _LevelOption(
            title: 'I know some already',
            subtitle: 'I will pick the letters I want to practice.',
            selected: !beginner,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _LevelOption extends StatelessWidget {
  const _LevelOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: selected
            ? BorderSide(color: AppColors.ink, width: 1.2)
            : BorderSide.none,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.bodyStrong),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppText.caption),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 22,
              color: selected ? AppColors.ink : AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _FirstStepPage extends StatelessWidget {
  const _FirstStepPage({required this.beginner});

  final bool beginner;

  @override
  Widget build(BuildContext context) {
    if (beginner) {
      return _PageFrame(
        hero: KanaCharacter('あ い う え お', size: 40),
        title: 'Your first lesson',
        body: 'Five vowels: a, i, u, e, o. See each letter, hear it, '
            'try to recall the sound, then reveal the answer.',
      );
    }
    return _PageFrame(
      hero: Icon(Icons.tune, size: 72, color: AppColors.ink),
      title: 'Pick your letters',
      body: 'Choose the letters you want to study. '
          'You can add or remove letters anytime from the Kana tab.',
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Page ${index + 1} of $count',
      excludeSemantics: true,
      child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: motionDuration(context, const Duration(milliseconds: 200)),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 20 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == index
                  ? AppColors.ink
                  // Dot tidak aktif >= 3:1 terhadap latar (dulu ~1,8:1).
                  : AppColors.onGradientMuted.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
      ],
      ),
    );
  }
}
