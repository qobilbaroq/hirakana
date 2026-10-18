#!/usr/bin/env python3
"""Satu kali: masukkan 412 kata yang belum ber-level ke tools/vocab_source.txt.

Membaca tools/level_map.tsv (tingkat + kategori) lalu mengambil arti PERSIS dari
assets/data/words.tsv. Kata dengan (tingkat, kategori) yang sudah ada di
vocab_source.txt disisipkan ke bagian itu; yang benar-benar baru dibuat
bagian baru di akhir berkas.

Tidak ada kana yang diketik tangan di sini, jadi tidak mungkin salah ketik.
Idempoten: jalan dua kali tidak menambah apa pun.
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
WORDS = ROOT / "assets/data/words.tsv"
MAP = ROOT / "tools/level_map.tsv"
SOURCE = ROOT / "tools/vocab_source.txt"

# arti dari words.tsv, apa adanya
meaning = {}
for line in WORDS.read_text(encoding="utf-8").split("\n"):
    if not line.strip():
        continue
    c = line.split("\t")
    if len(c) > 3 and c[3].strip():
        meaning[c[0]] = c[3].strip()

# peta: kata -> (tingkat, kategori)
peta = {}
for line in MAP.read_text(encoding="utf-8").split("\n"):
    if not line.strip() or line.startswith("#"):
        continue
    kata, level, cat = line.split("\t")
    if kata not in meaning:
        raise SystemExit(f"BUG: '{kata}' tidak ada di words.tsv")
    if kata in peta:
        raise SystemExit(f"BUG: '{kata}' dobel di level_map.tsv")
    peta[kata] = (level, cat)

# pecah vocab_source.txt jadi bagian [(header, [baris...])]
parts, cur, buf = [], None, []
for line in SOURCE.read_text(encoding="utf-8").split("\n"):
    if line.startswith("## "):
        if cur is not None:
            parts.append((cur, buf))
        cur, buf = line[3:].strip(), []
    elif cur is not None and line.strip() and not line.startswith("#"):
        buf.append(line)
if cur is not None:
    parts.append((cur, buf))

# kandidat per bagian: hanya kata yang BELUM ada di berkas
existing = {l.split("|", 1)[0].strip() for _, buf in parts for l in buf}
add = {}
for kata, (lvl, cat) in peta.items():
    if kata in existing:
        continue
    add.setdefault((lvl, cat), []).append(kata)

# sisipkan ke bagian yang cocok; buat bagian baru kalau tidak ada
used = set()
for header, _ in parts:
    used.add(header)

new_parts, created = [], []
for kata_list in add.values():
    pass

# 1) sisipkan ke bagian yang sudah ada
for i, (header, buf) in enumerate(parts):
    key = tuple(x.strip() for x in header.split("|", 1))
    extra = add.pop(key, None)
    if extra:
        buf = list(buf) + [f"{k}|{meaning[k]}" for k in extra]
    new_parts.append((header, buf))

# 2) sisipkan ke bagian yang belum ada
for (lvl, cat), klist in add.items():
    if not klist:
        continue
    header = f"{lvl} | {cat}"
    created.append((header, len(klist)))
    new_parts.append((header, [f"{k}|{meaning[k]}" for k in klist]))

out = []
for header, buf in new_parts:
    out.append(f"## {header}")
    out.extend(buf)
    out.append("")
text = ("# Kosakata kurasi Kana Quest (ditulis tangan, hanya kana).\n"
        "# Format: kana|arti Indonesia. Header: ## <level> | <Kategori>\n"
        "# level: n5n4 (N5-N4) atau n3. Cara baca (romaji) dihitung otomatis oleh build_vocab.py.\n\n")
text += "\n".join(out).rstrip() + "\n"
SOURCE.write_text(text, encoding="utf-8")

total = sum(len(buf) for _, buf in new_parts)
print(f"kata di peta        : {len(peta)}")
print(f"sudah ada di berkas: {len(peta) - sum(len(v) for v in add.values())}")
print(f"baru ditambahkan   : {sum(len(v) for v in add.values())}")
print(f"total entri berkas : {total}")
print(f"bagian baru        : {len(created)}")
for h, n in created:
    print(f"   {h:<28} {n:>4} kata")