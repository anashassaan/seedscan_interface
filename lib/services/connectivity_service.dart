import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

/// Service that monitors device connectivity and notifies listeners
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();

  factory ConnectivityService() => _instance;

  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOnline = true;

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;

  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _isOnline = result != ConnectivityResult.none;
      _connectionStatusController.add(_isOnline);
    } catch (e) {
      print('Error checking connectivity: $e');
      _isOnline = true; // Assume online on error
    }

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final wasOnline = _isOnline;
      _isOnline = results != ConnectivityResult.none;

      if (wasOnline != _isOnline) {
        print(
            '[ConnectivityService] Status changed: ${_isOnline ? 'ONLINE' : 'OFFLINE'}');
        _connectionStatusController.add(_isOnline);
      }
    });
  }

  /// Perform a quick connectivity check
  Future<bool> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      print('Error during connectivity check: $e');
      return _isOnline;
    }
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _connectionStatusController.close();
  }
}
