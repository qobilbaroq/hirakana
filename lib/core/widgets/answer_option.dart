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
  });

  final String label;
  final bool isKana; // true = tampil sebagai huruf Jepang, false = romaji
  final OptionState state;
  final VoidCallback? onTap;
  final double? textSize; // null = ukuran bawaan (kana 34, romaji 24)

  @override
  Widget build(BuildContext context) {
    Color border = Colors.transparent;
    double width = 1;
    Color? icon;
    switch (state) {
      case OptionState.correct:
        border = AppColors.sage;
        width = 1.5;
        icon = AppColors.sage;
      case OptionState.wrong:
        border = AppColors.clay;
        width = 1.5;
        icon = AppColors.clay;
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
            constraints: const BoxConstraints(minHeight: 84),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: border, width: width),
              color: state == OptionState.idle || state == OptionState.dimmed
                  ? AppColors.card
                  : AppColors.sand.withValues(alpha: 0.55),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                isKana
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
                if (icon != null)
                  Positioned(
                    top: 0,
                    right: 4,
                    child: Icon(
                      state == OptionState.correct
                          ? Icons.check_circle
                          : Icons.cancel,
                      size: 17,
                      color: icon,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
