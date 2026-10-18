Future<List<String>> supportedAbis() async => [];

Future<void> downloadAndInstall(
  Uri uri, {
  void Function(double? progress)? onProgress,
}) async {
  throw UnsupportedError('Instalasi pembaruan Android tidak tersedia.');
}
