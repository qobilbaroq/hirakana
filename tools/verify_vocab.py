#!/usr/bin/env python3
"""Verifikasi kosakata berkelompok tanpa Flutter. Cerminan dari test/vocab_groups_test.dart.

Pakai:  python3 tools/verify_vocab.py
Keluar kode 0 kalau semua lolos, 1 kalau ada masalah. Ringkasan dicetak ke layar
dan ditulis ke tools/out/verify_report.json (dipakai untuk laporan kerja).
"""
import json
import sys
from collections import Counter

from vocab_lib import LEVELS, ROOT, load_kana, parse, scripts_of

WORDS = ROOT / "assets/data/words.tsv"
AUDIO = ROOT / "assets/audio/words"


def main():
    kana = load_kana()
    total, curated, problems = 0, [], []
    for no, ln in enumerate(WORDS.read_text(encoding="utf-8").split("\n"), 1):
        if not ln.strip():
            continue
        c = ln.split("\t")
        if len(c) < 3:
            problems.append(f"baris {no}: kolom kurang")
            continue
        total += 1
        if len(c) > 4 and c[4]:
            curated.append((no, c))
    seen = set()
    for no, c in curated:
        text, reading, audio, meaning = c[0], c[1], c[2], c[3] if len(c) > 3 else ""
        level, cat = c[4], c[5] if len(c) > 5 else ""
        if level not in LEVELS:
            problems.append(f"baris {no}: tingkat tak dikenal {level!r} ({text})")
        if not cat:
            problems.append(f"baris {no}: kategori kosong ({text})")
        if not meaning:
            problems.append(f"baris {no}: arti Indonesia kosong ({text})")
        pieces = parse(text, kana)
        if pieces is None:
            problems.append(f"baris {no}: karakter tak dikenal app ({text})")
        elif len(scripts_of(pieces)) != 1:
            problems.append(f"baris {no}: campur script ({text})")
        if audio != "1":
            problems.append(f"baris {no}: kolom audio bukan 1 ({text})")
        for suffix in ("", "_slow"):
            if not (AUDIO / f"{reading}{suffix}.mp3").exists():
                problems.append(f"baris {no}: file hilang {reading}{suffix}.mp3 ({text})")
        if text in seen:
            problems.append(f"baris {no}: kata ganda ({text})")
        seen.add(text)

    by_level = Counter(c[4] for _, c in curated)
    by_cat = Counter((c[4], c[5]) for _, c in curated)
    files = list(AUDIO.glob("*.mp3"))
    report = dict(
        total_baris_words_tsv=total, kata_kurasi=len(curated),
        per_tingkat={LEVELS.get(k, k): v for k, v in by_level.items()},
        per_kategori={f"{LEVELS.get(k[0], k[0])} / {k[1]}": v for k, v in by_cat.items()},
        file_audio_kata=len(files),
        ukuran_audio_kata_mb=round(sum(f.stat().st_size for f in files) / 1e6, 1),
        masalah=problems)
    out = ROOT / "tools/out"
    out.mkdir(parents=True, exist_ok=True)
    (out / "verify_report.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")

    print(f"baris words.tsv       : {total}")
    print(f"kata kurasi berkelompok: {len(curated)}")
    for k, v in sorted(by_level.items()):
        print(f"  {LEVELS.get(k, k):6}: {v}")
    for (lv, ct), n in by_cat.items():
        print(f"    {LEVELS.get(lv, lv):6} {ct:12} {n}")
    print(f"file audio kata       : {len(files)} ({report['ukuran_audio_kata_mb']} MB)")
    print(f"masalah               : {len(problems)}")
    for p in problems[:50]:
        print("  -", p)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
