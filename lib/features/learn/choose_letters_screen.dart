import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/kana_character.dart';
import '../../core/widgets/kana_group_row.dart';
import '../../core/widgets/mastery_indicator.dart';
import '../../core/widgets/pill_button.dart';
import '../../data/models/kana.dart';
import '../../data/repositories/kana_repository.dart';
import '../../data/seed/kana_data.dart';

/// Pilih huruf mana yang mau dipelajari. Flashcard dan kuis hanya memakai
/// huruf yang dicentang di sini; huruf baru tidak pernah masuk otomatis.
class ChooseLettersScreen extends StatefulWidget {
  const ChooseLettersScreen({super.key, required this.type});

  final String type; // hiragana | katakana | mixed

  @override
  State<ChooseLettersScreen> createState() => _ChooseLettersScreenState();
}

class _ChooseLettersScreenState extends State<ChooseLettersScreen> {
  final _repo = KanaRepository.instance;
  Set<String> _selected = {};
  Map<String, int> _levels = {};
  bool _loaded = false;
  late String _script = widget.type == 'katakana' ? 'katakana' : 'hiragana';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ids = await _repo.activeIds();
    final progress = await _repo.loadProgress();
    if (!mounted) return;
    setState(() {
      _selected = ids;
      _levels = {for (final e in progress.entries) e.key: e.value.masteryLevel};
      _loaded = true;
    });
  }

  List<Kana> get _list => _script == 'hiragana' ? hiraganaList : katakanaList;

  Future<void> _save(Set<String> ids) async {
    setState(() => _selected = ids);
    await _repo.setActiveIds(ids);
  }

  void _toggle(Kana k) {
    final next = {..._selected};
    if (!next.remove(k.id)) next.add(k.id);
    _save(next);
  }

  void _toggleGroup(List<Kana> group) {
    final allOn = group.every((k) => _selected.contains(k.id));
    final next = {..._selected};
    for (final k in group) {
      allOn ? next.remove(k.id) : next.add(k.id);
    }
    _save(next);
  }

  Future<void> _addNext() async {
    await _repo.addNextLetters(_script);
    await _load();
  }

  String _groupLabel(String g) {
    if (g == 'vowels') return 'Vowels';
    if (g == 'n-final') return 'N';
    if (g == 'handakuten') return 'Handakuten · P';
    if (g.startsWith('dakuten-')) {
      return 'Dakuten · ${g.substring(8).toUpperCase()}';
    }
    if (g.startsWith('yoon-')) {
      return 'Combos · ${g.substring(5).toUpperCase()}';
    }
    return '${g.toUpperCase()} row';
  }

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<Kana>>{};
    for (final k in _list) {
      groups.putIfAbsent(k.group, () => []).add(k);
    }
    final count = _list.where((k) => _selected.contains(k.id)).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Choose letters')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Text(
                  'Only the letters you pick are used in flashcards and quizzes. '
                  'New letters are never added unless you add them.',
                  style: AppText.muted,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    SegmentedButton<String>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: 'hiragana', label: Text('あ')),
                        ButtonSegment(value: 'katakana', label: Text('ア')),
                      ],
                      selected: {_script},
                      onSelectionChanged: (v) =>
                          setState(() => _script = v.first),
                    ),
                    const Spacer(),
                    Text('$count selected', style: AppText.caption),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    PillButton(
                      icon: Icons.add,
                      label: 'Add next 5',
                      onTap: _addNext,
                    ),
                    PillButton(
                      icon: Icons.done_all,
                      label: 'Select all',
                      onTap: () =>
                          _save({..._selected, ..._list.map((k) => k.id)}),
                    ),
                    PillButton(
                      icon: Icons.clear_all,
                      label: 'Clear',
                      onTap: () => _save(
                        _selected.difference(_list.map((k) => k.id).toSet()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                for (final entry in groups.entries) ...[
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _toggleGroup(entry.value),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _groupLabel(entry.key),
                              style: AppText.section,
                            ),
                          ),
                          Text('Tap to select row', style: AppText.caption),
                        ],
                      ),
                    ),
                  ),
                  kanaGroupRow(entry.value, _tile),
                  const SizedBox(height: AppSpacing.sm),
                ],
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'If you unselect everything in a script, its first row is used again.',
                  style: AppText.muted,
                ),
              ],
            ),
    );
  }

  Widget _tile(Kana k) {
    final on = _selected.contains(k.id);
    return Semantics(
      button: true,
      selected: on,
      label: '${k.character} ${k.romaji}',
      excludeSemantics: true,
      child: _LetterTile(
        kana: k,
        on: on,
        level: _levels[k.id] ?? 0,
        onTap: () => _toggle(k),
      ),
    );
  }
}

/// Tile huruf. Saat dipilih: kaca halus memudar masuk dan tile membesar
/// sedikit. Warnanya sengaja lembut; pip penguasaan dibuat redup supaya tidak
/// lebih terang dari huruf.
class _LetterTile extends StatelessWidget {
  const _LetterTile({
    required this.kana,
    required this.on,
    required this.level,
    required this.onTap,
  });

  final Kana kana;
  final bool on;
  final int level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    final fg = AppColors.ink;
    return AnimatedScale(
      scale: on ? 1 : 0.97,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      child: Material(
        color: AppColors.card,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 72,
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedOpacity(
                    opacity: on ? 1 : 0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.activeGlassGradient(intensity: 0.7),
                        borderRadius: radius,
                        border: Border.all(
                          color: AppColors.glassBorder,
                          width: 0.8,
                        ),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      KanaCharacter(
                        kana.character,
                        size: kana.character.length > 1 ? 20 : 25,
                        color: on ? fg : fg.withValues(alpha: 0.86),
                      ),
                      Text(
                        kana.romaji,
                        style: TextStyle(
                          fontSize: 10.5,
                          height: 1.2,
                          color: on
                              ? fg.withValues(alpha: 0.65)
                              : AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 3),
                      MasteryIndicator(
                        level: level,
                        color: fg.withValues(alpha: on ? 0.5 : 0.38),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
