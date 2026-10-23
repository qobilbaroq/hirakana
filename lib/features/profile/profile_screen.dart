import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../core/settings/app_settings.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/kana_character.dart';
import '../../core/widgets/pill_button.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/progress_bar.dart';
import '../../core/widgets/screen_header.dart';
import '../../data/models/kana.dart';
import '../../data/repositories/kana_repository.dart';
import '../../data/seed/kana_data.dart';
import '../../data/seed/word_data.dart';
import '../home/home_controller.dart';
import '../learn/quiz_question.dart';
import '../learn/session_controller.dart';
import '../learn/session_launcher.dart';
import '../progress/progress_controller.dart';

/// Ringkasan belajar: streak, goal harian, milestone, total, dan sesi terakhir.
/// Menggabungkan isi Home dan Progress lama dalam satu layar.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _home = HomeController();
  final _progress = ProgressController();
  late final Listenable _listenable = Listenable.merge([_home, _progress]);
  int? _wordTotal;

  @override
  void initState() {
    super.initState();
    _loadWordTotal();
  }

  Future<void> _loadWordTotal() async {
    try {
      final words = await WordBank.instance.load();
      if (mounted) setState(() => _wordTotal = words.length);
    } catch (_) {}
  }

  @override
  void dispose() {
    _home.dispose();
    _progress.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Future.wait([_home.load(), _progress.load()]);
  }

  void _continue() {
    final h = _home.stats;
    if (h == null) return;
    final mode = h.hasStudied ? h.lastMode : 'flashcard';
    launchSession(context, mode: mode, args: SessionArgs(type: h.lastType));
  }

  void _startFlashcards() {
    launchSession(context,
        mode: 'flashcard', args: const SessionArgs(type: 'hiragana'));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: _listenable,
        builder: (context, _) {
          final s = _progress.stats;
          final h = _home.stats;
          if (s == null || h == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final hiraDone = _masteredIn(hiraganaList, s.levels);
          final kataDone = _masteredIn(katakanaList, s.levels);
          final goalMinutes = AppSettings.instance.goalMinutes;
          final goalSeconds = goalMinutes * 60;
          final goalRatio =
              goalSeconds <= 0 ? 0.0 : h.todaySeconds / goalSeconds;
          final wordTotal = _wordTotal ?? 0;

          return RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.ink,
            backgroundColor: AppColors.white,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                  20, 12, 20, AppSpacing.navClearance),
              children: [
                ScreenHeader(
                  title: 'Profile',
                  subtitle: 'Small steps, kept together.',
                  trailing: _RoundIconButton(
                    icon: Icons.settings_outlined,
                    tooltip: 'Settings',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRouter.settings),
                  ),
                  bottomGap: AppSpacing.md,
                ),
                _StreakCard(stats: s, dayNumber: h.dayNumber),
                const SizedBox(height: 12),
                _GoalCard(
                  todaySeconds: h.todaySeconds,
                  goalMinutes: goalMinutes,
                  ratio: goalRatio,
                  onContinue: _continue,
                ),
                const SizedBox(height: AppSpacing.lg),
                _Milestones(knownCount: s.knownCount),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: _BigStat(
                          value: '${s.knownCount}',
                          label: 'Kana known',
                          caption: 'of ${s.totalCount}',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _BigStat(
                          value: '${s.wordsMet}',
                          label: 'Words met',
                          caption: 'in word practice',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ProgressCard(
                        title: 'Hiragana',
                        done: hiraDone,
                        total: hiraganaList.length,
                        onTap: () => widget.onOpenTab(0),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ProgressCard(
                        title: 'Katakana',
                        done: kataDone,
                        total: katakanaList.length,
                        onTap: () => widget.onOpenTab(0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _ProgressCard(
                        title: 'Kana known',
                        done: s.knownCount,
                        total: s.totalCount,
                        onTap: () => widget.onOpenTab(0),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ProgressCard(
                        title: 'Words met',
                        done: s.wordsMet,
                        total: wordTotal,
                        onTap: () => widget.onOpenTab(2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _ReviewCard(stats: s),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: Text('Recent sessions', style: AppText.section),
                    ),
                    PillButton(
                      label: 'Practice',
                      onTap: () => widget.onOpenTab(1),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (s.recent.isEmpty)
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('No sessions yet.', style: AppText.bodyStrong),
                        const SizedBox(height: 4),
                        Text(
                          'One short round is enough to start.',
                          style: AppText.muted,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        PrimaryButton(
                          label: 'Start flashcards',
                          onPressed: _startFlashcards,
                          trailing: Icons.arrow_forward,
                        ),
                      ],
                    ),
                  )
                else
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    child: Column(
                      children: [
                        for (final r in s.recent)
                          _RecentRow(
                            mode: r.mode,
                            type: r.kanaType,
                            date: r.startedAt,
                            seconds: r.durationSeconds,
                            correct: r.correct,
                            cards: r.cards,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  int _masteredIn(List<Kana> list, Map<String, int> levels) =>
      list.where((k) => (levels[k.id] ?? 0) >= 3).length;
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.stats, required this.dayNumber});

  final ProgressStats stats;
  final int dayNumber;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = [
      for (var i = 6; i >= 0; i--)
        DateTime(today.year, today.month, today.day)
            .subtract(Duration(days: i)),
    ];
    final values = stats.last7DaysSeconds;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daily streak', style: AppText.cardTitle),
                    const SizedBox(height: 3),
                    Text(
                      'Current ${stats.currentStreak} days · Longest ${stats.longestStreak} days',
                      style: AppText.caption,
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.cardRaised,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text('Day $dayNumber', style: AppText.caption),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < days.length; i++)
                Expanded(
                  child: _DayDot(
                    date: days[i],
                    seconds: values.length > i ? values[i] : 0,
                    isToday: i == days.length - 1,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            stats.currentStreak > 0
                ? 'Keep the chain going with one short session.'
                : 'One session today starts the chain.',
            style: AppText.caption,
          ),
        ],
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({
    required this.date,
    required this.seconds,
    required this.isToday,
  });

  final DateTime date;
  final int seconds;
  final bool isToday;

  static const _initials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final active = seconds > 0;
    final fg = active ? AppColors.onActive : AppColors.muted;
    return Semantics(
      label:
          '${weekdayName(date)}: ${active ? 'studied' : 'no session'}',
      excludeSemantics: true,
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? AppColors.active : Colors.transparent,
              border: Border.all(
                color: isToday ? AppColors.active : AppColors.line,
                width: isToday ? 1.4 : 0.9,
              ),
            ),
            child: Text(
              _initials[date.weekday - 1],
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${date.day}',
            style: TextStyle(
              fontSize: 9.5,
              color: isToday ? AppColors.ink : AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.todaySeconds,
    required this.goalMinutes,
    required this.ratio,
    required this.onContinue,
  });

  final int todaySeconds;
  final int goalMinutes;
  final double ratio;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final minutes = toMinutes(todaySeconds);
    final pct = (ratio.clamp(0.0, 1.0) * 100).round();
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.today_outlined, size: 19, color: AppColors.muted),
              const SizedBox(width: 8),
              Expanded(child: Text("Today's goal", style: AppText.cardTitle)),
              Text(
                '$minutes / $goalMinutes min',
                style: AppText.caption.copyWith(color: AppColors.ink),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ProgressBar(value: ratio, height: 6),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('$pct%', style: AppText.caption.copyWith(color: AppColors.ink)),
              const Spacer(),
              PillButton(
                icon: Icons.play_arrow_rounded,
                label: 'Continue',
                onTap: onContinue,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Milestones extends StatelessWidget {
  const _Milestones({required this.knownCount});

  final int knownCount;

  static const _milestones = [
    (5, 'あ'),
    (25, 'か'),
    (50, 'な'),
    (100, 'ん'),
  ];

  @override
  Widget build(BuildContext context) {
    final unlocked =
        _milestones.where((m) => knownCount >= m.$1).length;
    final nextIndex = _milestones.indexWhere((m) => knownCount < m.$1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Milestones', style: AppText.section)),
            Text('$unlocked / ${_milestones.length}', style: AppText.caption),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            for (var i = 0; i < _milestones.length; i++)
              Expanded(
                child: _Milestone(
                  glyph: _milestones[i].$2,
                  threshold: _milestones[i].$1,
                  unlocked: knownCount >= _milestones[i].$1,
                  next: i == nextIndex,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Milestone extends StatelessWidget {
  const _Milestone({
    required this.glyph,
    required this.threshold,
    required this.unlocked,
    required this.next,
  });

  final String glyph;
  final int threshold;
  final bool unlocked;
  final bool next;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$threshold kana milestone, ${unlocked ? 'reached' : 'locked'}',
      excludeSemantics: true,
      child: Column(
        children: [
          SizedBox(
            width: 56,
            height: 62,
            child: CustomPaint(
              painter: _HexPainter(
                fill: unlocked
                    ? AppColors.cardRaised
                    : Colors.transparent,
                stroke: unlocked
                    ? AppColors.sage
                    : next
                        ? AppColors.ink
                        : AppColors.line,
                strokeWidth: next && !unlocked ? 1.5 : 1,
              ),
              child: Center(
                child: KanaCharacter(
                  glyph,
                  size: 23,
                  color: unlocked
                      ? AppColors.ink
                      : next
                          ? AppColors.ink
                          : AppColors.muted.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '$threshold kana',
            style: TextStyle(
              fontSize: 10.5,
              color: unlocked ? AppColors.ink : AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _HexPainter extends CustomPainter {
  const _HexPainter({
    required this.fill,
    required this.stroke,
    required this.strokeWidth,
  });

  final Color fill;
  final Color stroke;
  final double strokeWidth;

  Path _path(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w / 2, 1)
      ..lineTo(w - 1, h * 0.25)
      ..lineTo(w - 1, h * 0.75)
      ..lineTo(w / 2, h - 1)
      ..lineTo(1, h * 0.75)
      ..lineTo(1, h * 0.25)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _path(size);
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _HexPainter oldDelegate) =>
      oldDelegate.fill != fill ||
      oldDelegate.stroke != stroke ||
      oldDelegate.strokeWidth != strokeWidth;
}

class _BigStat extends StatelessWidget {
  const _BigStat({
    required this.value,
    required this.label,
    required this.caption,
  });

  final String value;
  final String label;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 30,
            height: 1,
            letterSpacing: -0.8,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: AppText.bodyStrong.copyWith(fontSize: 14)),
        const SizedBox(height: 1),
        Text(caption, style: AppText.caption),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.title,
    required this.done,
    required this.total,
    required this.onTap,
  });

  final String title;
  final int done;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ratio = total <= 0 ? 0.0 : (done / total).clamp(0.0, 1.0);
    final pct = (ratio * 100).round();
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.bodyStrong.copyWith(fontSize: 15)),
          const SizedBox(height: 11),
          ProgressBar(value: ratio, height: 5),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                total <= 0 ? '$done' : '$done / $total',
                style: AppText.caption,
              ),
              const Spacer(),
              if (total > 0)
                Text(
                  '$pct%',
                  style: AppText.caption.copyWith(color: AppColors.ink),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.stats});

  final ProgressStats stats;

  @override
  Widget build(BuildContext context) {
    final weak = stats.weak;
    final confusions = stats.confusions;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Needs another look', style: AppText.cardTitle),
          const SizedBox(height: 4),
          Text(
            weak.isEmpty && confusions.isEmpty
                ? 'Characters you mix up will show up here.'
                : 'A few characters are due for another pass.',
            style: AppText.caption,
          ),
          if (weak.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final k in weak.take(8))
                  Container(
                    width: 46,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.cardRaised,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: KanaCharacter(k.character,
                        size: k.character.length > 1 ? 18 : 22),
                  ),
              ],
            ),
          ],
          if (confusions.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (final c in confusions.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    _PairChip(c.a.character),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.swap_horiz,
                          size: 16, color: AppColors.muted),
                    ),
                    _PairChip(c.b.character),
                    const Spacer(),
                    Text('${c.count}×', style: AppText.caption),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            PrimaryButton(
              label: 'Practice look-alikes',
              kind: ButtonKind.secondary,
              onPressed: () => launchSession(
                context,
                mode: 'quiz',
                args: const SessionArgs(
                    type: 'mixed', quizKind: QuizKind.lookalike),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PairChip extends StatelessWidget {
  const _PairChip(this.glyph);
  final String glyph;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.cardRaised,
        borderRadius: BorderRadius.circular(10),
      ),
      child: KanaCharacter(glyph, size: glyph.length > 1 ? 15 : 19),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({
    required this.mode,
    required this.type,
    required this.date,
    required this.seconds,
    required this.correct,
    required this.cards,
  });

  final String mode;
  final String type;
  final DateTime date;
  final int seconds;
  final int correct;
  final int cards;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.cardRaised,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_modeIcon(mode), size: 18, color: AppColors.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_modeLabel(mode)} · $type',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodyStrong.copyWith(fontSize: 13.5),
                ),
                const SizedBox(height: 1),
                Text(
                  '${shortDate(date)} · ${formatDuration(seconds)}',
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            cards > 0 ? '$correct/$cards' : '—',
            style: AppText.caption.copyWith(color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.card,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 20, color: AppColors.ink),
          ),
        ),
      ),
    );
  }
}

String _modeLabel(String mode) => switch (mode) {
      'build_romaji' => 'Build romaji',
      'build_kana' => 'Build kana',
      '' => 'Session',
      _ => '${mode[0].toUpperCase()}${mode.substring(1)}',
    };

IconData _modeIcon(String mode) => switch (mode) {
      'flashcard' => Icons.style_outlined,
      'quiz' => Icons.quiz_outlined,
      'writing' => Icons.draw_outlined,
      'words' => Icons.menu_book_outlined,
      'meaning' => Icons.translate,
      'build_romaji' || 'build_kana' => Icons.extension_outlined,
      _ => Icons.history,
    };
