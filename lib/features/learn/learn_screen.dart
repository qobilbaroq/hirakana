import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../core/audio/kana_audio_service.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/curved_nav_bar.dart';
import '../../core/widgets/curved_nav_geometry.dart';
import '../../core/widgets/kana_character.dart';
import '../../core/widgets/kana_group_row.dart';
import '../../core/widgets/mastery_indicator.dart';
import '../../core/widgets/mode_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/screen_header.dart';
import '../../data/models/kana.dart';
import '../../data/repositories/kana_repository.dart';
import '../../data/seed/kana_data.dart';
import '../progress/progress_controller.dart';
import 'session_controller.dart';
import 'session_launcher.dart';

/// Pilih cara belajar untuk satu jenis kana (dipakai Home, Kana, dan Practice).
Future<void> showStudyModeSheet(
  BuildContext context, {
  required String type, // hiragana | katakana | mixed
  required String title,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.large),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: _SheetHandle()),
              const SizedBox(height: AppSpacing.md),
              Text(title, style: AppText.title),
              const SizedBox(height: AppSpacing.xs),
              Text('How do you want to study?', style: AppText.muted),
              const SizedBox(height: AppSpacing.lg),
              ModeCard(
                icon: Icons.style_outlined,
                title: 'Flashcards',
                subtitle: 'Recall each character, then reveal.',
                onTap: () {
                  Navigator.pop(sheetContext);
                  launchSession(
                    context,
                    mode: 'flashcard',
                    args: SessionArgs(type: type),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              ModeCard(
                icon: Icons.quiz_outlined,
                title: 'Quick quiz',
                subtitle: 'Only asks about letters you have already seen.',
                onTap: () {
                  Navigator.pop(sheetContext);
                  launchSession(
                    context,
                    mode: 'quiz',
                    args: SessionArgs(type: type),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              ModeCard(
                icon: Icons.draw_outlined,
                title: 'Writing',
                subtitle: 'Trace each character with your finger.',
                onTap: () {
                  Navigator.pop(sheetContext);
                  launchSession(
                    context,
                    mode: 'writing',
                    args: SessionArgs(type: type),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              ModeCard(
                icon: Icons.tune,
                title: 'Choose letters',
                subtitle: 'Pick exactly which letters to study.',
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.pushNamed(
                    context,
                    AppRouter.chooseLetters,
                    arguments: type,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.line,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

/// Grid kana utama: cari, ganti aksara, sembunyikan romaji, dan buka detail.
class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  final _progress = ProgressController();
  final _search = TextEditingController();
  String _script = 'hiragana';
  String _query = '';
  String? _selectedId;
  bool _showRomaji = true;

  /// Kartu "Start here" disembunyikan pengguna? null = belum dimuat.
  bool? _startHidden;

  @override
  void initState() {
    super.initState();
    KanaRepository.instance.getMeta('start_card_hidden').then((v) {
      if (mounted) setState(() => _startHidden = v == '1');
    });
  }

  void _setStartHidden(bool hidden) {
    setState(() => _startHidden = hidden);
    KanaRepository.instance.setMeta('start_card_hidden', hidden ? '1' : '0');
  }

  @override
  void dispose() {
    _progress.dispose();
    _search.dispose();
    super.dispose();
  }

  List<Kana> get _list => _script == 'hiragana' ? hiraganaList : katakanaList;

  List<Kana> get _visible {
    if (_query.trim().isEmpty) return _list;
    final q = _query.trim().toLowerCase();
    return _list
        .where(
          (k) =>
              k.character.contains(q) ||
              k.romaji.toLowerCase().contains(q) ||
              k.id.toLowerCase().contains(q),
        )
        .toList();
  }

  /// Huruf yang sedang dipelajari di script ini; kalau belum ada, lima huruf
  /// pertama (yang otomatis dipakai sebagai awalan).
  List<Kana> _focusLetters(ProgressStats? stats) {
    final active = stats?.active ?? const <String>{};
    final inSet = _list.where((k) => active.contains(k.id)).toList();
    return inSet.isNotEmpty
        ? inSet
        : _list.take(KanaRepository.starterCount).toList();
  }

  bool _hasStarted(ProgressStats? stats) =>
      _list.any((k) => (stats?.masterySteps[k.id] ?? 0) > 0);

  Widget _startCard(ProgressStats? stats) {
    final letters = _focusLetters(stats);
    final preview = letters.take(5).map((k) => k.character).join(' ');
    final more = letters.length > 5 ? ' +${letters.length - 5}' : '';
    final started = _hasStarted(stats);
    final scriptName = _script == 'hiragana' ? 'Hiragana' : 'Katakana';
    return _StartCard(
      title: started ? 'Continue learning' : 'Start here',
      subtitle:
          started ? '$scriptName · $preview$more' : 'Lesson 1 · $preview',
      onStart: () => launchSession(
        context,
        mode: 'flashcard',
        args: SessionArgs(type: _script),
      ),
      onClose: () => _setStartHidden(true),
    );
  }

  void _selectScript(String script) {
    if (script == _script) return;
    setState(() {
      _script = script;
      _selectedId = null;
    });
  }

  Future<void> _openDetail(Kana kana, ProgressStats? stats) async {
    final step = stats?.masterySteps[kana.id] ?? 0;
    final activeSet = stats?.active ?? <String>{};
    final active = activeSet.isEmpty || activeSet.contains(kana.id);
    setState(() => _selectedId = kana.id);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _KanaDetailSheet(
        kana: kana,
        step: step,
        active: active,
        onToggleActive: () async {
          final ids = await KanaRepository.instance.activeIds();
          final next = active ? ({...ids}..remove(kana.id)) : {...ids, kana.id};
          await KanaRepository.instance.setActiveIds(next);
          if (sheetContext.mounted) Navigator.pop(sheetContext);
        },
        onStudy: (mode) async {
          Navigator.pop(sheetContext);
          // Huruf yang diketuk ikut masuk set supaya benar-benar dipelajari.
          if (!active) await KanaRepository.instance.addToActive(kana);
          if (!mounted) return;
          launchSession(
            context,
            mode: mode,
            args: SessionArgs(type: kana.type, firstKanaId: kana.id),
          );
        },
      ),
    );
    if (mounted) setState(() => _selectedId = null);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    // Scaffold.extendBody sudah memasukkan tinggi navigasi ke padding bawah
    // body, jadi cukup tambahkan jarak visual 8 px (jangan hitung dua kali).
    final controlsBottom = bottomInset + 8;
    final navGeometry = CurvedNavGeometry(
      maxWidth: MediaQuery.sizeOf(context).width - 40,
      count: 4,
    );
    // Tombol kiri/kanan ikut turun mengikuti ujung busur navigasi.
    final edgeDrop = navGeometry.height - navGeometry.thickness;
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: _progress,
        builder: (context, _) {
          final stats = _progress.stats;
          final visible = _visible;
          return Stack(
            children: [
              Positioned.fill(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: ScreenHeader(
                        title: 'Kana',
                        subtitle:
                            '${_list.length} characters · tap for details',
                        bottomGap: AppSpacing.md,
                        trailing: _startHidden == true
                            ? _CircleButton(
                                icon: Icons.help_outline_rounded,
                                tooltip: 'Show start guide',
                                onTap: () => _setStartHidden(false),
                              )
                            : null,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _SearchField(
                        controller: _search,
                        onChanged: (value) => setState(() => _query = value),
                        onClear: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(
                      child: visible.isEmpty
                          ? Center(
                              child: Text(
                                'No kana found.',
                                style: AppText.muted,
                              ),
                            )
                          : _KanaGrid(
                              kana: visible,
                              grouped: _query.trim().isEmpty,
                              steps: stats?.masterySteps ?? const {},
                              active: stats?.active ?? const {},
                              showRomaji: _showRomaji,
                              selectedId: _selectedId,
                              bottomInset: controlsBottom + 58,
                              header: _startHidden == false
                                  ? _startCard(stats)
                                  : null,
                              onTap: (kana) => _openDetail(kana, stats),
                            ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: controlsBottom,
                child: _BottomControls(
                  script: _script,
                  showRomaji: _showRomaji,
                  edgeDrop: edgeDrop,
                  onScript: _selectScript,
                  onToggleRomaji: () =>
                      setState(() => _showRomaji = !_showRomaji),
                  onQuiz: () => launchSession(
                    context,
                    mode: 'quiz',
                    args: SessionArgs(type: _script),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Kartu ajakan mulai belajar: ketuk untuk mulai, X untuk menyembunyikan.
class _StartCard extends StatelessWidget {
  const _StartCard({
    required this.title,
    required this.subtitle,
    required this.onStart,
    required this.onClose,
  });

  final String title;
  final String subtitle;
  final VoidCallback onStart;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onStart,
      padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
      child: Row(
        children: [
          const IconTile(icon: Icons.play_arrow_rounded),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.bodyStrong.copyWith(fontSize: 16)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppText.caption),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Hide',
            onPressed: onClose,
            icon: Icon(Icons.close, size: 18, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: AppText.body,
      cursorColor: AppColors.ink,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColors.cardRaised,
        hintText: 'Search kana or romaji',
        hintStyle: AppText.muted,
        prefixIcon: Icon(Icons.search, size: 20, color: AppColors.muted),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: Icon(Icons.close, size: 18, color: AppColors.muted),
                onPressed: onClear,
              ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          borderSide: BorderSide(color: AppColors.ink, width: 1.2),
        ),
      ),
    );
  }
}

class _KanaGrid extends StatelessWidget {
  const _KanaGrid({
    required this.kana,
    required this.grouped,
    required this.steps,
    required this.active,
    required this.showRomaji,
    required this.selectedId,
    required this.bottomInset,
    required this.onTap,
    this.header,
  });

  /// Widget di atas grid yang ikut bergulir (kartu "Start here").
  final Widget? header;
  final List<Kana> kana;
  final bool grouped;
  final Map<String, int> steps;
  final Set<String> active;
  final bool showRomaji;
  final String? selectedId;
  final double bottomInset;
  final ValueChanged<Kana> onTap;

  bool _isActive(Kana k) => active.isEmpty || active.contains(k.id);

  Widget _tile(BuildContext context, Kana k, double? width) {
    final cell = _KanaCell(
      kana: k,
      step: steps[k.id] ?? 0,
      active: _isActive(k),
      showRomaji: showRomaji,
      selected: selectedId == k.id,
      onTap: () => onTap(k),
    );
    return width == null ? cell : SizedBox(width: width, child: cell);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        const columns = 5;
        final width =
            (constraints.maxWidth - 40 - gap * (columns - 1)) / columns;
        if (!grouped) {
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset),
            child: Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [for (final k in kana) _tile(context, k, width)],
            ),
          );
        }
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset),
          child: Column(
            children: [
              if (header != null) ...[header!, const SizedBox(height: gap)],
              for (final group in groupKana(kana)) ...[
                kanaGroupRow(group, (k) => _tile(context, k, null), gap: gap),
                const SizedBox(height: gap),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _KanaCell extends StatelessWidget {
  const _KanaCell({
    required this.kana,
    required this.step,
    required this.active,
    required this.showRomaji,
    required this.selected,
    required this.onTap,
  });

  final Kana kana;
  final int step;
  final bool active;
  final bool showRomaji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mastered = step >= 4;
    final learned = step > 0;
    final lit = selected || active || learned;
    final intensity = selected
        ? 1.5
        : switch (step) {
            1 => AppColors.isDark ? 0.30 : 0.80,
            2 => AppColors.isDark ? 0.52 : 1.20,
            3 => AppColors.isDark ? 0.78 : 1.50,
            4 => 0.0,
            // Huruf yang dipilih tapi belum pernah benar tetap punya kaca
            // sangat tipis, supaya beda dari huruf yang belum dipelajari.
            _ => active ? (AppColors.isDark ? 0.14 : 0.50) : 0.0,
          };
    final fill = intensity > 0
        ? AppColors.activeGlassGradient(intensity: intensity)
        : null;
    final borderColor = selected
        ? AppColors.tileBorderStrong
        : mastered || active
        ? AppColors.tileBorder
        : Colors.transparent;
    final color = lit ? AppColors.ink : AppColors.muted;

    return Semantics(
      button: true,
      selected: selected,
      label: '${kana.character}, ${kana.romaji}',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            height: showRomaji ? 72 : 62,
            decoration: BoxDecoration(
              gradient: fill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 0.8),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  KanaCharacter(
                    kana.character,
                    size: kana.character.length > 1 ? 21 : 29,
                    color: color,
                    weight: FontWeight.w500,
                  ),
                  if (showRomaji)
                    Text(
                      kana.romaji,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        height: 1.1,
                        color: selected
                            ? AppColors.ink.withValues(alpha: 0.72)
                            : AppColors.muted,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kontrol mengambang di atas navigasi: tombol quiz, toggle Hiragana/Katakana
/// berbentuk busur (pil memanjang saat berpindah), dan tombol romaji.
class _BottomControls extends StatelessWidget {
  const _BottomControls({
    required this.script,
    required this.showRomaji,
    required this.edgeDrop,
    required this.onScript,
    required this.onToggleRomaji,
    required this.onQuiz,
  });

  final String script;
  final bool showRomaji;

  /// Turunnya ujung busur navigasi; tombol bulat ikut turun sejauh ini agar
  /// tidak tampak melayang jauh di sisi kiri/kanan.
  final double edgeDrop;
  final ValueChanged<String> onScript;
  final VoidCallback onToggleRomaji;
  final VoidCallback onQuiz;

  static const _scripts = [
    CurvedNavItem(label: 'Hiragana', text: 'Hiragana'),
    CurvedNavItem(label: 'Katakana', text: 'Katakana'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Transform.translate(
          offset: Offset(0, edgeDrop),
          child: _CircleButton(
            icon: Icons.sports_esports_outlined,
            tooltip: 'Quiz this script',
            onTap: onQuiz,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CurvedNavBar(
            items: _scripts,
            currentIndex: script == 'katakana' ? 1 : 0,
            onTap: (i) => onScript(i == 0 ? 'hiragana' : 'katakana'),
            thickness: 42,
            slotWidth: 104,
            haptics: false,
            pillColor: AppColors.segPill,
            idleColor: AppColors.segText,
            activeColor: AppColors.segTextOn,
          ),
        ),
        const SizedBox(width: 8),
        Transform.translate(
          offset: Offset(0, edgeDrop),
          child: _CircleButton(
            icon: showRomaji
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            tooltip: showRomaji ? 'Hide romaji' : 'Show romaji',
            selected: showRomaji,
            onTap: onToggleRomaji,
          ),
        ),
      ],
    );
  }
}

/// Tombol bulat tembus pandang (tanpa border), sewarna bar melengkung.
class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      excludeSemantics: true,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: selected ? AppColors.segPill : AppColors.glass,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                icon,
                size: 20,
                color: selected ? AppColors.segTextOn : AppColors.glassIcon,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KanaDetailSheet extends StatelessWidget {
  const _KanaDetailSheet({
    required this.kana,
    required this.step,
    required this.active,
    required this.onToggleActive,
    required this.onStudy,
  });

  final Kana kana;
  final int step;
  final bool active;
  final Future<void> Function() onToggleActive;

  /// [mode]: flashcard | quiz | writing.
  final ValueChanged<String> onStudy;

  @override
  Widget build(BuildContext context) {
    final example = exampleFor(kana);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.large),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: _SheetHandle()),
              const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.cardRaised,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: KanaCharacter(
                      kana.character,
                      size: kana.character.length > 1 ? 38 : 52,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kana.romaji,
                          style: AppText.title.copyWith(fontSize: 28),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${kana.typeLabel} · ${active ? 'in your set' : 'not in your set'}',
                          style: AppText.muted,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            MasteryIndicator(step: step),
                            const SizedBox(width: 8),
                            Text(
                              step >= 4 ? 'Mastered' : 'Mastery $step of 4',
                              style: AppText.caption,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Hear it',
                    onPressed: () => KanaAudioService.instance.playCycle(kana),
                    icon: Icon(Icons.volume_up_outlined, color: AppColors.ink),
                  ),
                ],
              ),
              if (example != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('Example', style: AppText.caption),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    KanaCharacter(example.$1, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${example.$2} · ${example.$3}',
                        style: AppText.muted,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Start flashcards',
                onPressed: () => onStudy('flashcard'),
                trailing: Icons.arrow_forward,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () => onStudy('writing'),
                    icon: Icon(Icons.draw_outlined,
                        size: 18, color: AppColors.muted),
                    label: Text('Writing', style: AppText.muted),
                  ),
                  TextButton.icon(
                    onPressed: () => onStudy('quiz'),
                    icon: Icon(Icons.quiz_outlined,
                        size: 18, color: AppColors.muted),
                    label: Text('Quick quiz', style: AppText.muted),
                  ),
                ],
              ),
              PrimaryButton(
                label: active ? 'Remove from my letters' : 'Add to my letters',
                kind: ButtonKind.secondary,
                onPressed: onToggleActive,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
