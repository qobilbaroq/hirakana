#!/usr/bin/env python3
"""Gabungkan berkas batch terjemahan ke tool/translations/id.tsv.

Dipakai karena beberapa batch bisa tidak berakhir dengan newline; kalau
dipakai `cat` baris terakhir dan baris pertama akan menempel.
"""
import glob
import os
import re
import sys

TOOL = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                    "tool")
OUT = os.path.join(TOOL, "translations", "id.tsv")

# Kunci harus romaji ASCII. Batch lama masih ada sisa kana; kalau ikut
# terbawa cuma jadi baris mati karena build_words mencari lewat romaji.
KEY_RE = re.compile(r"^[a-z]+(#\d+)?$")

HEADER = ("# Terjemahan Bahasa Indonesia untuk kosakata JLPT.\n"
          "# Format: kunci romaji TAB arti Indonesia.\n"
          "# Kunci bentrok memakai suffix #2 (lihat tool/translations/keys.tsv).\n"
          "# Kata yang tidak ada di sini memakai arti Inggris sebagai cadangan.\n")


def main():
    sources = sys.argv[1:] or sorted(glob.glob("/tmp/opencode/b*.tsv"))
    lines = {}
    for src in sources:
        for raw in open(src, encoding="utf-8"):
            raw = raw.strip("\n").rstrip()
            if not raw.strip() or raw.lstrip().startswith("#"):
                continue
            parts = raw.split("\t")
            if len(parts) < 2:
                print(f"LEWATI (baris rusak): {src}: {raw!r}", file=sys.stderr)
                continue
            key = parts[0].strip()
            indo = "\t".join(parts[1:]).strip()
            if not indo:
                continue
            if not KEY_RE.match(key):
                print(f"LEWATI (kunci bukan romaji): {src}: {key!r}",
                      file=sys.stderr)
                continue
            if key in lines and lines[key] != indo:
                print(f"PERINGATAN: duplikat {key}: "
                      f"{lines[key]!r} != {indo!r}", file=sys.stderr)
            lines[key] = indo
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write(HEADER)
        for key in sorted(lines):
            f.write(f"{key}\t{lines[key]}\n")
    print(f"{len(lines)} terjemahan -> {OUT}")


if __name__ == "__main__":
    main()