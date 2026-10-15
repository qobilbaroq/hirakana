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
  final double? textSize; // null = ukuran bawaan (kana 36, romaji 26)

  @override
  Widget build(BuildContext context) {
    Color border = AppColors.sand;
    double width = 1;
    Color? icon;
    switch (state) {
      case OptionState.correct:
        border = AppColors.sage;
        width = 2;
        icon = AppColors.sage;
      case OptionState.wrong:
        border = AppColors.clay;
        width = 2;
      case OptionState.dimmed:
      case OptionState.idle:
        break;
    }

    final textColor = state == OptionState.dimmed
        ? AppColors.muted.withValues(alpha: 0.6)
        : AppColors.ink;

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 88),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: border, width: width),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                isKana
                    ? KanaCharacter(label, size: textSize ?? 36, color: textColor)
                    : Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: textSize ?? 26,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                if (icon != null)
                  Positioned(
                    top: 0,
                    right: 4,
                    child: Icon(Icons.check_circle,
                        size: 18, color: AppColors.sage),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
