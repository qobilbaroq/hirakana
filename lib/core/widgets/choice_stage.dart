import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

/// Susunan layar soal pilihan ganda: soal, kartu soal, pilihan, lalu umpan
/// balik, dibaca satu kolom dari atas ke bawah.
///
/// Kelompok ini sengaja ditaruh di bagian atas-tengah layar (bukan menempel
/// di dasar) supaya pilihan jawaban ada di zona jempol dan tidak berdempetan
/// dengan tombol Next. Umpan balik muncul DI BAWAH pilihan, jadi tinggi
/// umpan balik (pendek atau panjang) tidak menggeser pilihan. Kalau layar
/// terlalu pendek, seluruh kelompok bisa di-scroll.
///
/// Pakai di dalam `Expanded`.
class ChoiceStage extends StatelessWidget {
  const ChoiceStage({
    super.key,
    required this.prompt,
    required this.card,
    required this.choices,
    required this.feedback,
  });

  final Widget prompt;
  final Widget card;
  final Widget choices;
  final Widget feedback;

  /// Tinggi kartu soal mengikuti tinggi layar (lebih lega di layar tinggi).
  static double cardHeight(BuildContext context) =>
      (MediaQuery.sizeOf(context).height * 0.19).clamp(116.0, 164.0).toDouble();

  /// Tinggi tiap pilihan: cukup besar untuk ibu jari. [large] untuk layar
  /// dengan pilihan teks (Reading, Meaning).
  static double optionHeight(BuildContext context, {bool large = false}) {
    final h = MediaQuery.sizeOf(context).height;
    return large
        ? (h * 0.125).clamp(88.0, 112.0).toDouble()
        : (h * 0.11).clamp(80.0, 100.0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Sedikit ruang di atas supaya pilihan turun ke area tengah layar.
        final topGap = constraints.maxHeight * 0.05;
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: topGap + AppSpacing.md),
              prompt,
              const SizedBox(height: AppSpacing.sm + 2),
              card,
              const SizedBox(height: AppSpacing.lg),
              choices,
              const SizedBox(height: AppSpacing.md),
              feedback,
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
  }
}

/// Kartu soal besar dengan gradasi halus (atas = warna kartu, bawah sedikit
/// terangkat). Memakai warna tema, jadi aman di mode terang dan gelap.
class PromptPanel extends StatelessWidget {
  const PromptPanel({super.key, required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.card, AppColors.cardRaised],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: child,
    );
  }
}
