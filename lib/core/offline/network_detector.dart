import 'package:connectivity_plus/connectivity_plus.dart';

/// Network connectivity detector
///
/// Monitors network connectivity status and provides real-time updates.
/// Detects WiFi and mobile data connections.
class NetworkDetector {
  final Connectivity _connectivity = Connectivity();

  /// Check current connectivity status
  ///
  /// Returns `true` if connected via WiFi or mobile data
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return _hasActiveConnection(results);
  }

  /// Stream of connectivity changes
  ///
  /// Emits `true` when connected, `false` when disconnected
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map((results) {
      return _hasActiveConnection(results);
    });
  }

  /// Check if connectivity result indicates active connection
  bool _hasActiveConnection(List<ConnectivityResult> results) {
    return results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.mobile);
  }

  /// Check if currently offline
  Future<bool> get isOffline async {
    return !(await isConnected);
  }
}
