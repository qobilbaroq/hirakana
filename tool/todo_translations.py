#!/usr/bin/env python3
"""Tulis daftar kata JLPT yang belum punya arti Indonesia.

Output: satu baris "kunci<TAB>arti_inggris" ke file yang diberikan.
"""
import importlib.util
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = sys.argv[1] if len(sys.argv) > 1 else '/tmp/opencode/todo.txt'

spec = importlib.util.spec_from_file_location('bw', os.path.join(ROOT, 'tool', 'build_words.py'))
bw = importlib.util.module_from_spec(spec)
spec.loader.exec_module(bw)
bw.table = bw.load_kana()
jlpt, _ = bw.load_jlpt()

indo = set()
for ln in open(os.path.join(ROOT, 'tool/translations/id.tsv'), encoding='utf-8'):
    if ln.startswith('#') or not ln.strip():
        continue
    indo.add(ln.split('\t')[0])

todo = [w for w in jlpt if w['key'] not in indo]
with open(OUT, 'w', encoding='utf-8') as f:
    for w in todo:
        f.write(f"{w['key']}\t{w['meaning_en']}\n")
print(f'{len(todo)} kata belum diterjemahkan -> {OUT}')
