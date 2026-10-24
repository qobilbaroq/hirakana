import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_fonts.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../core/audio/kana_audio_service.dart';
import '../../core/settings/app_settings.dart';
import '../../core/update/update_prompt.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/pill_button.dart';
import '../../core/widgets/pill_choice.dart';
import '../../data/seed/kana_data.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            children: [
              _SettingsCard(
                title: 'Appearance',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                            value: ThemeMode.system, label: Text('System')),
                        ButtonSegment(
                            value: ThemeMode.light, label: Text('Light')),
                        ButtonSegment(
                            value: ThemeMode.dark, label: Text('Dark')),
                      ],
                      selected: {settings.themeMode},
                      onSelectionChanged: (v) =>
                          settings.setThemeMode(v.first),
                    ),
                    const SizedBox(height: 18),
                    Text('Accent color', style: AppText.muted),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final a in AppAccent.values)
                          _AccentDot(
                            accent: a,
                            selected: settings.accent == a,
                            onTap: () => settings.setAccent(a),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      settings.accent.isMono
                          ? 'Mono: the default black and white look.'
                          : '${settings.accent.label} accent on buttons, '
                                'navigation, and the background.',
                      style: AppText.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SettingsCard(
                title: 'Japanese font',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Used for kana and Japanese words. Other text stays the same.',
                      style: AppText.muted,
                    ),
                    const SizedBox(height: 10),
                    for (final f in AppFonts.options) ...[
                      _FontTile(
                        option: f,
                        selected: settings.fontId == f.id,
                        onTap: () => settings.setFont(f.id),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SettingsCard(
                title: 'Session',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cards or questions in one session. Minimum 10. '
                      'If you chose fewer letters than this, letters repeat.',
                      style: AppText.muted,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            min: AppSettings.minSessionSize.toDouble(),
                            max: AppSettings.maxSessionSize.toDouble(),
                            divisions: (AppSettings.maxSessionSize -
                                    AppSettings.minSessionSize) ~/
                                5,
                            value: settings.sessionSize.toDouble(),
                            label: '${settings.sessionSize}',
                            onChanged: (v) =>
                                settings.setSessionSize(v.round()),
                          ),
                        ),
                        SizedBox(
                          width: 38,
                          child: Text(
                            '${settings.sessionSize}',
                            textAlign: TextAlign.end,
                            style: AppText.section,
                          ),
                        ),
                      ],
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Show word meaning'),
                      subtitle: const Text(
                          'In reading practice, for words that have a meaning.'),
                      value: settings.showMeaning,
                      onChanged: settings.setShowMeaning,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SettingsCard(
                title: 'Daily goal',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How many minutes feels easy for you each day.',
                      style: AppText.muted,
                    ),
                    const SizedBox(height: 10),
                    PillChoiceWrap(
                      children: [
                        for (final m in AppSettings.goalChoices)
                          PillChoice(
                            label: '$m min',
                            selected: settings.goalMinutes == m,
                            onTap: () => settings.setGoalMinutes(m),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SettingsCard(
                title: 'Sound',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Play sound automatically'),
                      subtitle: const Text(
                          'When a flashcard is revealed or an answer is wrong.'),
                      value: settings.autoPlay,
                      onChanged: settings.setAutoPlay,
                    ),
                    const SizedBox(height: 4),
                    Text('When you replay the same letter',
                        style: AppText.muted),
                    const SizedBox(height: 8),
                    PillChoiceWrap(
                      children: [
                        for (final p in AudioPattern.values)
                          PillChoice(
                            label: p.label,
                            selected: settings.audioPattern == p,
                            onTap: () => settings.setAudioPattern(p),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    PillButton(
                      icon: Icons.volume_up_outlined,
                      label: 'Test sound (あ)',
                      onTap: () => KanaAudioService.instance
                          .playCycle(hiraganaList.first),
                    ),
                  ],
                ),
              ),
              if (!kIsWeb &&
                  defaultTargetPlatform == TargetPlatform.android) ...[
                const SizedBox(height: 12),
                const _UpdateSection(),
              ],
              const SizedBox(height: AppSpacing.lg),
              Text('Credits', style: AppText.section),
              const SizedBox(height: 6),
              Text(
                'Stroke order data: KanjiVG (CC BY-SA 3.0), kanjivg.tagaini.net\n'
                'Letter voice clips: veardk/just-gojuon (MIT)\n'
                'Word voice: HTS voice tohoku-f01, Tohoku University ICN Lab (CC BY 4.0)\n'
                'Word list: written for this app, no external source\n'
                'Fonts: Noto Sans JP, Klee One, Zen Maru Gothic, Yuji Syuku, '
                'Zen Kurenaido (SIL OFL 1.1)',
                style: AppText.caption,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Lingkaran contoh warna aksen. Yang terpilih diberi cincin.
class _AccentDot extends StatelessWidget {
  const _AccentDot({
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final AppAccent accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${accent.label} accent',
      excludeSemantics: true,
      child: Tooltip(
        message: accent.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.ink : Colors.transparent,
                width: 2,
              ),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.swatch,
              ),
              child: selected
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// Satu baris pilihan font dengan contoh huruf memakai font itu sendiri.
class _FontTile extends StatelessWidget {
  const _FontTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final AppFontOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.card);
    return Semantics(
      button: true,
      selected: selected,
      label: '${option.label} font',
      excludeSemantics: true,
      child: Material(
        color: AppColors.card,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: selected ? AppColors.button : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(option.label, style: AppText.bodyStrong),
                      const SizedBox(height: 2),
                      Text(option.note, style: AppText.caption),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'あいう ア',
                  style: TextStyle(
                    fontFamily: option.family,
                    fontSize: 22,
                    height: 1.2,
                    color: AppColors.ink,
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.check_circle, size: 18, color: AppColors.button),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.cardTitle.copyWith(fontSize: 18)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Ringkas: satu baris status + tombol. Detail dan unduhan ada di popup.
class _UpdateSection extends StatefulWidget {
  const _UpdateSection();

  @override
  State<_UpdateSection> createState() => _UpdateSectionState();
}

class _UpdateSectionState extends State<_UpdateSection> {
  String? _currentVersion;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _currentVersion = info.version);
    });
  }

  @override
  Widget build(BuildContext context) {
    final version = _currentVersion;
    return _SettingsCard(
      title: 'App update',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            version == null
                ? 'Loading app version...'
                : 'Current version $version',
            style: AppText.muted,
          ),
          const SizedBox(height: 10),
          PillButton(
            icon: Icons.system_update_alt,
            label: 'Check for updates',
            onTap: () => checkForUpdateAndPrompt(context, manual: true),
          ),
        ],
      ),
    );
  }
}
