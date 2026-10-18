#!/usr/bin/env python3
"""Membangun kosakata kurasi -> assets/data/words.tsv.

Membaca tools/vocab_source.txt, memeriksa setiap kata (hanya kana yang dikenal
app, tidak campur hiragana/katakana, arti Indonesia wajib ada), menghitung cara
baca, lalu menggabungkannya ke words.tsv TANPA menghapus kata lama:
  - kata yang sudah ada di words.tsv  -> diperbarui (arti, level, kategori)
  - kata baru                         -> ditambahkan di akhir file

Format baris words.tsv (dipisah TAB):
  kata, cara-baca, audio(0/1), arti, level, kategori
Baris lama hanya 4 kolom; app tetap bisa membacanya.

Pakai:  python3 tools/build_vocab.py            (tulis words.tsv)
        python3 tools/build_vocab.py --check    (hanya memeriksa, tidak menulis)
Laporan JSON ditulis ke tools/out/vocab_report.json.
"""
import json
import sys
from collections import Counter, OrderedDict
from pathlib import Path

from vocab_lib import (LEVELS, ROOT, load_kana, parse, romaji_of, scripts_of)

SOURCE = ROOT / "tools/vocab_source.txt"
WORDS = ROOT / "assets/data/words.tsv"
AUDIO = ROOT / "assets/audio/words"
OUT = ROOT / "tools/out"


def read_source(kana):
    items, problems, seen = [], [], {}
    level = cat = None
    for no, raw in enumerate(SOURCE.read_text(encoding="utf-8").split("\n"), 1):
        line = raw.strip()
        if not line or line.startswith("#") and not line.startswith("##"):
            continue
        if line.startswith("##"):
            lv, ct = [s.strip() for s in line[2:].split("|")]
            if lv not in LEVELS:
                problems.append(f"baris {no}: level tidak dikenal '{lv}'")
            level, cat = lv, ct
            continue
        if "|" not in line:
            problems.append(f"baris {no}: format salah: {line!r}")
            continue
        text, meaning = [s.strip() for s in line.split("|", 1)]
        pieces = parse(text, kana)
        if pieces is None:
            problems.append(f"baris {no}: karakter tak dikenal app: {text}")
            continue
        if not meaning:
            problems.append(f"baris {no}: arti Indonesia kosong: {text}")
            continue
        if len(scripts_of(pieces)) != 1:
            problems.append(f"baris {no}: campur hiragana/katakana: {text}")
            continue
        if "を" in text or "ヲ" in text:
            problems.append(f"baris {no}: mengandung を (partikel): {text}")
            continue
        if text in seen:
            problems.append(
                f"baris {no}: duplikat '{text}' (sudah ada di {seen[text]}), dilewati")
            continue
        seen[text] = f"{level}/{cat}"
        items.append(dict(text=text, reading=romaji_of(pieces),
                          level=level, category=cat, meaning=meaning))
    return items, problems


def main():
    check_only = "--check" in sys.argv
    kana = load_kana()
    assert len(kana) >= 200, f"tabel huruf terbaca {len(kana)} (harusnya 208)"
    items, problems = read_source(kana)

    lines = WORDS.read_text(encoding="utf-8").split("\n")
    trailing_nl = lines and lines[-1] == ""
    if trailing_nl:
        lines.pop()
    index = OrderedDict()
    for i, ln in enumerate(lines):
        index.setdefault(ln.split("\t")[0], i)

    updated, added, meaning_changed = 0, 0, []
    new_lines = []
    for it in items:
        # Kalau kata sudah ada, pakai cara baca lama supaya nama file audio lama tetap cocok.
        if it["text"] in index:
            old_reading = lines[index[it["text"]]].split("\t")[1]
            if old_reading != it["reading"]:
                problems.append(f"cara baca lama dipertahankan: {it['text']} "
                                f"{old_reading} (hitungan app: {it['reading']})")
                it["reading"] = old_reading
        have_audio = (AUDIO / f"{it['reading']}.mp3").exists() and \
                     (AUDIO / f"{it['reading']}_slow.mp3").exists()
        row = "\t".join([it["text"], it["reading"], "1" if have_audio else "0",
                         it["meaning"], it["level"], it["category"]])
        if it["text"] in index:
            i = index[it["text"]]
            old = lines[i].split("\t")
            if len(old) > 3 and old[3] and old[3] != it["meaning"]:
                meaning_changed.append((it["text"], old[3], it["meaning"]))
            lines[i] = row
            updated += 1
        else:
            new_lines.append(row)
            added += 1
    lines += new_lines

    by_level = Counter(i["level"] for i in items)
    by_cat = Counter((i["level"], i["category"]) for i in items)
    need_audio = sorted({i["reading"] for i in items
                         if not ((AUDIO / f"{i['reading']}.mp3").exists() and
                                 (AUDIO / f"{i['reading']}_slow.mp3").exists())})
    report = dict(
        total_curated=len(items), added_new_rows=added, updated_existing_rows=updated,
        by_level=dict(by_level),
        by_category={f"{k[0]} / {k[1]}": v for k, v in by_cat.items()},
        meaning_overridden=[dict(kata=a, lama=b, baru=c) for a, b, c in meaning_changed],
        readings_needing_audio=len(need_audio), problems=problems)
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "vocab_report.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")

    if not check_only:
        WORDS.write_text("\n".join(lines) + ("\n" if trailing_nl else ""),
                         encoding="utf-8")
    print(f"kata kurasi      : {len(items)}")
    print(f"baris baru       : {added}   diperbarui: {updated}")
    for lv, n in sorted(by_level.items()):
        print(f"  {LEVELS[lv]:6} : {n}")
    for (lv, ct), n in by_cat.items():
        print(f"    {LEVELS[lv]:6} {ct:12} {n}")
    print(f"perlu audio baru : {len(need_audio)} cara baca")
    if problems:
        print(f"\nPERINGATAN ({len(problems)}):")
        for p in problems:
            print("  -", p)
    print("\n(--check: words.tsv TIDAK ditulis)" if check_only
          else "\nwords.tsv diperbarui.")
    return 1 if any("tak dikenal" in p or "kosong" in p or "campur" in p
                    for p in problems) else 0


if __name__ == "__main__":
    sys.exit(main())
