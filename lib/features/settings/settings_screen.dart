import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
                          'After a correct answer in reading practice, for words that have a meaning.'),
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
                'Word list: written for this app, no external source',
                style: AppText.caption,
              ),
            ],
          );
        },
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
