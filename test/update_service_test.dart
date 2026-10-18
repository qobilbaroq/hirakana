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
}
