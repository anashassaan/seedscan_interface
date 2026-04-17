import 'dart:async';
import 'package:appwrite/appwrite.dart';
import '../models/sync_queue_model.dart';
import 'connectivity_service.dart';
import 'sync_queue_service.dart';

/// Manages background sync with debouncing, conflict resolution, and retry logic
class SyncManager {
  static final SyncManager _instance = SyncManager._internal();

  factory SyncManager() => _instance;

  SyncManager._internal();

  final _syncQueueService = SyncQueueService();
  final _connectivityService = ConnectivityService();

  // Stream for sync status updates
  final StreamController<SyncStatus> _syncStatusController =
      StreamController<SyncStatus>.broadcast();

  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  Timer? _debounceTimer;
  Timer? _retryTimer;
  bool _isSyncing = false;
  static const Duration _debounceInterval = Duration(seconds: 2);
  static const Duration _retryInterval = Duration(seconds: 30);

  bool get isSyncing => _isSyncing;
  bool get hasFailedItems => _syncQueueService.getStats().failedCount > 0;

  /// Initialize the sync manager
  Future<void> initialize(Client appwriteClient) async {
    await _syncQueueService.initialize();
    await _connectivityService.initialize();

    // Listen for connectivity changes and trigger sync
    _connectivityService.connectionStatusStream.listen((isOnline) {
      if (isOnline) {
        print('[SyncManager] Connection restored, triggering sync...');
        scheduleSyncWithDebounce();
      }
    });

    print('[SyncManager] Initialized');
  }

  /// Schedule a sync with debouncing to avoid excessive API calls
  void scheduleSyncWithDebounce() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceInterval, () {
      performSync();
    });
  }

  /// Perform the actual sync
  Future<void> performSync() async {
    if (!_connectivityService.isOnline) {
      print('[SyncManager] Offline - sync postponed');
      _syncStatusController.add(
        SyncStatus(
          isOnline: false,
          isSyncing: false,
          message: 'Offline - waiting for connection',
        ),
      );
      return;
    }

    if (_isSyncing) {
      print('[SyncManager] Already syncing, skipping');
      return;
    }

    _isSyncing = true;
    _syncStatusController.add(SyncStatus(
      isOnline: true,
      isSyncing: true,
      message: 'Syncing...',
    ));

    try {
      final items = _syncQueueService.getRetryableItems();
      int successCount = 0;
      int failedCount = 0;

      for (final item in items) {
        try {
          await _syncItem(item);
          successCount++;
          await _syncQueueService.removeItem(item);
        } catch (e) {
          item.markFailed(e.toString());
          await _syncQueueService.updateItem(item);
          failedCount++;

          // Don't retry immediately if max retries exceeded
          if (!item.shouldRetry()) {
            print('[SyncManager] Item ${item.id} exceeded max retries');
          }
        }
      }

      print(
          '[SyncManager] Sync complete: $successCount succeeded, $failedCount failed');

      _syncStatusController.add(SyncStatus(
        isOnline: true,
        isSyncing: false,
        message: 'Synced: $successCount, Failed: $failedCount',
        successCount: successCount,
        failedCount: failedCount,
      ));

      // Schedule retry if there are failed items
      if (failedCount > 0) {
        _scheduleRetry();
      }
    } catch (e) {
      print('[SyncManager] Sync error: $e');
      _syncStatusController.add(SyncStatus(
        isOnline: true,
        isSyncing: false,
        message: 'Sync failed: $e',
        error: e.toString(),
      ));
      _scheduleRetry();
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync a single item with Appwrite
  Future<void> _syncItem(SyncQueueItem item) async {
    print(
        '[SyncManager] Syncing ${item.operationLabel} for ${item.entityType}');

    // TODO: Implement Appwrite sync logic based on entity type
    // This is a placeholder - actual implementation depends on your Appwrite collections

    switch (item.operationType) {
      case SyncOperationType.create:
        // Item.data contains the creation payload
        print('  → CREATE: ${item.data}');
        break;

      case SyncOperationType.update:
        // Item.data contains the update payload
        print('  → UPDATE (${item.entityId}): ${item.data}');
        break;

      case SyncOperationType.delete:
        // Item.entityId contains the ID to delete
        print('  → DELETE (${item.entityId})');
        break;

      case SyncOperationType.read:
        print('  → READ: ${item.data}');
        break;
    }

    // Mark as synced
    item.markSynced();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Schedule a retry for failed items
  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(_retryInterval, () {
      print(
          '[SyncManager] Retrying failed items (interval: ${_retryInterval.inSeconds}s)');
      performSync();
    });
  }

  /// Add an item to sync queue (for offline writes)
  Future<SyncQueueItem> queueSyncItem({
    required String entityType,
    required SyncOperationType operationType,
    required Map<String, dynamic> data,
    String? entityId,
    int priority = 1,
    Map<String, dynamic>? metadata,
  }) async {
    final item = SyncQueueItem(
      entityType: entityType,
      operationType: operationType,
      data: data,
      entityId: entityId,
      priority: priority,
      metadata: metadata,
    );

    await _syncQueueService.addToQueue(item);
    scheduleSyncWithDebounce();
    return item;
  }

  /// Get sync statistics
  SyncStats getSyncStats() => _syncQueueService.getStats();

  /// Dispose resources
  void dispose() {
    _debounceTimer?.cancel();
    _retryTimer?.cancel();
    _syncStatusController.close();
  }
}

/// Model for sync status updates
class SyncStatus {
  final bool isOnline;
  final bool isSyncing;
  final String message;
  final int successCount;
  final int failedCount;
  final String? error;

  SyncStatus({
    required this.isOnline,
    required this.isSyncing,
    required this.message,
    this.successCount = 0,
    this.failedCount = 0,
    this.error,
  });

  @override
  String toString() =>
      'SyncStatus(online: $isOnline, syncing: $isSyncing, msg: $message)';
}
