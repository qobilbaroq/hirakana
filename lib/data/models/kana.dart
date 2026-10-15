class Kana {
  final String id;
  final String character;
  final String romaji;
  final String type; // 'hiragana' | 'katakana'
  final String group;

  const Kana({
    required this.id,
    required this.character,
    required this.romaji,
    required this.type,
    required this.group,
  });

  bool get isHiragana => type == 'hiragana';
  String get typeLabel => isHiragana ? 'Hiragana' : 'Katakana';
}
