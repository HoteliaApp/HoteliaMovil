import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

abstract class ConnectivityService {
  /// Emite si el dispositivo tiene conexión a internet activa
  Stream<bool> watchIsOnline();

  /// Comprueba de forma puntual si hay conexión de red
  Future<bool> checkIsOnline();
}

class ConnectivityServiceImpl implements ConnectivityService {
  final Connectivity _connectivity;

  ConnectivityServiceImpl([Connectivity? connectivity])
      : _connectivity = connectivity ?? Connectivity();

  static bool _isOnlineFromResults(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn);
  }

  @override
  Stream<bool> watchIsOnline() {
    return _connectivity.onConnectivityChanged.map(_isOnlineFromResults);
  }

  @override
  Future<bool> checkIsOnline() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return _isOnlineFromResults(results);
    } catch (_) {
      return false;
    }
  }
}
