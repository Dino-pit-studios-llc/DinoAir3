import 'package:connectivity_plus/connectivity_plus.dart';

/// Provides reactive network connectivity status using [connectivity_plus].
class ConnectivityService {
  ConnectivityService([Connectivity? connectivity])
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  /// Emits `true` when at least one network interface is connected.
  Stream<bool> get onStatusChange =>
      _connectivity.onConnectivityChanged.map(_isOnline);

  /// Returns whether a connection is currently available.
  Future<bool> get isConnected async =>
      _isOnline(await _connectivity.checkConnectivity());

  bool _isOnline(ConnectivityResult result) {
    return result != ConnectivityResult.none;
  }
}
