import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../core/audio/kana_audio_service.dart';
import '../../core/settings/app_settings.dart';
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
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text('Appearance', style: AppText.section),
              const SizedBox(height: AppSpacing.sm),
              SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('System')),
                  ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (v) => settings.setThemeMode(v.first),
              ),
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('AMOLED black'),
                subtitle: const Text('Pure black background in dark mode'),
                // Di Light tidak ada gunanya, jadi dimatikan. Di System tetap
                // aktif: hanya berlaku kalau perangkat sedang gelap.
                value: settings.themeMode == ThemeMode.light
                    ? false
                    : settings.amoled,
                onChanged: settings.themeMode == ThemeMode.light
                    ? null
                    : settings.setAmoled,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Session length', style: AppText.section),
              const SizedBox(height: AppSpacing.xs),
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
                      onChanged: (v) => settings.setSessionSize(v.round()),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text('${settings.sessionSize}',
                        textAlign: TextAlign.end, style: AppText.section),
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
              const SizedBox(height: AppSpacing.lg),
              Text('Daily goal', style: AppText.section),
              const SizedBox(height: AppSpacing.xs),
              Text('How many minutes feels easy for you each day.',
                  style: AppText.muted),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final m in AppSettings.goalChoices)
                    ChoiceChip(
                      label: Text('$m min'),
                      selected: settings.goalMinutes == m,
                      selectedColor: AppColors.sage.withValues(alpha: 0.35),
                      backgroundColor: AppColors.sand,
                      side: BorderSide.none,
                      onSelected: (_) => settings.setGoalMinutes(m),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Sound', style: AppText.section),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Play sound automatically'),
                subtitle: const Text('When a flashcard is revealed or an answer is wrong.'),
                value: settings.autoPlay,
                onChanged: settings.setAutoPlay,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text('When you replay the same letter', style: AppText.muted),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final p in AudioPattern.values)
                    ChoiceChip(
                      label: Text(p.label),
                      selected: settings.audioPattern == p,
                      selectedColor: AppColors.sage.withValues(alpha: 0.35),
                      backgroundColor: AppColors.sand,
                      side: BorderSide.none,
                      onSelected: (_) => settings.setAudioPattern(p),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => KanaAudioService.instance.playCycle(hiraganaList.first),
                  icon: const Icon(Icons.volume_up_outlined, size: 20),
                  label: const Text('Test sound (あ)'),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Credits', style: AppText.section),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Stroke order data: KanjiVG (CC BY-SA 3.0), kanjivg.tagaini.net\n'
                'Letter voice clips: veardk/just-gojuon (MIT)\n'
                'Word voice: HTS voice tohoku-f01, Tohoku University ICN Lab (CC BY 4.0)\n'
                'Word list: JMdict, EDRDG (CC BY-SA 4.0), edrdg.org',
                style: AppText.muted,
              ),
            ],
          );
        },
      ),
    );
  }
}
