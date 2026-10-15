import 'package:flutter/foundation.dart';

import '../../data/repositories/kana_repository.dart';

class HomeController extends ChangeNotifier {
  HomeController() {
    _repo.addListener(load);
    load();
  }

  final _repo = KanaRepository.instance;
  HomeStats? stats;
  bool _disposed = false;

  Future<void> load() async {
    final result = await _repo.homeStats();
    if (_disposed) return;
    stats = result;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _repo.removeListener(load);
    super.dispose();
  }
}
