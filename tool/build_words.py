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
MANUAL_FIXES_TSV = os.path.join(TOOL, "translations", "manual_fixes.tsv")

SMALL = "ゃゅょャュョ"          # boleh: digabung jadi satu huruf (きゃ)
FORBIDDEN_SMALL = "ぁぃぅぇぉァィゥェォ"  # tidak ada di data huruf app
SMALL_TSU = "っッ"
LONG_MARK = "ー"

LEVELS = [("n5.csv", "N5"), ("n4.csv", "N4"), ("n3.csv", "N3")]
LEVEL_ORDER = {"N5": 0, "N4": 1, "N3": 2}

# Batas gloss untuk memotong arti Inggris (lihat truncate_gloss).
GLOSS_BOUNDARY = re.compile(r'[;,]\s')


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


MEANING_MAX = 40


# Label gaya kamus yang tidak ada artinya bagi pengguna dan hanya bikin
# membingungkan di layar. Formatnya persis seperti di JMdict.
JMdict_LABEL = re.compile(
    r"\((?:abbr|pol|uk|oik|ksb|arch|obs|dial|hum|uk)\.\)")

WORD_ONLY_LABEL = re.compile(r"\s*\((?:[a-z]{2,12})\.\)")


def clean_gloss(text):
    """Buang label gaya kamus dari arti Inggris.

    Daftar JLPT warisan JMdict menyisipkan penanda seperti "(abbr.)" dan
    "(oik)" di dalam arti. Penanda itu tidak menjelaskan apa pun ke
    pembaca Indonesia dan hanya menambah-pollusi layar, jadi dibuang.
    """
    if not text:
        return text
    out = JMdict_LABEL.sub('', text)
    out = WORD_ONLY_LABEL.sub('', out)
    return re.sub(r'\s{2,}', ' ', out).strip()


def _parens_balanced(text):
    """Kurung buka/tutup sama banyak dan tidak menggantung di akhir."""
    return text.count('(') == text.count(')') and not text.endswith('(')


def truncate_gloss(text, limit=MEANING_MAX):
    """Potong arti Inggris di batas gloss, tidak pernah di tengah kata.

    Arti JLPT sering berupa daftar gloss: "to heat (up), to warm (up); to
    warm". Memotongnya di jumlah karakter tertentu pernah memotong kata jadi
    "to hea" atau "gener", yang membingungkan di layar.

    potongan dianggap layak kalau dua syarat ini sama-sama terpenuhi:

    1. kurung buka/tutup berpasangan dan tidak menggantung di akhir;
    2. karakter tepat sesudah potongan adalah batas kata (spasi, koma,
       titik koma, atau akhir teks), bukan huruf.

    Selama syarat belum terpenuhi, mundur ke batas gloss terdekat
    ('; ' atau ', '), atau satu kata kalau tidak ada batas gloss.
    """
    if len(text) <= limit:
        return text
    cut = text[:limit]
    while cut:
        next_ch = text[len(cut):len(cut) + 1]
        word_ok = next_ch in ('', ' ', ';', ',', ')')
        if _parens_balanced(cut) and word_ok:
            break
        bounds = list(GLOSS_BOUNDARY.finditer(cut))
        cand = ''
        if bounds:
            cand = cut[:bounds[-1].start()].rstrip(' ,;')
        if not cand:
            cand = re.sub(r"\s*\S*$", "", cut)
        if cand == cut:
            break                      # tidak ada yang bisa dipotong lagi
        cut = cand
    return cut


def load_tsv_keys(path):
    """Baca berkas "kunci TAB nilai", lewati komentar dan baris rusak.

    Dipakai bersama oleh id.tsv dan manual_fixes.tsv supaya keduanya punya
    aturan baca yang sama.
    """
    if not os.path.isfile(path):
        return {}
    result = {}
    for line in open(path, encoding="utf-8"):
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


def load_indo():
    """Baca tool/translations/id.tsv (romaji TAB arti Indonesia).

    Berkas ini boleh diisi sebagian: kata yang belum diterjemahkan memakai
    arti Inggris sebagai cadangan (lihat DOKUMENTASI.md bagian 6).
    """
    return load_tsv_keys(INDO_TSV)


def load_manual_fixes():
    """Baca tool/translations/manual_fixes.tsv.

    Isi koreksi manual yang diperiksa tangan, keyed dengan KATA KANA (bukan
    romaji). Diterapkan TERAKHIR, sesudah id.tsv, supaya koreksi ini tidak
    pernah tertimpa kalau id.tsv dibangun ulang atau diterjemahkan ulang.
    """
    return load_tsv_keys(MANUAL_FIXES_TSV)


# -------------------------------------------------------------------- main

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--stats", action="store_true",
                    help="hanya tampilkan statistik, jangan tulis berkas")
    ap.add_argument("--out", default=None,
                    help="tulis ke berkas lain (dipakai test untuk membandingkan "
                         "keluaran pipeline dengan assets/data/words.tsv)")
    args = ap.parse_args()

    global table
    table = load_kana()
    if not table:
        raise SystemExit("gagal membaca kana_data.dart")

    jlpt_list, raw_stats = load_jlpt()
    old = load_old_pool()
    indo = load_indo()
    manual_fixes = load_manual_fixes()
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

    # Koreksi manual diterapkan TERAKHIR: menimpa apa pun hasil terjemahan
    # otomatis, supaya koreksi yang sudah diperiksa tangan tidak hilang
    # ketika id.tsv dibangun ulang.
    applied = 0
    unknown = []
    for r in rows:
        fix = manual_fixes.get(r["text"])
        if fix is None:
            continue
        if r["meaning_id"] != fix:
            applied += 1
        r["meaning_id"] = fix
    for key in manual_fixes:
        if key not in {r["text"] for r in rows}:
            unknown.append(key)
    if unknown:
        print(f"PERINGATAN: {len(unknown)} koreksi manual tidak cocok "
              f"dengan kata mana pun: {', '.join(sorted(unknown)[:5])}",
              file=sys.stderr)

    for r in rows:
        r["has_audio"] = 1 if has_audio(r["reading"]) else 0
        r["meaning_en"] = truncate_gloss(clean_gloss(r["meaning_en"]))
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

    out = args.out or OUT_TSV
    tmp = out + ".tmp"
    with open(tmp, "w", encoding="utf-8", newline="\n") as f:
        for r in sorted(rows, key=lambda x: (x["level"] or "ZZZ", x["text"])):
            f.write("\t".join([
                r["text"], r["reading"], str(r["has_audio"]),
                r["meaning_id"], r["meaning_en"], r["level"], r["kanji"],
            ]) + "\n")
    os.replace(tmp, out)
    print(f"\ntertulis: {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())