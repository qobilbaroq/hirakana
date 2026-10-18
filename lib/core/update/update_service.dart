import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;

import 'update_installer_stub.dart'
    if (dart.library.io) 'update_installer_io.dart'
    as installer;

class GitHubRelease {
  const GitHubRelease({
    required this.tagName,
    required this.title,
    required this.notes,
    required this.assets,
  });

  final String tagName;
  final String title;
  final String notes;
  final List<GitHubReleaseAsset> assets;

  String get version => tagName.replaceFirst(RegExp(r'^[vV]'), '');

  factory GitHubRelease.fromJson(Map<String, dynamic> json) {
    final tagName = json['tag_name'];
    final rawAssets = json['assets'];
    if (tagName is! String || rawAssets is! List) {
      throw const FormatException('Format data rilis GitHub tidak valid.');
    }
    return GitHubRelease(
      tagName: tagName,
      title: json['name'] is String && (json['name'] as String).isNotEmpty
          ? json['name'] as String
          : tagName,
      notes: json['body'] is String ? json['body'] as String : '',
      assets: [
        for (final asset in rawAssets)
          if (asset is Map<String, dynamic>) GitHubReleaseAsset.fromJson(asset),
      ],
    );
  }
}

class GitHubReleaseAsset {
  const GitHubReleaseAsset({required this.name, required this.downloadUrl});

  final String name;
  final String downloadUrl;

  factory GitHubReleaseAsset.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final downloadUrl = json['browser_download_url'];
    if (name is! String || downloadUrl is! String) {
      throw const FormatException('Data APK rilis GitHub tidak valid.');
    }
    return GitHubReleaseAsset(name: name, downloadUrl: downloadUrl);
  }
}

class UpdateException implements Exception {
  const UpdateException(this.message);

  final String message;

  @override
  String toString() => message;
}

int compareAppVersions(String a, String b) {
  final aParts = _versionParts(a);
  final bParts = _versionParts(b);
  final length = aParts.length > bParts.length ? aParts.length : bParts.length;
  for (var i = 0; i < length; i++) {
    final aPart = i < aParts.length ? aParts[i] : 0;
    final bPart = i < bParts.length ? bParts[i] : 0;
    if (aPart != bPart) return aPart.compareTo(bPart);
  }
  return 0;
}

List<int> _versionParts(String version) {
  final normalized = version
      .replaceFirst(RegExp(r'^[vV]'), '')
      .split('+')
      .first;
  final match = RegExp(r'^\d+(?:\.\d+)*').firstMatch(normalized);
  if (match == null) {
    throw FormatException('Versi aplikasi tidak valid: $version');
  }
  return match[0]!.split('.').map(int.parse).toList();
}

GitHubReleaseAsset selectApkAsset(
  List<GitHubReleaseAsset> assets,
  List<String> supportedAbis,
) {
  const knownAbis = ['arm64-v8a', 'armeabi-v7a', 'x86_64', 'x86', 'armeabi'];
  final apks = assets
      .where((asset) => asset.name.toLowerCase().endsWith('.apk'))
      .toList();
  if (apks.isEmpty) {
    throw const UpdateException(
      'Rilis ini belum menyertakan file APK untuk dipasang.',
    );
  }

  String? assetAbi(GitHubReleaseAsset asset) {
    final name = asset.name.toLowerCase();
    for (final abi in knownAbis) {
      if (name.contains(abi)) return abi;
    }
    return null;
  }

  for (final abi in supportedAbis) {
    for (final asset in apks) {
      if (assetAbi(asset) == abi.toLowerCase()) return asset;
    }
  }
  if (apks.length == 1 && assetAbi(apks.single) == null) {
    return apks.single;
  }
  for (final asset in apks) {
    final name = asset.name.toLowerCase();
    if (name.contains('universal') || name == 'app-release.apk') return asset;
  }
  throw const UpdateException(
    'Rilis ini tidak memiliki APK yang cocok dengan perangkat ini.',
  );
}

class GitHubUpdateService {
  GitHubUpdateService._();
  static final instance = GitHubUpdateService._();

  static final _latestReleaseUri = Uri.https(
    'api.github.com',
    '/repos/qobilbaroq/hirakana/releases/latest',
  );

  Future<GitHubRelease?> checkForUpdate() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw const UpdateException(
        'Pembaruan langsung hanya tersedia di aplikasi Android.',
      );
    }

    final response = await http.get(
      _latestReleaseUri,
      headers: const {
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'Kana-Quest-Android',
      },
    );
    if (response.statusCode != 200) {
      throw UpdateException(
        'Gagal memeriksa rilis GitHub (HTTP ${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const UpdateException('Respons rilis GitHub tidak valid.');
    }
    final release = GitHubRelease.fromJson(decoded);
    final currentVersion = (await PackageInfo.fromPlatform()).version;
    return compareAppVersions(release.version, currentVersion) > 0
        ? release
        : null;
  }

  Future<void> downloadAndInstall(
    GitHubRelease release, {
    void Function(double? progress)? onProgress,
  }) async {
    final abis = await installer.supportedAbis();
    final asset = selectApkAsset(release.assets, abis);
    final uri = Uri.tryParse(asset.downloadUrl);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host != 'github.com' ||
        !uri.path.startsWith('/qobilbaroq/hirakana/releases/download/')) {
      throw const UpdateException('Tautan APK rilis tidak valid.');
    }
    await installer.downloadAndInstall(uri, onProgress: onProgress);
  }
}
