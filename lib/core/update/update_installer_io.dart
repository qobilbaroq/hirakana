import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

const _channel = MethodChannel('dev.qobilul.kana_quest/updates');

Future<List<String>> supportedAbis() async {
  final abis = await _channel.invokeListMethod<String>('supportedAbis');
  return abis ?? const [];
}

Future<bool> _canInstallPackages() async =>
    await _channel.invokeMethod<bool>('prepareInstall') ?? false;

Future<void> downloadAndInstall(
  Uri uri, {
  void Function(double? progress)? onProgress,
}) async {
  if (!Platform.isAndroid) {
    throw UnsupportedError('Instalasi pembaruan Android tidak tersedia.');
  }
  if (!await _canInstallPackages()) {
    throw PlatformException(
      code: 'install_permission_required',
      message:
          'Izinkan pemasangan aplikasi dari Kana Quest, lalu tekan Unduh & instal lagi.',
    );
  }

  final client = http.Client();
  File? apkFile;
  IOSink? sink;
  try {
    final request = http.Request('GET', uri)
      ..headers['User-Agent'] = 'Kana-Quest-Android';
    final response = await client.send(request);
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'Gagal mengunduh APK (HTTP ${response.statusCode}).',
        uri: uri,
      );
    }
    if (response.contentLength == 0) {
      throw HttpException('File APK yang diunduh kosong.', uri: uri);
    }

    final temporaryDirectory = await getTemporaryDirectory();
    final updateDirectory = Directory('${temporaryDirectory.path}/updates');
    await updateDirectory.create(recursive: true);
    apkFile = File('${updateDirectory.path}/kana-quest-update.apk');
    sink = apkFile.openWrite();

    var received = 0;
    await for (final chunk in response.stream) {
      sink.add(chunk);
      received += chunk.length;
      final total = response.contentLength;
      onProgress?.call(
        total != null && total > 0 ? received / total : null,
      );
    }
    await sink.flush();
    await sink.close();
    sink = null;

    if (received == 0) {
      throw HttpException('File APK yang diunduh kosong.', uri: uri);
    }
    await _channel.invokeMethod<void>(
      'installApk',
      {'path': apkFile.path},
    );
  } catch (_) {
    if (sink != null) await sink.close();
    if (apkFile != null && await apkFile.exists()) {
      await apkFile.delete();
    }
    rethrow;
  } finally {
    client.close();
  }
}
