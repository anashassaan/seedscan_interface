import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sync_queue_model.dart';
import '../services/sync_manager.dart';

/// Provider for reactive sync status updates
class SyncStatusNotifier extends ChangeNotifier {
  final SyncManager _syncManager;

  SyncStatus _status = SyncStatus(
    isOnline: true,
    isSyncing: false,
    message: 'Ready',
  );

  SyncStatusNotifier(this._syncManager) {
    _initializeStream();
  }

  SyncStatus get status => _status;
  bool get isOnline => _status.isOnline;
  bool get isSyncing => _status.isSyncing;
  String get message => _status.message;

  void _initializeStream() {
    _syncManager.syncStatusStream.listen((newStatus) {
      _status = newStatus;
      notifyListeners();
    });
  }

  /// Manually trigger sync
  Future<void> triggerSync() => _syncManager.performSync();

  /// Get current sync statistics
  SyncStats getSyncStats() => _syncManager.getSyncStats();
}

/// Provider for reactive sync queue updates
class SyncQueueNotifier extends ChangeNotifier {
  final SyncManager _syncManager;
  int _pendingCount = 0;

  SyncQueueNotifier(this._syncManager) {
    _updateStats();
  }

  int get pendingCount => _pendingCount;
  bool get hasPending => _pendingCount > 0;

  void _updateStats() {
    final stats = _syncManager.getSyncStats();
    _pendingCount = stats.totalPending;
    notifyListeners();
  }

  /// Refresh queue stats
  void refresh() {
    _updateStats();
  }
}

/// Widget to display sync status in AppBar
class SyncStatusIndicator extends StatelessWidget {
  final double size;

  const SyncStatusIndicator({
    Key? key,
    this.size = 24,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncStatusNotifier>(
      builder: (context, syncStatus, child) {
        Color color;
        IconData icon;

        if (!syncStatus.isOnline) {
          color = Colors.grey;
          icon = Icons.cloud_off;
        } else if (syncStatus.isSyncing) {
          color = Colors.blue;
          icon = Icons.cloud_download;
        } else {
          color = Colors.green;
          icon = Icons.cloud_done;
        }

        return Tooltip(
          message: syncStatus.message,
          child: Icon(
            icon,
            color: color,
            size: size,
          ),
        );
      },
    );
  }
}

/// Widget to show pending sync badge
class SyncQueueBadge extends StatelessWidget {
  const SyncQueueBadge({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncQueueNotifier>(
      builder: (context, syncQueue, child) {
        if (!syncQueue.hasPending) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${syncQueue.pendingCount} pending',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}

/// Dialog to show sync queue details
class SyncQueueDialog extends StatelessWidget {
  const SyncQueueDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncStatusNotifier>(
      builder: (context, syncStatus, child) {
        final stats = syncStatus.getSyncStats();

        return AlertDialog(
          title: const Text('Sync Queue Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Pending: ${stats.totalPending}'),
              Text('  High Priority: ${stats.highPriority}'),
              Text('  Normal Priority: ${stats.normalPriority}'),
              Text('  Low Priority: ${stats.lowPriority}'),
              const SizedBox(height: 8),
              Text('Failed Items: ${stats.failedCount}'),
              if (stats.lastSyncTime != null)
                Text(
                    'Last Synced: ${stats.lastSyncTime.toString().split('.')[0]}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () async {
                await syncStatus.triggerSync();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Sync Now'),
            ),
          ],
        );
      },
    );
  }
}
