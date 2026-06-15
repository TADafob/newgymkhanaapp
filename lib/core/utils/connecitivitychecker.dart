import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final _connectionChangeController = StreamController<bool>.broadcast();

  /// Emits `true`/`false` whenever the device goes online/offline.
  Stream<bool> get connectionChange => _connectionChangeController.stream;

  ConnectivityService() {
    // onConnectivityChanged now yields List<ConnectivityResult>
    Connectivity()
      .onConnectivityChanged
      .listen(_connectionChanged);
  }

  /// Manually trigger a check; returns `true` if any interface is up.
  Future<bool> checkConnection() async {
    final results = await Connectivity().checkConnectivity();
    final isConnected = results.any((r) => r != ConnectivityResult.none);
    _connectionChangeController.add(isConnected);
    return isConnected;
  }

  /// Handler for the connectivity stream’s List<ConnectivityResult>
  void _connectionChanged(List<ConnectivityResult> results) {
    final isConnected = results.any((r) => r != ConnectivityResult.none);
    _connectionChangeController.add(isConnected);
  }

  void dispose() {
    _connectionChangeController.close();
  }
}
