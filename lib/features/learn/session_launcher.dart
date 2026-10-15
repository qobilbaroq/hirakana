import 'package:flutter/material.dart';

import '../../app/router.dart';
import '../../data/repositories/kana_repository.dart';
import '../../data/repositories/word_repository.dart';
import 'quiz_question.dart';
import 'session_controller.dart';

/// Membuka sesi belajar. Pertama kali dipakai, tampilkan onboarding singkat.
/// Kuis hanya jalan kalau ada huruf pilihanmu yang sudah pernah dilihat.
Future<void> launchSession(
  BuildContext context, {
  required String mode, // flashcard | quiz | writing
  required SessionArgs args,
}) async {
  final repo = KanaRepository.instance;
  final navigator = Navigator.of(context);

  if (mode == 'quiz' && args.quizKind == QuizKind.lookalike) {
    if ((await repo.confusableQueue()).isEmpty) {
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Nothing to drill yet'),
          content: const Text(
            'This drill uses letters you have mixed up in quizzes at least '
            'twice. Do a few quizzes and they will show up here.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
  } else if (mode == 'quiz' && await repo.reviewedActiveCount(args.type) == 0) {
    if (!context.mounted) return;
    final goFlashcards = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Study first'),
        content: const Text(
          'The quiz only asks about letters you have already seen. '
          'Start with a few flashcards, then come back.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Open flashcards'),
          ),
        ],
      ),
    );
    if (goFlashcards == true && context.mounted) {
      await launchSession(context,
          mode: 'flashcard', args: SessionArgs(type: args.type));
    }
    return;
  }

  if (mode == 'words') {
    final count = (await WordRepository.instance.available(args.type)).length;
    if (count < WordRepository.minWords) {
      if (!context.mounted) return;
      final goChoose = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Not enough words yet'),
          content: Text(
            'Word practice only uses words made from your chosen letters. '
            'Right now only $count word${count == 1 ? '' : 's'} fit. '
            'Add a few more letters to unlock more.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Not now'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Choose letters'),
            ),
          ],
        ),
      );
      if (goChoose == true) {
        navigator.pushNamed(AppRouter.chooseLetters, arguments: args.type);
      }
      return;
    }
    navigator.pushNamed(AppRouter.words, arguments: args);
    return;
  }

  if (await repo.getMeta('onboarded') == null) {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Welcome 👋'),
        content: const Text(
          "We'll start with just five letters, and you decide when to add more. "
          'See each one, try to recall its sound, then reveal. '
          'No pressure, no streak to lose.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Start'),
          ),
        ],
      ),
    );
    await repo.setMeta('onboarded', '1');
  }

  final route = switch (mode) {
    'quiz' => AppRouter.quiz,
    'writing' => AppRouter.writing,
    _ => AppRouter.flashcard,
  };
  navigator.pushNamed(route, arguments: args);
}
