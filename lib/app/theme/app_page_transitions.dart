import 'package:flutter/material.dart';

/// Transisi halaman yang tenang: konten baru masuk dengan fade + geser tipis.
///
/// Dipakai oleh semua [MaterialPageRoute] lewat [ThemeData.pageTransitionsTheme],
/// jadi halaman Settings, Choose letters, sesi latihan, dan dialog layar penuh
/// punya ritme yang sama.
class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final offset = Tween<Offset>(
      begin: const Offset(0, 0.025),
      end: Offset.zero,
    ).animate(curved);

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(position: offset, child: child),
    );
  }
}
