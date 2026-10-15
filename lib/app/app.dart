import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/settings/app_settings.dart';
import 'router.dart';
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
          darkTheme: buildAppTheme(Brightness.dark, amoled: settings.amoled),
          themeMode: settings.themeMode,
          initialRoute: AppRouter.home,
          onGenerateRoute: AppRouter.onGenerateRoute,
          builder: (context, child) {
            final dark = Theme.of(context).brightness == Brightness.dark;
            // AMOLED hanya berarti sesuatu kalau tema aktifnya gelap.
            _syncPalette(dark, dark && settings.amoled);
            final icons = dark ? Brightness.light : Brightness.dark;
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: icons,
                systemNavigationBarColor: AppColors.paper,
                systemNavigationBarIconBrightness: icons,
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }

  /// Warna widget dibaca dari [AppColors], jadi saat tema berganti (atau
  /// mode AMOLED dinyalakan) kita perlu menyuruh seluruh widget dibangun ulang
  /// satu kali.
  static void _syncPalette(bool dark, bool amoled) {
    if (AppColors.isDark == dark && AppColors.isAmoled == amoled) return;
    AppColors.isDark = dark;
    AppColors.isAmoled = amoled;
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
