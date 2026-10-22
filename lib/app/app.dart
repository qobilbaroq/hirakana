import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/settings/app_settings.dart';
import 'router.dart';
import 'theme/app_background.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

class KanaQuestApp extends StatelessWidget {
  const KanaQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return MaterialApp(
          title: 'Kana Quest',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(Brightness.light),
          darkTheme: buildAppTheme(Brightness.dark),
          themeMode: settings.themeMode,
          initialRoute: AppRouter.home,
          onGenerateRoute: AppRouter.onGenerateRoute,
          builder: (context, child) {
            final dark = Theme.of(context).brightness == Brightness.dark;
            _syncPalette(dark);
            final icons = dark ? Brightness.light : Brightness.dark;
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: icons,
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarDividerColor: Colors.transparent,
                systemNavigationBarIconBrightness: icons,
                systemNavigationBarContrastEnforced: false,
              ),
              child: AppBackground(child: child ?? const SizedBox.shrink()),
            );
          },
        );
      },
    );
  }

  /// Warna widget dibaca dari [AppColors], jadi saat tema berganti kita perlu
  /// menyuruh seluruh widget dibangun ulang satu kali.
  static void _syncPalette(bool dark) {
    if (AppColors.isDark == dark) return;
    AppColors.isDark = dark;
    WidgetsBinding.instance.addPostFrameCallback((_) => _rebuildAll());
  }

  static void _rebuildAll() {
    void rebuild(Element el) {
      el.markNeedsBuild();
      el.visitChildren(rebuild);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(rebuild);
  }
}
