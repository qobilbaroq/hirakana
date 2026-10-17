#!/usr/bin/env python3
"""Periksa berkas terjemahan: laporkan nilai yang rusak.

Nilai yang dianggap rusak: memuat kana/CJK, memuat underscore, kosong,
lebih dari 40 karakter, atau memuat huruf kapital di tengah (biasanya
sisa kalimat Inggris yang bocor ke dalam terjemahan).
"""
import re
import sys

CJK = re.compile(r'[\u3040-\u30ff\u4e00-\u9fff]')
KEY = re.compile(r'^[a-z]+(#\d+)?$')
# Nilai boleh memuat huruf kapital hanya di awal kata, dan hanya untuk
# nama diri / singkatan. Kata seperti "Furthermore" atau "Cancelled" di
# tengah nilai biasanya kalimat Inggris yang bocor ke dalam terjemahan.
ALLOWED_CAPS = {
    'Barat', 'Buddha', 'Buddhis', 'Inggris', 'Tokyo', 'Jepang', 'Asia',
    'Eropa', 'Amerika', 'SMA', 'SMP', 'SD', 'AC', 'TV', 'Uni', 'Nippon',
    'Kanji', 'Hiragana', 'Katakana', 'Romaji', 'Okinawa', 'Hokkaido',
    'ASEAN', 'APEC', 'ASEAN', 'Nanking', 'Kongo', 'Nepal', 'Sinhala',
}


def bad_caps(value):
    """Balik True kalau ada kata kapital di tengah nilai.

    Kata pertama boleh kapital (nilai ditampilkan sebagai kalimat), jadi
    hanya token setelah spasi/koma yang diperiksa.
    """
    import re as _re
    toks = _re.findall(r"[A-Za-z][A-Za-z'\-]*", value)
    for tok in toks[1:]:
        if not tok[0].isupper():
            continue
        if tok.isupper():          # singkatan: SMA, AC, TV, ASEAN
            continue
        if tok in ALLOWED_CAPS:
            continue
        return True
    return False


def main(paths):
    total = bad = 0
    for path in paths:
        for no, raw in enumerate(open(path, encoding='utf-8'), 1):
            raw = raw.rstrip('\n')
            if not raw.strip() or raw.lstrip().startswith('#'):
                continue
            total += 1
            parts = raw.split('\t')
            if len(parts) != 2:
                print(f'{path}:{no} KOLOM  {raw[:60]!r}')
                bad += 1
                continue
            key, value = parts[0], parts[1]
            why = None
            if not KEY.match(key):
                why = 'kunci bukan romaji'
            elif not value.strip():
                why = 'kosong'
            elif CJK.search(value):
                why = 'punya kana/CJK'
            elif '_' in value:
                why = 'punya underscore'
            elif len(value) > 40:
                why = f'terlalu panjang ({len(value)})'
            elif bad_caps(value):
                why = 'huruf kapital di tengah'
            if why:
                print(f'{path}:{no} {why}: {key}={value}')
                bad += 1
    print(f'{total} baris diperiksa, {bad} bermasalah')
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:] or ['tool/translations/id.tsv']))
