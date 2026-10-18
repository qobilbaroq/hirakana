#!/usr/bin/env python3
"""Membuat suara kata (normal + lambat) dengan Open JTalk + htsvoice-tohoku-f01.

Hanya membuat file yang BELUM ada, jadi aman dijalankan berulang.
Keluaran : assets/audio/words/<cara-baca>.mp3 dan <cara-baca>_slow.mp3
           (mp3 mono 22050 Hz, sama seperti rekaman kata yang sudah ada)

Syarat   : open_jtalk, ffmpeg, kamus naist-jdic, dan berkas tohoku-f01-neutral.htsvoice
  Ubuntu : sudo apt install open-jtalk open-jtalk-mecab-naist-jdic ffmpeg
           git clone https://github.com/icn-lab/htsvoice-tohoku-f01.git

Pakai    :
  python3 tools/generate_audio.py --voice /path/ke/tohoku-f01-neutral.htsvoice
  opsi   : --dic /var/lib/mecab/dic/open-jtalk/naist-jdic   (default)
           --only-curated      hanya kata yang punya level (default: ya)
           --limit N           uji coba N kata
Laporan JSON: tools/out/audio_report.json
"""
import argparse
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path

from vocab_lib import ROOT, expected_consonants, load_kana, parse

WORDS = ROOT / "assets/data/words.tsv"
AUDIO = ROOT / "assets/audio/words"
OUT = ROOT / "tools/out"
VOWELS = set("aiueoAIUEO")


def to_katakana(s):
    return "".join(chr(ord(c) + 0x60) if "ぁ" <= c <= "ゖ" else c for c in s)


def synth(text, voice, dic, wav, trace):
    subprocess.run(
        ["open_jtalk", "-x", dic, "-m", voice, "-ow", str(wav), "-ot", str(trace)],
        input=text.encode("utf-8"), check=True, capture_output=True)


def jtalk_consonants(trace_file):
    """Konsonan hasil Open JTalk (dari label fonem) untuk memeriksa salah baca."""
    cons = []
    for ln in Path(trace_file).read_text(encoding="utf-8", errors="ignore").split("\n"):
        if "[Output label]" in ln or not re.match(r"^\d+ \d+ ", ln):
            continue
        m = re.search(r"\^(.+?)-(.+?)\+", ln)
        if not m:
            continue
        ph = m.group(2)
        if ph in ("sil", "pau") or ph in VOWELS:
            continue
        cons.append("n" if ph == "N" else ph.lower())
    return cons


def volume_peak(path):
    r = subprocess.run(["ffmpeg", "-hide_banner", "-i", str(path), "-af", "volumedetect",
                        "-f", "null", "-"], capture_output=True, text=True)
    m = re.search(r"max_volume: (-?[\d.]+) dB", r.stderr)
    return float(m.group(1)) if m else -3.0


def encode(wav, dest_normal, dest_slow):
    trim = ("silenceremove=start_periods=1:start_threshold=-50dB:"
            "stop_periods=1:stop_threshold=-50dB:stop_duration=0.1,"
            "adelay=120:all=1,apad=pad_dur=0.12")
    with tempfile.TemporaryDirectory() as td:
        pre = Path(td) / "pre.wav"
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", str(wav), "-af", trim,
                        "-ar", "22050", "-ac", "1", str(pre)], check=True)
        gain = -1.5 - volume_peak(pre)   # puncak diseragamkan ke sekitar -1,5 dB
        base = f"volume={gain:.2f}dB"
        for dest, extra in ((dest_normal, ""), (dest_slow, ",atempo=0.75")):
            subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", str(pre),
                            "-af", base + extra, "-ar", "22050", "-ac", "1",
                            "-codec:a", "libmp3lame", "-b:a", "32k", str(dest)], check=True)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--voice", required=True, help="tohoku-f01-neutral.htsvoice")
    ap.add_argument("--dic", default="/var/lib/mecab/dic/open-jtalk/naist-jdic")
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--all", action="store_true",
                    help="juga kata JMdict tanpa level (default: hanya kata kurasi)")
    args = ap.parse_args()

    kana = load_kana()
    todo = {}
    for ln in WORDS.read_text(encoding="utf-8").split("\n"):
        c = ln.split("\t")
        if len(c) < 3:
            continue
        curated = len(c) > 4 and c[4]
        if not curated and not args.all:
            continue
        reading = c[1]
        if (AUDIO / f"{reading}.mp3").exists() and (AUDIO / f"{reading}_slow.mp3").exists():
            continue
        todo.setdefault(reading, c[0])
    items = list(todo.items())
    if args.limit:
        items = items[:args.limit]

    AUDIO.mkdir(parents=True, exist_ok=True)
    made, suspicious, failed, used_kata = [], [], [], []
    with tempfile.TemporaryDirectory() as td:
        wav, trace = Path(td) / "o.wav", Path(td) / "t.txt"
        for n, (reading, text) in enumerate(items, 1):
            try:
                want = expected_consonants(parse(text, kana))
                synth(text, args.voice, args.dic, wav, trace)
                got = jtalk_consonants(trace)
                if got != want:        # mis. は dibaca "wa" -> coba tulisan katakana
                    synth(to_katakana(text), args.voice, args.dic, wav, trace)
                    got2 = jtalk_consonants(trace)
                    if got2 == want:
                        used_kata.append(text)
                    else:
                        suspicious.append(dict(kata=text, cara_baca=reading,
                                               harapan=want, hasil=got2))
                encode(wav, AUDIO / f"{reading}.mp3", AUDIO / f"{reading}_slow.mp3")
                made.append(reading)
            except Exception as e:   # noqa: BLE001
                failed.append(dict(kata=text, cara_baca=reading, error=str(e)[:200]))
            if n % 50 == 0:
                print(f"  {n}/{len(items)}", flush=True)

    # perbarui kolom audio di words.tsv
    lines = WORDS.read_text(encoding="utf-8").split("\n")
    fixed = 0
    for i, ln in enumerate(lines):
        c = ln.split("\t")
        if len(c) >= 3 and c[2] == "0" and \
           (AUDIO / f"{c[1]}.mp3").exists() and (AUDIO / f"{c[1]}_slow.mp3").exists():
            c[2] = "1"
            lines[i] = "\t".join(c)
            fixed += 1
    WORDS.write_text("\n".join(lines), encoding="utf-8")

    OUT.mkdir(parents=True, exist_ok=True)
    rep = dict(dibuat=len(made), kolom_audio_diperbarui=fixed,
               pakai_tulisan_katakana=used_kata, mencurigakan=suspicious, gagal=failed)
    (OUT / "audio_report.json").write_text(
        json.dumps(rep, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"audio dibuat: {len(made)} cara baca ({len(made) * 2} file)")
    print(f"kolom audio words.tsv diperbarui: {fixed}")
    print(f"dibaca ulang lewat katakana: {len(used_kata)}")
    print(f"mencurigakan (cek manual): {len(suspicious)}   gagal: {len(failed)}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
