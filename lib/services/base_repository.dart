import 'package:hive/hive.dart';
import '../models/sync_queue_model.dart';
import 'sync_manager.dart';

/// Base repository implementing Local-First sync strategy
///
/// Read Strategy:
/// 1. Instantly return from Hive
/// 2. Silent background refresh from Appwrite
/// 3. Update Hive and notify listeners if changed
///
/// Write Strategy (Offline):
/// 1. Immediately update Hive
/// 2. Queue operation in SyncQueue
/// 3. Return optimistically updated UI
/// 4. Sync when online
abstract class BaseRepository<T> {
  final Box<T> localBox;
  final SyncManager syncManager;
  final String entityType;

  BaseRepository({
    required this.localBox,
    required this.syncManager,
    required this.entityType,
  });

  /// Read from local cache first, then sync in background
  /// Returns cached data immediately for instant UI feedback
  Future<T?> get(String id) async {
    // 1. Return from cache instantly (optimistic read)
    final cached = localBox.get(id);
    if (cached != null) {
      print('[${entityType}Repository] Cache hit: $id');
      // 2. Silent background refresh (fire & forget)
      _silentRefresh(id);
    } else {
      print('[${entityType}Repository] Cache miss: $id');
    }
    return cached;
  }

  /// Get all items from local cache
  Future<List<T>> getAll() async {
    return localBox.values.toList();
  }

  /// Create locally and queue for sync
  /// Optimistic: Data is immediately available in UI
  Future<T> create(String id, T data) async {
    // 1. Update local cache immediately (optimistic write)
    await localBox.put(id, data);
    print('[${entityType}Repository] Created locally: $id');

    // 2. Queue for sync
    final syncData = _toSyncData(data, id);
    await syncManager.queueSyncItem(
      entityType: entityType,
      operationType: SyncOperationType.create,
      data: syncData,
      entityId: id,
      priority: 1,
    );

    return data;
  }

  /// Update locally and queue for sync
  /// Optimistic: UI updates before sync completes
  Future<T> update(String id, T data) async {
    // 1. Update local cache immediately (optimistic write)
    await localBox.put(id, data);
    print('[${entityType}Repository] Updated locally: $id');

    // 2. Queue for sync
    final syncData = _toSyncData(data, id);
    await syncManager.queueSyncItem(
      entityType: entityType,
      operationType: SyncOperationType.update,
      data: syncData,
      entityId: id,
      priority: 1,
    );

    return data;
  }

  /// Delete locally and queue for sync
  Future<void> delete(String id) async {
    // 1. Delete from local cache (optimistic delete)
    await localBox.delete(id);
    print('[${entityType}Repository] Deleted locally: $id');

    // 2. Queue for sync
    await syncManager.queueSyncItem(
      entityType: entityType,
      operationType: SyncOperationType.delete,
      data: {'id': id},
      entityId: id,
      priority: 2, // High priority for deletes
    );
  }

  /// Internal: Silent background refresh
  /// Fetches from remote (Appwrite) and updates local cache if changed
  Future<void> _silentRefresh(String id) async {
    try {
      // This method should be overridden in subclasses to fetch from Appwrite
      // For now, it's a placeholder
      print('[${entityType}Repository] Silent refresh for: $id');
    } catch (e) {
      print('[${entityType}Repository] Silent refresh error: $e');
      // Silently fail - don't disrupt user
    }
  }

  /// Conflict resolution: Last-In-Wins
  /// Compares timestamps and keeps the newer version
  bool hasConflict(T local, T remote, DateTime localTime, DateTime remoteTime) {
    // Simple Last-In-Wins: newer timestamp wins
    return remoteTime.isAfter(localTime);
  }

  /// Resolve conflict using timestamp strategy
  void resolveConflict(
    String id,
    T localData,
    T remoteData,
    DateTime localTime,
    DateTime remoteTime,
  ) {
    if (hasConflict(localData, remoteData, localTime, remoteTime)) {
      print('[${entityType}Repository] Conflict: keeping remote (newer)');
      localBox.put(id, remoteData);
    } else {
      print('[${entityType}Repository] Conflict: keeping local (newer)');
    }
  }

  /// Convert entity to sync-friendly data (override in subclass if needed)
  Map<String, dynamic> _toSyncData(T data, String id) {
    if (data is Map) {
      return {
        'id': id,
        ...data as Map<String, dynamic>,
      };
    }
    return {'id': id, 'data': data.toString()};
  }

  /// Clear entire local cache (use with caution)
  Future<void> clearCache() async {
    await localBox.clear();
    print('[${entityType}Repository] Cache cleared');
  }

  /// Get cache size
  int getCacheSize() => localBox.length;

  /// Export cache as JSON for debugging
  List<Map<String, dynamic>> exportCacheAsJson() {
    return localBox.values
        .map((item) => {
              'item': item.toString(),
              'type': item.runtimeType.toString(),
            })
        .toList();
  }
}
