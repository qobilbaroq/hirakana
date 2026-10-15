import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_drawing/path_drawing.dart';

/// Data urutan goresan dari KanjiVG (CC BY-SA 3.0, https://kanjivg.tagaini.net).
/// Semua path memakai ruang koordinat 109 x 109.
class StrokeRepository {
  StrokeRepository._();
  static final instance = StrokeRepository._();

  static const double box = 109;

  Map<String, List<String>>? _raw;
  final Map<String, List<Path>> _cache = {};

  Future<void> load() async {
    if (_raw != null) return;
    final text = await rootBundle.loadString('assets/strokes/kana_strokes.json');
    final map = jsonDecode(text) as Map<String, dynamic>;
    _raw = map.map((k, v) => MapEntry(k, (v as List).cast<String>()));
  }

  Path _transform(String d, double scale, double dx, double dy) {
    final m = Matrix4.identity()
      ..translate(dx, dy)
      ..scale(scale, scale, 1.0);
    return parseSvgPathData(d).transform(m.storage);
  }

  /// Daftar goresan sesuai urutan menulis, atau null kalau datanya tidak ada.
  /// Huruf kombinasi (きゃ dst.) disusun dari huruf dasar + ya/yu/yo kecil.
  List<Path>? pathsFor(String character) {
    final raw = _raw;
    if (raw == null) return null;
    final cached = _cache[character];
    if (cached != null) return cached;

    List<Path>? result;
    if (character.length == 1) {
      final list = raw[character];
      if (list != null) {
        result = [for (final d in list) parseSvgPathData(d)];
      }
    } else if (character.length == 2) {
      final base = raw[character[0]];
      final small = raw[character[1]];
      if (base != null && small != null) {
        result = [
          for (final d in base) _transform(d, 0.66, -6, 18),
          for (final d in small) _transform(d, 0.6, 46, 38),
        ];
      }
    }
    if (result != null) _cache[character] = result;
    return result;
  }
}
