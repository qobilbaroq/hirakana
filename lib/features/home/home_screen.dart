import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../core/settings/app_settings.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/progress_bar.dart';
import '../../data/seed/kana_data.dart';
import '../learn/learn_screen.dart';
import '../learn/session_controller.dart';
import '../learn/session_launcher.dart';
import 'home_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = HomeController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _message(double ratio) {
    if (ratio <= 0) return "Let's start small.";
    if (ratio < 0.5) return 'A small start counts.';
    if (ratio < 1) return "You're getting there. Keep it easy.";
    return "Goal reached. Keep going only if you feel like it.";
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: Listenable.merge([_controller, AppSettings.instance]),
        builder: (context, _) {
          final stats = _controller.stats;
          if (stats == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final minutes = toMinutes(stats.todaySeconds);
          final goal = AppSettings.instance.goalMinutes;
          final ratio = (stats.todaySeconds / 60) / goal;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${weekdayName(DateTime.now())} · DAY ${stats.dayNumber.toString().padLeft(2, '0')}',
                      style: AppText.overline,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Settings',
                    icon: Icon(Icons.settings_outlined, color: AppColors.muted),
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRouter.settings),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'おはよう!',
                style: TextStyle(
                  fontFamily: 'Noto Sans JP',
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text('A little Japanese, every day.', style: AppText.muted),
              const SizedBox(height: AppSpacing.lg),
              _DailyGoalCard(
                minutes: minutes,
                goal: goal,
                ratio: ratio,
                message: _message(ratio),
                onContinue: () => launchSession(
                  context,
                  mode: stats.lastMode == 'quiz' ? 'quiz' : 'flashcard',
                  args: SessionArgs(type: stats.lastType),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Choose your session', style: AppText.section),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _KanaCategoryCard(
                      glyph: 'あ',
                      title: 'Hiragana',
                      count: hiraganaList.length,
                      onTap: () => showStudyModeSheet(context,
                          type: 'hiragana', title: 'Hiragana'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _KanaCategoryCard(
                      glyph: 'ア',
                      title: 'Katakana',
                      count: katakanaList.length,
                      onTap: () => showStudyModeSheet(context,
                          type: 'katakana', title: 'Katakana'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _QuickReviewCard(
                onTap: () => launchSession(
                  context,
                  mode: 'flashcard',
                  args: const SessionArgs(type: 'mixed', quick: true),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DailyGoalCard extends StatelessWidget {
  const _DailyGoalCard({
    required this.minutes,
    required this.goal,
    required this.ratio,
    required this.message,
    required this.onContinue,
  });

  final int minutes;
  final int goal;
  final double ratio;
  final String message;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Today's goal", style: AppText.section),
              Text('$minutes / $goal min', style: AppText.muted),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ProgressBar(value: ratio),
          const SizedBox(height: AppSpacing.sm),
          Text(message, style: AppText.muted),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Continue learning',
            trailing: Icons.arrow_forward,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}

class _KanaCategoryCard extends StatelessWidget {
  const _KanaCategoryCard({
    required this.glyph,
    required this.title,
    required this.count,
    required this.onTap,
  });

  final String glyph;
  final String title;
  final int count;
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
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  glyph,
                  style: const TextStyle(
                    fontFamily: 'Noto Sans JP',
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(title, style: AppText.section),
              const SizedBox(height: 2),
              Text('$count kana', style: AppText.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickReviewCard extends StatelessWidget {
  const _QuickReviewCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.sand),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quick review', style: AppText.section),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      "Review the characters you're most likely to forget.",
                      style: AppText.muted,
                    ),
                  ],
                ),
              ),
              Icon(Icons.north_east, size: 18, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
