import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_fonts.dart';

class KanaCharacter extends StatelessWidget {
  const KanaCharacter(
    this.text, {
    super.key,
    this.size = 48,
    this.color,
    this.weight = FontWeight.w500,
  });

  final String text;
  final double size;
  final Color? color;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: AppFonts.kana,
        fontSize: size,
        height: 1.2,
        fontWeight: weight,
        color: color ?? AppColors.ink,
      ),
    );
  }
}
