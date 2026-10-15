import 'package:flutter/material.dart';

import '../features/learn/choose_letters_screen.dart';
import '../features/learn/flashcard_screen.dart';
import '../features/learn/quiz_screen.dart';
import '../features/learn/session_controller.dart';
import '../features/learn/session_summary_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shell/main_shell.dart';
import '../features/words/word_practice_screen.dart';
import '../features/writing/writing_screen.dart';

class AppRouter {
  static const home = '/';
  static const flashcard = '/flashcard';
  static const quiz = '/quiz';
  static const writing = '/writing';
  static const summary = '/summary';
  static const chooseLetters = '/choose';
  static const settings = '/settings';
  static const words = '/words';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final Widget page;
    switch (settings.name) {
      case flashcard:
        page = FlashcardScreen(args: settings.arguments as SessionArgs);
      case quiz:
        page = QuizScreen(args: settings.arguments as SessionArgs);
      case writing:
        page = WritingScreen(args: settings.arguments as SessionArgs);
      case chooseLetters:
        page = ChooseLettersScreen(type: settings.arguments as String);
      case AppRouter.settings:
        page = const SettingsScreen();
      case words:
        page = WordPracticeScreen(args: settings.arguments as SessionArgs);
      case summary:
        page = SessionSummaryScreen(result: settings.arguments as SessionResult);
      default:
        page = const MainShell();
    }
    return MaterialPageRoute<void>(builder: (_) => page, settings: settings);
  }
}
