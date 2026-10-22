import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Empat langkah penguasaan, digambar sebagai kaca kecil.
///
/// [step] 0..4 dipakai langsung oleh grid kana. Pemanggil lama yang hanya punya
/// [level] 0..3 tetap bekerja lewat pemetaan di bawah.
class MasteryIndicator extends StatelessWidget {
  const MasteryIndicator({super.key, this.level, this.step, this.color})
      : assert(level != null || step != null);

  final int? level;
  final int? step;
  final Color? color;

  int get _step {
    if (step != null) return step!.clamp(0, 4);
    return switch (level ?? 0) {
      0 => 0,
      1 => 1,
      2 => 2,
      _ => 4,
    };
  }

  @override
  Widget build(BuildContext context) {
    final filled = _step;
    return Semantics(
      label: 'Mastery ${_step == 4 ? 'complete' : '$_step of 4'}',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(4, (i) {
          final on = i < filled;
          return Container(
            width: 10,
            height: 5,
            margin: const EdgeInsets.symmetric(horizontal: 1.2),
            decoration: BoxDecoration(
              color: on ? (color ?? AppColors.active) : Colors.transparent,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                color: on ? Colors.transparent : AppColors.glassBorder,
                width: 0.8,
              ),
            ),
          );
        }),
      ),
    );
  }
}
