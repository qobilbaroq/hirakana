import 'package:flutter/widgets.dart';

/// Durasi animasi yang menghormati pengaturan Reduce Motion sistem.
///
/// Kalau pengguna mematikan animasi ([MediaQueryData.disableAnimations]),
/// durasinya nol sehingga perubahan langsung terjadi tanpa gerak.
Duration motionDuration(BuildContext context, Duration normal) {
  final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  return reduce ? Duration.zero : normal;
}
