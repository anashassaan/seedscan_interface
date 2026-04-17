import 'package:hive_flutter/hive_flutter.dart';
import '../models/sync_queue_model.dart';

/// Service to manage the sync queue in Hive
class SyncQueueService {
  static final SyncQueueService _instance = SyncQueueService._internal();
  static const String _boxName = 'sync_queue';

  factory SyncQueueService() => _instance;

  SyncQueueService._internal();

  late Box<SyncQueueItem> _syncBox;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _syncBox = await Hive.openBox<SyncQueueItem>(_boxName);
      _initialized = true;
      print(
          '[SyncQueueService] Initialized with ${_syncBox.length} pending items');
    } catch (e) {
      print('[SyncQueueService] Error initializing: $e');
      rethrow;
    }
  }

  /// Add an item to the sync queue
  Future<SyncQueueItem> addToQueue(SyncQueueItem item) async {
    await _syncBox.add(item);
    print('[SyncQueue] Added: ${item.operationLabel} for ${item.entityType}');
    return item;
  }

  /// Get all pending items sorted by priority (high first) then by creation time
  List<SyncQueueItem> getPendingItems() {
    final items = _syncBox.values.toList();
    items.sort((a, b) {
      // High priority first
      if (a.priority != b.priority) {
        return b.priority.compareTo(a.priority);
      }
      // Then by creation time (oldest first)
      return a.createdAt.compareTo(b.createdAt);
    });
    return items;
  }

  /// Get items that should be retried (not synced yet and within retry limit)
  List<SyncQueueItem> getRetryableItems() {
    return getPendingItems().where((item) => item.shouldRetry()).toList();
  }

  /// Get items for a specific entity type
  List<SyncQueueItem> getItemsByEntityType(String entityType) {
    final items =
        _syncBox.values.where((item) => item.entityType == entityType).toList();
    items.sort((a, b) => b.priority.compareTo(a.priority));
    return items;
  }

  /// Update an item (after sync attempt)
  Future<void> updateItem(SyncQueueItem item) async {
    await item.save();
    print('[SyncQueue] Updated: ${item.id}');
  }

  /// Remove a successfully synced item
  Future<void> removeItem(SyncQueueItem item) async {
    await item.delete();
    print('[SyncQueue] Removed: ${item.id}');
  }

  /// Clear all synced items
  Future<int> clearSyncedItems() async {
    int count = 0;
    final keys = _syncBox.keys.toList();
    for (final key in keys) {
      final item = _syncBox.get(key);
      if (item != null && item.syncedAt != null) {
        await _syncBox.delete(key);
        count++;
      }
    }
    print('[SyncQueue] Cleared $count synced items');
    return count;
  }

  /// Get sync statistics
  SyncStats getStats() {
    final items = _syncBox.values.toList();
    return SyncStats(
      totalPending: items.length,
      highPriority: items.where((i) => i.priority == 2).length,
      normalPriority: items.where((i) => i.priority == 1).length,
      lowPriority: items.where((i) => i.priority == 0).length,
      lastSyncTime: items.isNotEmpty
          ? items.map((i) => i.syncedAt).whereType<DateTime>().lastOrNull
          : null,
      failedCount: items.where((i) => i.error != null).length,
    );
  }

  /// Total count of pending items
  int get count => _syncBox.length;

  /// Is queue empty
  bool get isEmpty => _syncBox.isEmpty;

  /// Clear entire queue (use with caution!)
  Future<void> clearAll() async {
    await _syncBox.clear();
    print('[SyncQueue] Cleared all items');
  }

  /// Close the box
  Future<void> close() async {
    await _syncBox.close();
    _initialized = false;
  }
}
