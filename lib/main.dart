import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'app/theme/app_colors.dart';
import 'core/settings/app_settings.dart';
import 'core/storage/local_database.dart';
import 'data/repositories/kana_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Kanvas menulis dan layout dirancang untuk potret.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await LocalDatabase.configurePath();
  await KanaRepository.instance.init();
  final settings = AppSettings.instance;
  await settings.load();

  // Tentukan warna sejak frame pertama supaya tidak berkedip terang->gelap.
  final platformDark =
      WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
  AppColors.isDark = settings.themeMode == ThemeMode.dark ||
      (settings.themeMode == ThemeMode.system && platformDark);
  AppColors.isAmoled = AppColors.isDark && settings.amoled;

  runApp(const KanaQuestApp());
}
