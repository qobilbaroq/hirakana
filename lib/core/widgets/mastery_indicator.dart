import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Tiga titik kecil: makin banyak yang terisi, makin dikuasai (level 0..3).
class MasteryIndicator extends StatelessWidget {
  const MasteryIndicator({super.key, required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Mastery level $level of 3',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < level ? AppColors.sage : AppColors.sand,
            ),
          );
        }),
      ),
    );
  }
}
