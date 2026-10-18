"""Fungsi bersama untuk build_vocab.py dan generate_audio.py.

Meniru logika Dart di lib/data/repositories/word_repository.dart
(parse kata -> potongan, romajiOf) supaya cara baca yang ditulis ke
words.tsv SAMA PERSIS dengan yang dihitung app.
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
KANA_DART = ROOT / "lib/data/seed/kana_data.dart"
SMALL = "ゃゅょャュョ"
LEVELS = {"n5n4": "N5–N4", "n3": "N3"}


def load_kana():
    """Baca tabel huruf dari kana_data.dart -> {karakter: (romaji, script)}."""
    src = KANA_DART.read_text(encoding="utf-8")
    table = {}
    for m in re.finditer(
        r"\('([^']+)',\s*'([^']+)',\s*'([^']+)',\s*'([^']+)'\)", src
    ):
        _grp, hira, kata, romaji = m.groups()
        h, k, r = hira.split(" "), kata.split(" "), romaji.split(" ")
        if not (len(h) == len(k) == len(r)):
            continue
        for i in range(len(r)):
            table[h[i]] = (r[i], "hiragana")
            table[k[i]] = (r[i], "katakana")
    return table


def parse(text, kana):
    """Pecah kata jadi potongan: ('k', romaji, script) | ('tsu',) | ('long',).
    None kalau ada karakter yang tidak dikenal app."""
    out, i = [], 0
    while i < len(text):
        ch = text[i]
        if ch in "っッ":
            out.append(("tsu",)); i += 1; continue
        if ch == "ー":
            out.append(("long",)); i += 1; continue
        if i + 1 < len(text) and text[i + 1] in SMALL:
            c = kana.get(ch + text[i + 1])
            if c is None:
                return None
            out.append(("k", c[0], c[1])); i += 2; continue
        c = kana.get(ch)
        if c is None:
            return None
        out.append(("k", c[0], c[1])); i += 1
    return out


def romaji_of(pieces):
    """Port dari WordRepository.romajiOf."""
    sb, pending = "", False
    for p in pieces:
        if p[0] == "tsu":
            pending = True; continue
        if p[0] == "long":
            for ch in reversed(sb):
                if ch in "aiueo":
                    sb += ch
                    break
            continue
        r = p[1]
        if pending:
            if r.startswith("ch"):
                sb += "t"
            elif r[0] in "kstpgzdbhfjmrcw":
                sb += r[0]
            pending = False
        sb += r
    return sb


def scripts_of(pieces):
    return {p[2] for p in pieces if p[0] == "k"}


# ---- konsonan yang diharapkan (untuk memeriksa hasil Open JTalk) ----
_SPECIAL = {"shi": "sh", "sha": "sh", "shu": "sh", "sho": "sh",
            "chi": "ch", "cha": "ch", "chu": "ch", "cho": "ch",
            "tsu": "ts", "fu": "f", "ji": "j", "ja": "j", "ju": "j", "jo": "j",
            "di": "j", "du": "z", "wo": ""}


def expected_consonants(pieces):
    out = []
    for p in pieces:
        if p[0] == "tsu":
            out.append("cl"); continue
        if p[0] == "long":
            continue
        r = p[1]
        if r == "n":
            out.append("n")
        elif r in _SPECIAL:
            if _SPECIAL[r]:
                out.append(_SPECIAL[r])
        elif len(r) > 1:
            out.append(r[:-1])
    return out
