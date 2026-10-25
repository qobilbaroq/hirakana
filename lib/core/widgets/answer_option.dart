import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import 'kana_character.dart';

enum OptionState { idle, correct, wrong, dimmed }

class AnswerOption extends StatelessWidget {
  const AnswerOption({
    super.key,
    required this.label,
    required this.isKana,
    required this.state,
    required this.onTap,
    this.textSize,
    this.minHeight = 84,
  });

  final String label;
  final bool isKana; // true = tampil sebagai huruf Jepang, false = romaji
  final OptionState state;
  final VoidCallback? onTap;
  final double? textSize; // null = ukuran bawaan (kana 34, romaji 24)
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    // Benar/salah ditandai warna border dan isi saja (tanpa ikon centang/X).
    Color border = Colors.transparent;
    double width = 1;
    Color? tint;
    switch (state) {
      case OptionState.correct:
        border = AppColors.sage;
        width = 1.5;
        tint = AppColors.sage.withValues(alpha: 0.22);
      case OptionState.wrong:
        border = AppColors.clay;
        width = 1.5;
        tint = AppColors.clay.withValues(alpha: 0.22);
      case OptionState.dimmed:
      case OptionState.idle:
        break;
    }

    final textColor = state == OptionState.dimmed
        ? AppColors.muted.withValues(alpha: 0.6)
        : AppColors.ink;

    final stateSuffix = switch (state) {
      OptionState.correct => ', correct',
      OptionState.wrong => ', wrong',
      _ => '',
    };

    return Semantics(
      button: onTap != null,
      label: '$label$stateSuffix',
      excludeSemantics: true,
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            constraints: BoxConstraints(minHeight: minHeight),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: border, width: width),
              color: tint ?? AppColors.card,
            ),
            child: isKana
                ? KanaCharacter(label, size: textSize ?? 34, color: textColor)
                : Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: textSize ?? 24,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
