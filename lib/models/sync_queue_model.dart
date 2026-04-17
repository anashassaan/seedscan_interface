import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

/// Enum for operation types in the sync queue
enum SyncOperationType {
  create,
  update,
  delete,
  read,
}

/// Represents a pending operation to be synced with Appwrite
@HiveType(typeId: 20)
class SyncQueueItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String entityType; // e.g., "chat_message", "plant_scan", "user_profile"

  @HiveField(2)
  SyncOperationType operationType;

  @HiveField(3)
  Map<String, dynamic> data;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime? syncedAt;

  @HiveField(6)
  int retryCount;

  @HiveField(7)
  String? error;

  @HiveField(8)
  int priority; // 0=low, 1=normal, 2=high

  @HiveField(9)
  String? entityId; // ID of the entity being synced (for updates/deletes)

  @HiveField(10)
  Map<String, dynamic>?
      metadata; // Additional context (e.g., userId, conversationId)

  SyncQueueItem({
    String? id,
    required this.entityType,
    required this.operationType,
    required this.data,
    DateTime? createdAt,
    this.syncedAt,
    this.retryCount = 0,
    this.error,
    this.priority = 1,
    this.entityId,
    this.metadata,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// Marks this item as successfully synced
  void markSynced() {
    syncedAt = DateTime.now();
    error = null;
  }

  /// Increments retry count and sets error
  void markFailed(String errorMessage) {
    retryCount++;
    error = errorMessage;
  }

  /// Returns true if this item should be retried (max 3 attempts)
  bool shouldRetry() => retryCount < 3;

  /// Age of this item in seconds
  int get ageInSeconds => DateTime.now().difference(createdAt).inSeconds;

  /// Human-readable operation type
  String get operationLabel =>
      operationType.toString().split('.').last.toUpperCase();

  @override
  String toString() =>
      'SyncQueueItem(id: $id, type: $entityType, op: $operationLabel, retries: $retryCount)';
}

/// Container for sync statistics
class SyncStats {
  final int totalPending;
  final int highPriority;
  final int normalPriority;
  final int lowPriority;
  final DateTime? lastSyncTime;
  final int failedCount;

  SyncStats({
    required this.totalPending,
    this.highPriority = 0,
    this.normalPriority = 0,
    this.lowPriority = 0,
    this.lastSyncTime,
    this.failedCount = 0,
  });

  bool get hasPendingItems => totalPending > 0;

  @override
  String toString() =>
      'SyncStats(pending: $totalPending, high: $highPriority, failed: $failedCount)';
}
