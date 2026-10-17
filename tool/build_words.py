#!/usr/bin/env python3
"""Bangun assets/data/words.tsv dari daftar kosakata JLPT.

Sumber data (lihat DOKUMENTASI.md bagian 9):
  - tool/data/n5.csv, n4.csv, n3.csv
   .open-anki-jlpt-decks (MIT, Jamie Sinclair), berisi kosakata JLPT yang
   ，基于 Jonathan Waller / tanos.co.uk (CC BY).

Jalankan dari root proyek:
    python3 tool/build_words.py            # tulis assets/data/words.tsv
    python3 tool/build_words.py --stats    # hanya tampilkan statistik

Skrip ini idempoten: dijalankan dari nol menghasilkan berkas yang sama.
"""

import argparse
import csv
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOOL = os.path.join(ROOT, "tool")
KANA_DART = os.path.join(ROOT, "lib", "data", "seed", "kana_data.dart")
LEGACY_TSV = os.path.join(TOOL, "data", "words_legacy.tsv")
OUT_TSV = os.path.join(ROOT, "assets", "data", "words.tsv")
WORDS_AUDIO = os.path.join(ROOT, "assets", "audio", "words")
INDO_TSV = os.path.join(TOOL, "translations", "id.tsv")

SMALL = "ゃゅょャュョ"          # boleh: digabung jadi satu huruf (きゃ)
FORBIDDEN_SMALL = "ぁぃぅぇぉァィゥェォ"  # tidak ada di data huruf app
SMALL_TSU = "っッ"
LONG_MARK = "ー"

LEVELS = [("n5.csv", "N5"), ("n4.csv", "N4"), ("n3.csv", "N3")]
LEVEL_ORDER = {"N5": 0, "N4": 1, "N3": 2}


# --------------------------------------------------------------- data huruf

def load_kana():
    """Baca _rows dari kana_data.dart -> {karakter: romaji}."""
    src = open(KANA_DART, encoding="utf-8").read()
    rows = re.findall(
        r"\('([^']+)',\s*'([^']*)',\s*'([^']*)',\s*'([^']*)'\)", src)
    table = {}
    for _group, hira, kata, romaji in rows:
        h, k, r = hira.split(), kata.split(), romaji.split()
        if not (len(h) == len(k) == len(r)):
            raise SystemExit(f"baris _rows tidak seimbang: {_group}")
        for chars in (h, k):
            for ch, rm in zip(chars, r):
                table[ch] = rm
    return table


# ------------------------------------------------- padanan WordRepository.parse

def parse(text, table):
    """Padanan WordRepository.parse: kembalikan (pieces, n_huruf) atau None.

    pieces: list of ('kana', romaji) | ('tsu', None) | ('long', None)
    None kalau ada karakter yang tidak dikenal app.
    """
    if not text:
        return None
    pieces = []
    i = 0
    while i < len(text):
        ch = text[i]
        if ch in SMALL_TSU:
            pieces.append(("tsu", None))
            i += 1
            continue
        if ch == LONG_MARK:
            pieces.append(("long", None))
            i += 1
            continue
        if i + 1 < len(text) and text[i + 1] in SMALL:
            combo = ch + text[i + 1]
            if combo not in table:
                return None
            pieces.append(("kana", table[combo]))
            i += 2
            continue
        if ch not in table:
            return None
        pieces.append(("kana", table[ch]))
        i += 1
    return pieces


def romaji_of(pieces):
    """Padanan WordRepository.romajiOf."""
    out = []
    pending = False
    for kind, value in pieces:
        if kind == "tsu":
            pending = True
            continue
        if kind == "long":
            for ch in reversed("".join(out)):
                if ch in "aiueo":
                    out.append(ch)
                    break
            continue
        if pending:
            if value.startswith("ch"):
                out.append("t")
            elif value[0] in "kstpgzdbhfjmrcw":
                out.append(value[0])
            pending = False
        out.append(value)
    return "".join(out)


# ------------------------------------------------------------------- muatan

def has_audio(reading):
    return (
        os.path.isfile(os.path.join(WORDS_AUDIO, f"{reading}.mp3"))
        and os.path.isfile(os.path.join(WORDS_AUDIO, f"{reading}_slow.mp3"))
    )


def load_old_pool():
    """Kata dari pool sebelumnya (kurasi + JMdict).

    Dibaca dari tool/data/words_legacy.tsv, BUKAN dari assets/data/words.tsv,
    supaya skrip ini idempoten: menjalankan berkali-kali tetap menghasilkan
    berkas yang sama (tidak membaca berkas yangyang dia buat sendiri).
    """
    old = {}
    if not os.path.isfile(LEGACY_TSV):
        return old
    for line in open(LEGACY_TSV, encoding="utf-8"):
        line = line.rstrip("\n")
        if not line.strip():
            continue
        c = line.split("\t")
        if len(c) < 3:
            continue
        old[c[0]] = {
            "reading": c[1],
            "meaning_id": c[3].strip() if len(c) > 3 else "",
            "meaning_en": "",
            "level": "",
            "kanji": "",
        }
    return old


def load_jlpt():
    """Baca CSV JLPT, kembalikan daftar entry berurutan (N5, N4, N3).

    Kunci untuk berkas terjemahan adalah ROMAJI (ASCII).-Romaji bentrok
    sangat jarang (homofon seperti クラス "a class" vs くらす "to live"),
    untuk itu kunci kedua dan seterusnya memakai suffix #2, #3. Urutan
    penentuannya deterministik: urutan level, lalu urutan baris di CSV.
    """
    entries = []
    stats = {}
    for fname, level in LEVELS:
        path = os.path.join(TOOL, "data", fname)
        kept = 0
        raw = 0
        for row in csv.DictReader(open(path, encoding="utf-8")):
            raw += 1
            reading = (row.get("reading") or "").strip()
            expr = (row.get("expression") or "").strip()
            meaning = (row.get("meaning") or "").strip()
            if not reading:
                continue
            if any(c in FORBIDDEN_SMALL for c in reading):
                continue
            pieces = parse(reading, table)
            if pieces is None:
                continue
            letters = [p for p in pieces if p[0] == "kana"]
            if len(letters) < 2:          # minimal 2 huruf kana
                continue
            romaji = romaji_of(pieces)
            if not romaji or not re.fullmatch(r"[a-z]+", romaji):
                continue
            kanji = expr if expr != reading and \
                all(not (0x3040 <= ord(c) <= 0x30FF) for c in expr) else ""
            entries.append({
                "text": reading,
                "reading": romaji,
                "level": level,
                "meaning_en": meaning,
                "kanji": kanji,
            })
            kept += 1
        stats[level] = {"raw": raw, "kept": kept}

    # kunci unik untuk berkastranslasi
    seen = {}
    for e in entries:
        r = e["reading"]
        seen[r] = seen.get(r, 0) + 1
        e["key"] = r if seen[r] == 1 else f"{r}#{seen[r]}"

    # Buang duplikat teks, level terendah menang (N5 < N4 < N3)
    best = {}
    for e in entries:
        cur = best.get(e["text"])
        if cur is None or LEVEL_ORDER[e["level"]] < LEVEL_ORDER[cur["level"]]:
            best[e["text"]] = e
    return list(best.values()), stats


def load_indo():
    """Baca tool/translations/id.tsv (kata TAB arti Indonesia).

    Berkas ini boleh diisi sebagian: kata yang belum diterjemahkan memakai
    arti Inggris sebagai cadangan (lihat DOKUMENTASI.md bagian 6).
    """
    if not os.path.isfile(INDO_TSV):
        return {}
    result = {}
    for line in open(INDO_TSV, encoding="utf-8"):
        line = line.rstrip("\n")
        if not line.strip() or line.startswith("#"):
            continue
        parts = line.split("\t")
        if len(parts) < 2:
            continue
        text, indo = parts[0], parts[1].strip()
        if indo:
            result[text] = indo
    return result


# -------------------------------------------------------------------- main

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--stats", action="store_true",
                    help="hanya tampilkan statistik, jangan tulis berkas")
    args = ap.parse_args()

    global table
    table = load_kana()
    if not table:
        raise SystemExit("gagal membaca kana_data.dart")

    jlpt_list, raw_stats = load_jlpt()
    old = load_old_pool()
    indo = load_indo()
    jlpt_texts = {w["text"] for w in jlpt_list}

    rows = []
    # JLPT dulu (punya arti), lalu kata umum lain.
    for w in jlpt_list:
        rows.append({
            "text": w["text"],
            "reading": w["reading"],
            "level": w["level"],
            "meaning_en": w["meaning_en"],
            "meaning_id": indo.get(w["key"], ""),
            "kanji": w["kanji"],
        })
    for text, w in old.items():
        if text in jlpt_texts:
            continue
        # Pool lama TIDAK pernah disaring, sehingga ikut terbawa entah apa:
        # kana tunggal (き, ご, て), satu kana + tanda panjang (ツー), dan
        # kata berisi karakter yang tidak dikenal. Semuanya akan menggigit
        # di latihan: soal kata jadi tidak bisa dijawab atau salah dibaca
        # hanya jadi satu huruf. Saring dengan aturan yang sama seperti JLPT.
        if any(c in FORBIDDEN_SMALL for c in text):
            continue
        pieces = parse(text, table)
        if pieces is None:
            continue
        letters = [p for p in pieces if p[0] == "kana"]
        if len(letters) < 2:
            continue
        romaji = romaji_of(pieces)
        if not romaji or not re.fullmatch(r"[a-z]+", romaji):
            continue
        rows.append({
            "text": text,
            "reading": w["reading"],
            "level": "",
            "meaning_en": "",
            "meaning_id": w["meaning_id"],
            "kanji": "",
        })

    for r in rows:
        r["has_audio"] = 1 if has_audio(r["reading"]) else 0
        r["meaning_en"] = r["meaning_en"][:40]
        r["meaning_id"] = r["meaning_id"][:35]

    # statistik
    by_level = {}
    for r in rows:
        by_level.setdefault(r["level"] or "(kosong)", 0)
        by_level[r["level"] or "(kosong)"] += 1

    print("=== SEBELUM PENYARINGAN (baris CSV mentah) ===")
    for lvl in ("N5", "N4", "N3"):
        print(f"  {lvl}: {raw_stats[lvl]['raw']} baris -> "
              f"{raw_stats[lvl]['kept']} lolos filter")
    print()
    print("=== SESUDAH PENYARINGAN (kata unik per level) ===")
    total = 0
    for lvl in ("N5", "N4", "N3", "(kosong)"):
        n = by_level.get(lvl, 0)
        total += n
        print(f"  {lvl:>8}: {n}")
    print(f"  {'TOTAL':>8}: {total}")
    print()

    lvl_words = [r for r in rows if r["level"]]
    audio = sum(1 for r in rows if r["has_audio"])
    idn = sum(1 for r in lvl_words if r["meaning_id"])
    en_only = sum(1 for r in lvl_words if not r["meaning_id"] and r["meaning_en"])
    empty = sum(1 for r in lvl_words if not r["meaning_id"] and not r["meaning_en"])
    print("=== KATA JLPT ===")
    print(f"  total kata JLPT     : {len(lvl_words)}")
    print(f"  ada rekaman utuh    : {sum(1 for r in lvl_words if r['has_audio'])}")
    print(f"  pakai TTS (tanpa)   : {sum(1 for r in lvl_words if not r['has_audio'])}")
    print(f"  ada arti Indonesia  : {idn} "
          f"({round(100*idn/max(len(lvl_words),1))}%)")
    print(f"  hanya arti Inggris  : {en_only}")
    print(f"  tanpa arti          : {empty}")
    print()
    print("=== SEMUA BARIS ===")
    print(f"  ada rekaman : {audio} / {total}")
    print(f"  TTS sisanya : {total - audio}")

    if args.stats:
        return 0

    tmp = OUT_TSV + ".tmp"
    with open(tmp, "w", encoding="utf-8", newline="\n") as f:
        for r in sorted(rows, key=lambda x: (x["level"] or "ZZZ", x["text"])):
            f.write("\t".join([
                r["text"], r["reading"], str(r["has_audio"]),
                r["meaning_id"], r["meaning_en"], r["level"], r["kanji"],
            ]) + "\n")
    os.replace(tmp, OUT_TSV)
    print(f"\ntertulis: {OUT_TSV}")
    return 0


if __name__ == "__main__":
    sys.exit(main())