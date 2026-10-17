#!/usr/bin/env python3
"""Audit arti Indonesia di assets/data/words.tsv.

Menandai baris yang perlu diperiksa manusia dan menulisnya ke
tool/translations/review.tsv (kata, arti-indo, arti-inggris, alasan).

Pemeriksaan yang dijalankan:

  sama      arti Indonesia identik dengan arti Inggris -> belum diterjemahkan
  label     ada label gaya kamus JMdict: (abbr.), (pol.), dan sejenisnya
  panjang   arti Indonesia lebih dari 35 karakter
  gloss     arti Inggris punya beberapa makna tapi arti Indonesia hanya satu
            -> mungkin belum semuanya tertangkap
  kosong    kata JLPT tanpa arti Indonesia
  trunc     arti Inggris terpotong di tengah kata

CATATAN SOAL PEMERIKSAAN EJAAN (langkah 1a)
--------------------------------------------
Pemeriksaan ejaan otomatis terhadap daftar kata baku TIDAK dijalankan.
Alasannya:

  * Tidak ada kamus bahasa Indonesia dengan lisensi yang bisa dipastikan
    tersedia luring di mesin ini.
  * Paket `nlp-id` (MIT) memang menyertakan lemma korpus IDN-Coarse
    (778.514 entri), tapi itu artefak korpus riset, bukan daftar kata baku:
    isinya memuat banyak bukan-kata seperti "berdap" dan "membogeli".
    Sumbernya tidak screamed lisensi yang jelas, jadi tidak dipakai sebagai
    acuan.
  * `espeak-ng-data/id_dict` itu kamus pelafalan (GPL), bukan daftar kata.

Sebagai gantinya, `--lemma-file` bisa diberi daftar lemma untuk dipakai
hanya sebagai PETUNJUK kandidat (bukan acuan benar/salah) supaya curvature
dari "${kata}${kata}${kata}${kata}" gibi token aneh lebih mudah terlihat.
Berkas seperti itu tidak disimpan di repo.

Pemeriksaan ejaan yang dipakai di laporan ini: kalau ada token yang tidak
ada di daftar Petunjuk, token itu tetap ditulis ke review.tsv supaya
diperiksa orang, bukan diperbaiki otomatis.
"""
import argparse
import csv
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WORDS_TSV = os.path.join(ROOT, "assets", "data", "words.tsv")
REVIEW_TSV = os.path.join(TOOL_REVIEW := os.path.join(
    ROOT, "tool", "translations", "review.tsv"))
WHITELIST = os.path.join(ROOT, "tool", "translations", "whitelist.txt")

JLPT_LEVELS = ("N5", "N4", "N3")
MEANING_MAX = 35

# Label gaya kamus. Semuanya tidak menjelaskan apa pun ke pembaca.
LABEL = re.compile(r"\((?:abbr|pol|uk|oik|ksb|arch|obs|dial|hum)\.\)")

# Batas gloss untuk mendeteksi arti Inggris yang terpotong.
GLOSS = re.compile(r"[;,]\s")

# Serapan dan nama diri yang sah tetap sama dalam bahasa Indonesia.
DEFAULT_WHITELIST = """
album hotel radio data internet computer software hardware printer scanner
mouse keyboard monitor server browser laptop notebook modem
asia europe america afrika australia jepang china korea india mesir
tokyo osaka kyoto jakarta bandung surabaya medan semarang makassar
inggris prancis spanyol jerman belanda tiongkok rusia kanada meksiko
brasil argentina turki arab saudi dirsiah uni uni Arab
ac tv dvd hq sms url pdf usb sim gsm cd mp3 dvd
sma smp sd smm sma negri pt cv tbk
spbu bpom bpjt dpr mpr explore
"""


def load_whitelist():
    words = set(DEFAULT_WHITELIST.split())
    if os.path.isfile(WHITELIST):
        for line in open(WHITELIST, encoding="utf-8"):
            line = line.strip().lower()
            if line and not line.startswith("#"):
                words.add(line)
    return words


def load_words():
    rows = []
    for line in open(WORDS_TSV, encoding="utf-8"):
        line = line.rstrip("\n")
        if not line.strip():
            continue
        c = (line.split("\t") + [""] * 7)[:7]
        rows.append({
            "text": c[0], "reading": c[1], "has_audio": c[2],
            "meaning_id": c[3], "meaning_en": c[4],
            "level": c[5], "kanji": c[6],
        })
    return rows


def load_source_glosses():
    """Arti Inggris penuh dari tool/data/*.csv (untuk deteksi terpotong)."""
    src = {}
    for name in ("n5", "n4", "n3"):
        path = os.path.join(ROOT, "tool", "data", f"{name}.csv")
        if not os.path.isfile(path):
            continue
        with open(path, encoding="utf-8") as fh:
            for row in csv.DictReader(fh):
                reading = (row.get("reading") or "").strip()
                meaning = (row.get("meaning") or "").strip()
                if reading and meaning:
                    src.setdefault(reading, meaning)
    return src


def load_lemma_hint(path):
    """Daftar kata dari Petunjuk (opsional, hanya untuk menandai kandidat)."""
    if not path or not os.path.isfile(path):
        return None
    words = set()
    for line in open(path, encoding="utf-8"):
        w = line.strip().lower()
        if w:
            words.add(w)
            # juga bentuk akar untuk prefiks/sufiks yang lazim
            for p in ("meng", "meny", "mem", "men", "me", "ber", "per",
                      "ter", "di", "pe", "pen", "peng", "pem", "peny",
                      "ke", "se", "ber", "di"):
                if w.startswith(p) and len(w) - len(p) > 2:
                    words.add(w[len(p):])
    return words


def audit(rows, src_glosses, whitelist, lemma):
    """Kembalikan {(kata): [alasan, ...]} plus statistik per alasan."""
    flags = {}
    stats = {}

    def flag(row, reason):
        flags.setdefault(row["text"], []).append(reason)
        stats[reason] = stats.get(reason, 0) + 1

    # Makna yang mungkin tidak lengkap: arti Inggris memuat beberapa gloss
    # (';' atau ', ' sebagai pemisah) tapi arti Indonesia hanya satu butir.
    #
    # Catatan: TIDAK memakai tabrakan cara baca sebagai sinyal. クラス "kelas"
    # dan くらす "hidup" memang dua kata berbeda yang kebetulan sama-sama
    # dibaca "kurasu"; menyatukan artinya jadi salah.

    for r in rows:
        indo = r["meaning_id"].strip()
        en = r["meaning_en"].strip()
        is_jlpt = r["level"] in JLPT_LEVELS

        if is_jlpt and not indo:
            flag(r, "kosong")

        if indo and len(indo) > MEANING_MAX:
            flag(r, "panjang")

        if LABEL.search(indo) or LABEL.search(en):
            flag(r, "label")

        # b: identik dengan Inggris. Kata ulang inggris yang sah ada di
        # whitelist, sisanya berarti belum diterjemahkan.
        if indo and indo == en and indo.lower() not in whitelist:
            flag(r, "sama")

        # d: arti Inggris terpotong di tengah kata
        full = src_glosses.get(r["reading"])
        if full and en and full != en and full.startswith(en):
            nxt = full[len(en):len(en) + 1]
            if not (en.endswith(" ") or nxt in ("", " ", ";", ",", ")")):
                flag(r, "trunc")

        # e: makna yang mungkin belum lengkap.
        # Hanya pemisah ';' yang dipakai. Daftar Tanos memakai ';' untuk
        # makna yang benar-benar berbeda ("to finish; to put away") dan ','
        # untuk sinonim ("big, large, great"). Kalau ',' ikut dihitung,
        # hampir semua kata N5 terbaca janggal padahal translate-nya benar
        # karena sinonim memang diringkas jadi satu kata Indonesia.
        if is_jlpt and indo and en:
            n_sense = len([g for g in en.split(";") if g.strip()])
            n_indo = len([g for g in indo.split(",") if g.strip()])
            if n_sense >= 2 and n_indo == 1:
                flag(r, "gloss")

        # Petunjuk token asing (opsional, tidak baku)
        if lemma and indo:
            for tok in re.split(r"[^A-Za-z]+", indo.lower()):
                if len(tok) < 3 or tok in whitelist:
                    continue
                if tok not in lemma:
                    flag(r, "token")
                    break
    return flags, stats


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--lemma-file", default=None,
                    help="daftar kata Petunjuk; hanya menandai kandidat, "
                         "bukan acuan benar/salah")
    ap.add_argument("--out", default=REVIEW_TSV)
    args = ap.parse_args()

    rows = load_words()
    src = load_source_glosses()
    wl = load_whitelist()
    lemma = load_lemma_hint(args.lemma_file)

    flags, stats = audit(rows, src, wl, lemma)

    jlpt = [r for r in rows if r["level"] in JLPT_LEVELS]
    with open(args.out, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("# kata\tarti-indonesia\tarti-inggris\talasan\n")
        for r in jlpt:
            if r["text"] in flags:
                fh.write("\t".join([
                    r["text"], r["meaning_id"], r["meaning_en"],
                    ",".join(flags[r["text"]]),
                ]) + "\n")

    print(f"kata JLPT diperiksa : {len(jlpt)}")
    print(f"baris ditandai      : {len([r for r in jlpt if r['text'] in flags])}"
          f"  -> {args.out}")
    print("per alasan:")
    for reason, n in sorted(stats.items(), key=lambda x: -x[1]):
        print(f"  {reason:10} {n}")
    if lemma is None:
        print("\nCatatan:Pemeriksaan ejaan otomatis TIDAK dijalankan "
              "(tidak ada daftar kata baku berlisensi jelas).")
    else:
        print(f"\nPetunjuk token memakai {args.lemma_file}; hasilnya "
              "kandidat, bukan vonis benar/salah.")
    return 0


if __name__ == "__main__":
    sys.exit(main())