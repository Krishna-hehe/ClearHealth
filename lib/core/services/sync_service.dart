import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../services/log_service.dart';

class SyncService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  final Box _syncBox;
  bool _isOnline = true;
  StreamSubscription? _subscription;

  SyncService(this._syncBox) {
    _init();
  }

  bool get isOnline => _isOnline;

  Future<void> _init() async {
    final result = await _connectivity.checkConnectivity();
    _updateStatus(result);

    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    // connectivity_plus 6.0 returns a List<ConnectivityResult>
    final status = results.firstWhere(
      (r) => r != ConnectivityResult.none,
      orElse: () => ConnectivityResult.none,
    );

    _isOnline = status != ConnectivityResult.none;
    notifyListeners();
    AppLogger.debug(
      '🌐 Network Status: ${_isOnline ? "Online" : "Offline"} ($status)',
    );

    if (_isOnline) {
      _processQueue();
    }
  }

  Future<void> addToQueue(String action, Map<String, dynamic> data) async {
    final item = {
      'action': action,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await _syncBox.add(item);
    AppLogger.debug('📥 Added to Sync Queue: $action');
  }

  Future<void> _processQueue() async {
    if (_syncBox.isEmpty) return;

    AppLogger.debug('🔄 Processing Sync Queue (${_syncBox.length} items)...');

    // Process items one by one (FIFO)
    // Note: In a real app, you'd probably want more robust retry logic
    // For MVP, we just try to process and remove if successful

    final keys = _syncBox.keys.toList();
    for (var key in keys) {
      if (!_isOnline) break;

      try {
        final item = Map<String, dynamic>.from(_syncBox.get(key));
        final success = await _executeAction(item['action'], item['data']);

        if (success) {
          await _syncBox.delete(key);
          AppLogger.debug('✅ Synced: ${item['action']}');
        }
      } catch (e) {
        AppLogger.error('❌ Sync Failed for $key: $e');
        // Keep in queue to retry later
      }
    }
  }

  // This will be injected or set by the repository to avoid circular dependencies
  Future<bool> Function(String action, Map<String, dynamic> data)?
  _actionHandler;

  void setActionHandler(
    Future<bool> Function(String action, Map<String, dynamic> data) handler,
  ) {
    _actionHandler = handler;
  }

  Future<bool> _executeAction(String action, Map<String, dynamic> data) async {
    if (_actionHandler != null) {
      return await _actionHandler!(action, data);
    }
    return false;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
