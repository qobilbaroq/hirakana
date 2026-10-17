import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Memuat daftar kata hasil pipeline, bukan hasil filter(app).
List<List<String>> _readTsv(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    fail('berkas tidak ada: $path\n'
        'Jalankan dulu: python3 tool/build_words.py');
  }
  return file
      .readAsLinesSync()
      .where((l) => l.trim().isNotEmpty)
      .map((l) => l.split('\t'))
      .toList();
}

void main() {
  group('assets/data/words.tsv harus sama dengan keluaran pipeline', () {
    late String fresh;

    setUpAll(() {
      // Jalankan pipeline ke berkas sementara, JANGAN menimpa assets/.
      fresh = '${Directory.systemTemp.path}/kana_words_pipeline.tsv';
      final r = Process.runSync('python3', [
        'tool/build_words.py',
        '--out',
        fresh,
      ], workingDirectory: Directory.current.path);
      expect(r.exitCode, 0,
          reason: 'build_words.py gagal:\n${r.stdout}\n${r.stderr}');
    });

    tearDownAll(() {
      final f = File(fresh);
      if (f.existsSync()) f.deleteSync();
    });

    test('keluaran pipeline identik dengan berkas yang di-commit', () {
      final committed = _readTsv('assets/data/words.tsv');
      final generated = _readTsv(fresh);

      // Bandingkan per baris supaya pesan errornya informatif.
      final n = committed.length < generated.length
          ? committed.length
          : generated.length;
      for (var i = 0; i < n; i++) {
        if (committed[i].join('\t') != generated[i].join('\t')) {
          fail('baris ${i + 1} berbeda:\n'
              '  di commit : ${committed[i].join(' | ')}\n'
              '  pipeline  : ${generated[i].join(' | ')}\n'
              'Perbaiki atau masukkan koreksinya ke '
              'tool/translations/manual_fixes.tsv, lalu bangun ulang.');
        }
      }
      expect(generated.length, committed.length,
          reason: 'jumlah baris berbeda');
    });
  });

  group('kelengkapan arti', () {
    late List<List<String>> words;

    setUpAll(() {
      words = _readTsv('assets/data/words.tsv');
    });

    List<List<String>> jlpt() =>
        words.where((w) => w.length > 5 && ['N5', 'N4', 'N3'].contains(w[5]))
            .toList();

    test('tiada arti Indonesia kosong untuk kata JLPT', () {
      final kosong =
          jlpt().where((w) => w[3].trim().isEmpty).map((w) => w[0]).toList();
      expect(kosong, isEmpty,
          reason: 'kata JLPT tanpa arti: ${kosong.take(10)}');
    });

    test('tiada arti (Indonesia atau Inggris) lebih dari 60 karakter', () {
      final panjang = jlpt()
          .where((w) => w[3].length > 60 || w[4].length > 60)
          .map((w) => '${w[0]}: id=${w[3].length} en=${w[4].length}')
          .toList();
      expect(panjang, isEmpty, reason: panjang.take(10).join('\n'));
    });

    test('tiada label sisa JMdict seperti (abbr.) atau (hum.)', () {
      final label = RegExp(r'\((abbr|pol|hum|uk|oik|ksb|arch|obs|dial)\.\)');
      final kena = words
          .where((w) => w.length > 4 &&
              (label.hasMatch(w[3]) || label.hasMatch(w[4])))
          .map((w) => '${w[0]}: ${w[3]} / ${w[4]}')
          .toList();
      expect(kena, isEmpty, reason: kena.take(10).join('\n'));
    });

    test('kurung buka/tutup berpasangan di SEMUA arti', () {
      // Potongan arti glossary yang terpotong setelah "(" menghasilkan
      // "to bury, to fill up, to fill (a seat, a " yang jelek di layar.
      final rusak = <String>[];
      for (final w in words) {
        if (w.length < 5) continue;
        void cek(String label, String v) {
          final buka = '('.allMatches(v).length;
          final tutup = ')'.allMatches(v).length;
          if (buka != tutup || v.endsWith('(')) {
            rusak.add('${w[0]} $label: $v');
          }
        }

        cek('arti Indonesia', w[3]);
        cek('arti Inggris', w[4]);
      }
      expect(rusak, isEmpty, reason: rusak.take(10).join('\n'));
    });

    test('arti Inggris tidak berakhir di tengah kata', () {
      // Bandingkan dengan sumber mentah tool/data/*.csv: kalau baris ini
      // berawalan dari sumber tapi diikuti huruf, berarti terpotong mid-kata.
      final sumber = <String, String>{};
      for (final f in ['n5', 'n4', 'n3']) {
        final p = 'tool/data/$f.csv';
        if (!File(p).existsSync()) continue;
        for (final line in File(p).readAsLinesSync().skip(1)) {
          final c = line.split('","');
          if (c.length < 4) continue;
          final reading = c[1].replaceAll('"', '').trim();
          final meaning = c[3].replaceAll('"', '').trim();
          if (reading.isNotEmpty && meaning.isNotEmpty) {
            sumber.putIfAbsent(reading, () => meaning);
          }
        }
      }
      final terpotong = <String>[];
      for (final w in jlpt()) {
        final full = sumber[w[1]];
        final got = w[4];
        if (full == null || got.isEmpty || full == got) continue;
        if (!full.startsWith(got)) continue; // homograf #2, bukan terpotong
        final next = full.substring(got.length,
            got.length + 1);
        if (got.endsWith(' ') || next.isEmpty ||
            const [' ', ';', ',', ')'].contains(next)) {
          continue;
        }
        terpotong.add('${w[0]}: "$full" -> "$got"');
      }
      expect(terpotong, isEmpty, reason: terpotong.take(10).join('\n'));
    });
  });
}