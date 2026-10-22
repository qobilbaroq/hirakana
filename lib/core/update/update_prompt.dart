import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme.dart';
import '../../data/repositories/kana_repository.dart';
import 'update_service.dart';

/// Kunci meta untuk versi yang ditekan "Nanti".
const updateDismissedMetaKey = 'update_dismissed_version';

/// Periksa rilis GitHub lalu tampilkan popup singkat kalau ada versi baru.
///
/// Dipakai dua kali: otomatis saat app dibuka ([manual] = false, sekali per
/// aplikasi dibuka) dan dari tombol di Settings ([manual] = true, yang
/// mengabaikan versi yang pernah ditunda).
Future<void> checkForUpdateAndPrompt(
  BuildContext context, {
  bool manual = false,
}) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

  GitHubRelease? found;
  try {
    found = await GitHubUpdateService.instance.checkForUpdate();
  } catch (error) {
    // Pemeriksaan otomatis sengaja diamkan: tidak ada internet atau GitHub
    // sedang tidak bisa dijawab tidak boleh mengganggu pengguna.
    if (manual && context.mounted) _showError(context, error);
    return;
  }

  if (found == null) {
    if (manual && context.mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
          content: Text('You\'re on the latest version.'),
        ));
    }
    return;
  }
  final release = found;

  if (!manual) {
    final dismissed =
        await KanaRepository.instance.getMeta(updateDismissedMetaKey);
    if (dismissed == release.tagName) return;
  }

  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (_) => UpdatePromptDialog(release: release),
  );
}

void _showError(BuildContext context, Object error) {
  final message = error is UpdateException
      ? error.message
      : 'Couldn\'t check for updates.';
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Dialog pembaruan: judul, maksimal 4 poin ringkas, tombol Nanti / Perbarui.
class UpdatePromptDialog extends StatefulWidget {
  const UpdatePromptDialog({super.key, required this.release});

  final GitHubRelease release;

  @override
  State<UpdatePromptDialog> createState() => _UpdatePromptDialogState();
}

class _UpdatePromptDialogState extends State<UpdatePromptDialog> {
  bool _downloading = false;
  double? _progress;
  String? _error;

  List<String> get _points => summarizeReleaseNotes(widget.release.notes);

  Future<void> _update() async {
    if (_downloading) return;
    setState(() {
      _downloading = true;
      _progress = null;
      _error = null;
    });
    try {
      await GitHubUpdateService.instance.downloadAndInstall(
        widget.release,
        onProgress: (value) {
          if (mounted) setState(() => _progress = value);
        },
      );
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        _downloading = false;
        _error = error.code == 'install_permission_required'
            ? 'Allow app installs for Kana Quest, then come back and tap '
                'Update again.'
            : (error.message ?? 'The update couldn\'t be installed.');
      });
      return;
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _downloading = false;
        _error = error is UpdateException ? error.message : error.toString();
      });
      return;
    }
    // Installer Android yang terbuka; tutup popup-nya.
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _later() async {
    await KanaRepository.instance
        .setMeta(updateDismissedMetaKey, widget.release.tagName);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final points = _points;
    return AlertDialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Update available', style: AppText.section),
          const SizedBox(height: AppSpacing.xs),
          Text('Version ${widget.release.version}', style: AppText.muted),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (points.isEmpty)
            Text('Version ${widget.release.version} is available.',
                style: AppText.body)
          else
            ...points.map((point) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('•  ', style: AppText.body),
                      Expanded(child: Text(point, style: AppText.body)),
                    ],
                  ),
                )),
          if (_downloading) ...[
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: AppSpacing.xs),
            Text('Downloading...', style: AppText.muted),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(_error!, style: AppText.muted.copyWith(color: AppColors.clay)),
          ],
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      actions: [
        TextButton(
          onPressed: _downloading ? null : _later,
          child: const Text('Later'),
        ),
        FilledButton(
          onPressed: _downloading ? null : _update,
          child: const Text('Update'),
        ),
      ],
    );
  }
}