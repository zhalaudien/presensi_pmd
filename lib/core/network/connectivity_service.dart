import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  Stream<bool> get onConnectivityChanged => _controller.stream;

  ConnectivityService() {
    _connectivity.onConnectivityChanged.listen((results) {
      final isOnline = _isOnline(results);
      _controller.add(isOnline);
    });
  }

  bool _isOnline(List<ConnectivityResult> results) {
    return results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet);
  }

  Future<bool> checkOnline() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return _isOnline(results);
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _controller.close();
  }
}
