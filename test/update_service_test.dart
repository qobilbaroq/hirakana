import 'package:flutter_test/flutter_test.dart';
import 'package:kana_quest/core/update/update_service.dart';

void main() {
  group('compareAppVersions', () {
    test('compares numeric components rather than text', () {
      expect(compareAppVersions('1.10.0', '1.9.9'), greaterThan(0));
      expect(compareAppVersions('v2.0.0', '1.99.99'), greaterThan(0));
      expect(compareAppVersions('1.3.0+8', '1.3.0+4'), 0);
    });

    test('treats omitted trailing zeroes as equal', () {
      expect(compareAppVersions('1.3', '1.3.0'), 0);
    });
  });

  group('GitHubRelease', () {
    test('parses release info and selects a device APK', () {
      final release = GitHubRelease.fromJson({
        'tag_name': 'v1.4.0',
        'name': 'Pembaruan kosakata',
        'body': 'Perbaikan arti dan beberapa fitur baru.',
        'assets': [
          {
            'name': 'kana-quest-arm64-v8a.apk',
            'browser_download_url':
                'https://github.com/qobilbaroq/hirakana/releases/download/v1.4.0/kana-quest-arm64-v8a.apk',
          },
          {
            'name': 'kana-quest-universal.apk',
            'browser_download_url':
                'https://github.com/qobilbaroq/hirakana/releases/download/v1.4.0/kana-quest-universal.apk',
          },
        ],
      });

      expect(release.version, '1.4.0');
      expect(release.title, 'Pembaruan kosakata');
      expect(
        selectApkAsset(release.assets, ['arm64-v8a']).name,
        'kana-quest-arm64-v8a.apk',
      );
      expect(
        selectApkAsset(release.assets, ['x86_64']).name,
        'kana-quest-universal.apk',
      );
    });

    test('reports a release without an APK clearly', () {
      expect(
        () => selectApkAsset(const [], const []),
        throwsA(isA<UpdateException>()),
      );
    });

    test('does not choose a single split APK for a different device ABI', () {
      const apk = GitHubReleaseAsset(
        name: 'kanaquest-arm64-v8a.apk',
        downloadUrl:
            'https://github.com/qobilbaroq/hirakana/releases/download/v1.4.0/kanaquest-arm64-v8a.apk',
      );
      expect(
        () => selectApkAsset([apk], ['armeabi-v7a']),
        throwsA(isA<UpdateException>()),
      );
    });
  });

  group('summarizeReleaseNotes', () {
    test('mengambil bullet di bawah heading Ringkasan', () {
      const body = '''
Pembaruan yang lebih panjang sekali yang tidak boleh muncul di popup.

## Ringkasan
- Baru: Tebak arti kata dan riwayat kata
- Diperbaiki: arti kata tidak lagi tertimpa kategori

## Detail
- Ini bagian panjang yang harus diabaikan
''';
      expect(summarizeReleaseNotes(body), [
        'Baru: Tebak arti kata dan riwayat kata',
        'Diperbaiki: arti kata tidak lagi tertimpa kategori',
      ]);
    });

    test('heading Ringkasan boleh ### dan huruf besar', () {
      const body = '''
### RINGKASAN
- Satu
- Dua
''';
      expect(summarizeReleaseNotes(body), ['Satu', 'Dua']);
    });

    test('tanpa heading Ringkasan memakai bullet pertama', () {
      const body = 'Halo dunia\n\n- Poin pertama\n- Poin kedua\n';
      expect(summarizeReleaseNotes(body), ['Poin pertama']);
    });

    test('bullet kosong, format Markdown, dan tautan dirapikan', () {
      const body = '''
## Ringkasan
-   **Tebal** dan `kode`
- [teks tautan](https://contoh.example/halaman-panjang-sekali)
- spasi   berlebih
-
''';
      expect(summarizeReleaseNotes(body), [
        'Tebal dan kode',
        'teks tautan',
        'spasi berlebih',
      ]);
    });

    test('memotong poin lebih dari 80 karakter dengan elipsis', () {
      final long = 'a' * 200;
      final points = summarizeReleaseNotes('## Ringkasan\n- $long\n');
      expect(points, hasLength(1));
      expect(points.single.length, 80);
      expect(points.single.endsWith('…'), isTrue);
    });

    test('maksimal maxItems poin', () {
      final body = [
        '## Ringkasan',
        for (var i = 1; i <= 7; i++) '- Poin $i',
      ].join('\n');
      expect(summarizeReleaseNotes(body), ['Poin 1', 'Poin 2', 'Poin 3', 'Poin 4']);
      expect(summarizeReleaseNotes(body, maxItems: 2), ['Poin 1', 'Poin 2']);
    });

    test('body kosong atau tanpa bullet menghasilkan daftar kosong', () {
      expect(summarizeReleaseNotes(''), isEmpty);
      expect(summarizeReleaseNotes('Hanya teks biasa tanpa bullet.'), isEmpty);
      expect(
        summarizeReleaseNotes('## Ringkasan\n\n## Detail\n- ada bullet di detail'),
        isEmpty,
      );
    });
  });
}
