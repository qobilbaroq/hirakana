#!/usr/bin/env python3
"""Buat suara HURUF (104 berkas x 2 kecepatan) dengan Open JTalk + tohoku-f01.

Membaca tools/letter_audio_source.tsv. Setiap huruf memakai teks pada kolom
tts_input, yang sudah diberi vokal あ di belakang supaya suaranya tidak
terlalu pendek (huruf tunggal hasil sintesis cuma ~0,28 detik).

Keluaran:
  assets/audio/<romaji>.mp3        normal  (atempo=0.75)
  assets/audio/slow/<romaji>.mp3   lambat  (atempo=0.58)

PENGATURAN DURASI (hasil eksperimen, lihat tools/out/letter_audio_report.json):
  Durasi huruf hasil sintesis apa adanya hanya ~0,52 detik, jauh lebih pendek
  dari rekaman manusia yang lama (rata-rata 1,21 detik) dan masih pendek dari
  file kata terpendek di repo (0,63 detik). Karena itu:
    - laju bicara diturunkan (atempo), supaya huruf terdengar jelas
    - jeda di ujung (apad) diperpanjang, supaya tidak terpotong

Syarat:
  - open_jtalk di PATH
  - ffmpeg
  - kamus open_jtalk_dic_utf_8-1.11
  - tohoku-f01-neutral.htsvoice dari https://github.com/icn-lab/htsvoice-tohoku-f01

Pakai:
  python3 tools/generate_letter_audio.py \
      --dic ~/tts/open_jtalk_dic_utf_8-1.11 \
      --voice ~/tts/htsvoice-tohoku-f01/tohoku-f01-neutral.htsvoice
  --only a,ka,wo,n,ja   hanya huruf tertentu (tes cepat)
  --force               buat ulang walau berkas sudah ada
"""
import argparse
import csv
import json
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

TSV = ROOT / "tools/letter_audio_source.tsv"
OUT = ROOT / "tools/out"

PEAK_DB = -1.5
# atempo, pad (detik) untuk tiap kecepatan
TUNING = {"normal": (0.75, 0.38), "slow": (0.58, 0.45)}


def run(cmd, **kw):
    return subprocess.run(cmd, check=True, capture_output=True, **kw)


def peak_db(path):
    p = subprocess.run(["ffmpeg", "-hide_banner", "-i", str(path),
                        "-af", "volumedetect", "-f", "null", "-"],
                       capture_output=True, text=True)
    m = re.search(r"max_volume:\s*(-?[\d.]+) dB", p.stderr)
    return float(m.group(1)) if m else 0.0


def synth_wav(text, dic, voice, wav):
    run(["open_jtalk", "-x", dic, "-m", voice, "-r", "1.0", "-ow", str(wav)],
        input=text.encode("utf-8"))


def process(wav_in, mp3_out, atempo, pad):
    chain = ("silenceremove=start_periods=1:start_threshold=-50dB"
             ":stop_periods=-1:stop_threshold=-50dB")
    if atempo != 1.0:
        chain += f",atempo={atempo}"
    chain += f",adelay=100:all=1,apad=pad_dur={pad}"
    with tempfile.TemporaryDirectory() as td:
        tmp = Path(td) / "tmp.wav"
        run(["ffmpeg", "-loglevel", "error", "-y", "-i", str(wav_in),
             "-af", chain, "-ar", "22050", "-ac", "1", str(tmp)])
        gain = PEAK_DB - peak_db(tmp)
        run(["ffmpeg", "-loglevel", "error", "-y", "-i", str(tmp),
             "-af", f"volume={gain:.2f}dB", "-ar", "22050", "-ac", "1",
             "-c:a", "libmp3lame", "-b:a", "32k", str(mp3_out)])


def load_rows(path):
    """Header TSV ditulis sebagai baris komentar yang diawali '#'."""
    raw = Path(path).read_text(encoding="utf-8").splitlines()
    header, data = None, []
    for line in raw:
        if not line.strip():
            continue
        if line.startswith("#"):
            body = line.lstrip("#").strip()
            if body.startswith("romaji\t"):
                header = body
            continue
        data.append(line)
    if header is None:
        raise SystemExit("Header 'romaji<TAB>grup<TAB>...' tidak ditemukan di TSV")
    return list(csv.DictReader([header] + data, delimiter="\t"))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dic", required=True)
    ap.add_argument("--voice", required=True)
    ap.add_argument("--tsv", default=str(TSV))
    ap.add_argument("--out", default=str(ROOT / "assets/audio"))
    ap.add_argument("--only", default="")
    ap.add_argument("--alt", action="store_true",
                    help="pakai kolom tts_alt (versi pakai jeda)")
    ap.add_argument("--force", action="store_true")
    args = ap.parse_args()

    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    (out / "slow").mkdir(exist_ok=True)
    only = {s.strip() for s in args.only.split(",") if s.strip()}
    col = "tts_alt" if args.alt else "tts_input"

    rows = load_rows(args.tsv)
    ok, skipped, failed, dur, ditahan = 0, 0, [], [], []

    for r in rows:
        name = r["romaji"]
        if only and name not in only:
            continue
        dest_n = out / f"{name}.mp3"
        dest_s = out / "slow" / f"{name}.mp3"

        # ぢ dan づ TIDAK bisa disintesis dengan benar: kamus naist-jdic hanya
        # punya pembacaan "ji" / "zu" untuk kana tunggal, sedangkan yang benar
        # adalah "di" dan "du" (lihat うちこむ / つづける di kamus). Semua ejaan
        # lain tetap menghasilkan "ji"/"zu", termasuk katakana, jadi tidak ada
        # trik penulisan yang-working. Dua huruf ini mempertahankan rekaman
        # manusia yang lama.
        if r[col].strip() == "(tetap)":
            ditahan.append(name)
            if not args.force and dest_n.exists() and dest_s.exists():
                print(f"[TAHAN] {name:5s} {r['hiragana']} -> rekaman lama "
                      f"dipertahankan (tidak bisa disintesis)")
                continue

        if not args.force and dest_n.exists() and dest_s.exists():
            skipped += 1
            continue
        try:
            with tempfile.TemporaryDirectory() as td:
                wav = Path(td) / "raw.wav"
                synth_wav(r[col], args.dic, args.voice, wav)
                at, pd = TUNING["normal"]
                process(wav, dest_n, at, pd)
                at, pd = TUNING["slow"]
                process(wav, dest_s, at, pd)
            d = float(run(["ffprobe", "-v", "error", "-show_entries",
                           "format=duration", "-of", "csv=p=0",
                           str(dest_n)]).stdout.strip())
            dur.append(d)
            ok += 1
            print(f"[OK] {name:5s} {r['hiragana']} {r[col]:<6} "
                  f"{d:.3f} dtk")
        except subprocess.CalledProcessError as e:
            failed.append(name)
            print(f"[GAGAL] {name}: "
                  f"{e.stderr.decode(errors='ignore')[:200]}", file=sys.stderr)

    report = dict(
        jumlah_berhasil=ok, jumlah_dilewati=skipped, gagal=failed,
        huruf_ditahan_rekaman_lama=sorted(ditahan),
        kolom_dipakai=col,
        rata2_durasi_normal_detik=round(sum(dur) / len(dur), 3) if dur else None,
        min_durasi_detik=round(min(dur), 3) if dur else None,
        max_durasi_detik=round(max(dur), 3) if dur else None)
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "letter_audio_report.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")

    print(f"\nSelesai: {ok} dibuat, {skipped} dilewati, {len(failed)} gagal")
    if ditahan:
        print(f"Ditahan (pakai rekaman lama): {sorted(ditahan)}")
    if dur:
        print(f"Durasi normal: rata-rata {report['rata2_durasi_normal_detik']} dtk, "
              f"rentang {report['min_durasi_detik']}-{report['max_durasi_detik']} dtk")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())