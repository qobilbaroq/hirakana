#!/usr/bin/env python3
"""Ambil sampel acak kata JLPT untuk diperiksa ulang oleh manusia.

Seed-nya tetap supaya hasilnya bisa direproduksi: dipakai ulang setiap kali
audit dijalankan, sehingga daftar yang di unsure.tsv tidak bergeser.

Jalankan:
    python3 tool/sample_audit.py            # tulis tool/translations/sample.tsv
    python3 tool/sample_audit.py --show     # tampilkan di layar
"""
import argparse
import csv
import os
import random

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WORDS_TSV = os.path.join(ROOT, "assets", "data", "words.tsv")
OUT_TSV = os.path.join(ROOT, "tool", "translations", "sample.tsv")

SEED = 20261018
QUOTA = {"N5": 40, "N4": 30, "N3": 30}


def load_jlpt():
    rows = []
    for line in open(WORDS_TSV, encoding="utf-8"):
        line = line.rstrip("\n")
        if not line.strip():
            continue
        c = (line.split("\t") + [""] * 7)[:7]
        if c[5] in QUOTA:
            rows.append({
                "text": c[0], "reading": c[1], "meaning_id": c[3],
                "meaning_en": c[4], "level": c[5], "kanji": c[6],
            })
    return rows


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--show", action="store_true")
    args = ap.parse_args()

    by_level = {"N5": [], "N4": [], "N3": []}
    for r in load_jlpt():
        by_level[r["level"]].append(r)

    rng = random.Random(SEED)
    sample = []
    for level in ("N5", "N4", "N3"):       # urutan tetap, bukan urutan dict
        pool = sorted(by_level[level], key=lambda x: x["text"])
        n = QUOTA[level]
        if len(pool) < n:
            raise SystemExit(f"{level}: hanya {len(pool)} kata, kurang dari {n}")
        sample.extend(rng.sample(pool, n))

    with open(OUT_TSV, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("# sampel audit, seed tetap. "
                 "Kolom 'catat' diisi manual saat pemeriksaan.\n")
        fh.write("# kata\tbacaan\tlevel\tkanji\tarti-indonesia\t"
                 "arti-inggris\tcatat\n")
        for r in sample:
            fh.write("\t".join([
                r["text"], r["reading"], r["level"], r["kanji"],
                r["meaning_id"], r["meaning_en"], "",
            ]) + "\n")

    print(f"seed {SEED}, {len(sample)} kata -> {OUT_TSV}")
    if args.show:
        for r in sample:
            mark = "  <-- perlu dicek" if r["text"] in _unsure_keys() else ""
            print(f'{r["text"]:<12} {r["reading"]:<13} {r["level"]}  '
                  f'{r["meaning_id"]:<26} {r["meaning_en"][:36]}{mark}')


def _unsure_keys():
    p = os.path.join(ROOT, "tool", "translations", "uncertain.tsv")
    if not os.path.isfile(p):
        return set()
    out = set()
    for line in open(p, encoding="utf-8"):
        if line.startswith("#") or not line.strip():
            continue
        out.add(line.split("\t")[0])
    return out


if __name__ == "__main__":
    main()