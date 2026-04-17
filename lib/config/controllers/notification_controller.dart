import 'package:flutter/foundation.dart';
import '../../services/push_notification_service.dart';
import '../../services/database_service.dart';
import '../../services/garden_cache_service.dart';

class NotificationController extends ChangeNotifier {
  final List<NotificationModel> _notifications = [];
  final DatabaseService _db = DatabaseService();
  bool _loading = false;
  String? _currentUserId;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get loading => _loading;

  // ── Initialize: load from cache + subscribe to realtime ────────────────
  /// CACHE-FIRST: Returns immediately after loading from cache.
  /// Appwrite sync and realtime subscribe happen in true background.
  Future<void> initialize(String userId) async {
    if (_currentUserId == userId) return; // already initialized for this user

    // User switched: clear old in-memory data and detach previous subscription.
    await PushNotificationService().unsubscribe();
    _notifications.clear();
    notifyListeners();

    _currentUserId = userId;

    // Initialize local notifications
    await PushNotificationService().initLocalNotifications();

    // STEP 1: LOAD FROM CACHE (instant — caller unblocked immediately after this)
    _loadFromCache(userId);

    // STEP 2: SYNC FROM APPWRITE (truly background — does NOT block caller)
    // ignore: unawaited_futures
    _syncFromAppwrite(userId);

    // STEP 3: Subscribe to real-time new notifications (fire-and-forget)
    // ignore: unawaited_futures
    PushNotificationService().subscribe(
      userId: userId,
      onNotification: (data) {
        final existing =
            _notifications.any((n) => n.id == (data['\$id'] ?? ''));
        if (!existing) {
          final model = _fromAppwriteData(data);

          // Deduplication: If this is a watering notification and we already have an
          // unread one for the same plant, skip it.
          if (model.type == NotificationType.watering &&
              model.linkedPlantId != null) {
            final duplicate = _notifications.any((n) =>
                n.type == NotificationType.watering &&
                n.linkedPlantId == model.linkedPlantId &&
                !n.isRead);
            if (duplicate) return;
          }

          _notifications.insert(0, model);
          notifyListeners();
        }
      },
    );
  }

  /// Detach realtime listener on logout
  Future<void> dispose2() async {
    await PushNotificationService().unsubscribe();
    _currentUserId = null;
    _notifications.clear();
    notifyListeners();
  }

  /// Load notifications from Hive cache instantly
  void _loadFromCache(String userId) {
    _loading = true;
    notifyListeners();
    try {
      final cached = GardenCacheService.getCachedNotifications(userId);
      if (cached != null && cached.isNotEmpty) {
        _notifications.clear();
        _notifications.addAll(cached.map((data) => _fromAppwriteData(data)));
        debugPrint(
            '[NotificationController] Loaded ${_notifications.length} notifications from cache');
      }
    } catch (e) {
      debugPrint('[NotificationController] _loadFromCache error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Sync notifications from Appwrite in background
  Future<void> _syncFromAppwrite(String userId) async {
    try {
      final list = await _db.listNotifications(userId);
      _notifications.clear();
      _notifications.addAll(list.map(_fromAppwriteNotificationModel).toList());
      debugPrint(
          '[NotificationController] Synced ${_notifications.length} notifications from Appwrite');

      // Cache the fetched data
      final notificationsList = _notifications
          .map((n) => {
                'id': n.id,
                'type': _typeToString(n.type),
                'title': n.title,
                'body': n.message,
                'plant_name': n.plantName,
                'plant_location': '${n.location}|${n.latitude},${n.longitude}',
                'created_at': n.timestamp.toIso8601String(),
                'is_read': n.isRead,
                'linked_community_id': n.linkedCommunityId,
                'linked_plant_id': n.linkedPlantId,
              })
          .toList();
      await GardenCacheService.cacheNotifications(userId, notificationsList);
    } catch (e) {
      debugPrint(
          '[NotificationController] Appwrite sync failed (using cached data): $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  String _typeToString(NotificationType type) {
    switch (type) {
      case NotificationType.watering:
        return 'watering';
      case NotificationType.disease:
        return 'disease';
      case NotificationType.health:
        return 'health';
      case NotificationType.fertilizer:
        return 'fertilizer';
      case NotificationType.pest:
        return 'pest';
      case NotificationType.pruning:
        return 'pruning';
      case NotificationType.repotting:
        return 'repotting';
      case NotificationType.success:
        return 'success';
      case NotificationType.reminder:
        return 'reminder';
    }
  }

  // ── Public API (used by view) ─────────────────────────────────────────────
  void markAllAsRead() {
    for (var n in _notifications) {
      if (!n.isRead) {
        n.isRead = true;
        _markReadOnServer(n.id);
      }
    }
    notifyListeners();
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index].isRead = true;
      notifyListeners();
      _markReadOnServer(id);
    }
  }

  void removeNotification(String id) {
    // Remove from in-memory list immediately for a snappy UI.
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();

    // Bug-2 fix: permanently delete from Appwrite so it never comes back
    // after logout / re-login.
    _db.deleteNotification(id).catchError((e) {
      debugPrint(
          '[NotificationController] deleteNotification error for $id: $e');
    });
  }

  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  void _markReadOnServer(String id) {
    _db.markNotificationRead(id).catchError(
        (e) => debugPrint('[NotificationController] markRead error: $e'));
  }

  NotificationType _typeFromString(String? type) {
    switch (type) {
      case 'watering':
        return NotificationType.watering;
      case 'disease':
        return NotificationType.disease;
      case 'health':
        return NotificationType.health;
      case 'fertilizer':
        return NotificationType.fertilizer;
      case 'pest':
        return NotificationType.pest;
      case 'pruning':
        return NotificationType.pruning;
      case 'repotting':
        return NotificationType.repotting;
      case 'success':
        return NotificationType.success;
      default:
        return NotificationType.reminder;
    }
  }

  NotificationModel _fromAppwriteNotificationModel(dynamic m) {
    String rawLocation = m.plantLocation ?? '';
    String parsedLocation = rawLocation;
    double parsedLat = 0.0;
    double parsedLng = 0.0;

    if (rawLocation.contains('|')) {
      final parts = rawLocation.split('|');
      parsedLocation = parts[0];
      if (parts.length > 1 && parts[1].contains(',')) {
        final coords = parts[1].split(',');
        parsedLat = double.tryParse(coords[0]) ?? 0.0;
        parsedLng = double.tryParse(coords[1]) ?? 0.0;
      }
    }

    // m is a NotificationModel from models/notification_model.dart
    return NotificationModel(
      id: m.id,
      type: _typeFromString(m.type),
      title: m.title,
      message: m.body,
      plantName: m.plantName ?? 'SeedScan',
      location: parsedLocation,
      latitude: parsedLat,
      longitude: parsedLng,
      timestamp: m.createdAt,
      isRead: m.isRead,
      linkedCommunityId: m.linkedCommunityId,
      linkedPlantId: m.linkedPlantId,
    );
  }

  NotificationModel _fromAppwriteData(Map<String, dynamic> data) {
    String rawLocation = data['plant_location'] ?? '';
    String parsedLocation = rawLocation;
    double parsedLat = 0.0;
    double parsedLng = 0.0;

    if (rawLocation.contains('|')) {
      final parts = rawLocation.split('|');
      parsedLocation = parts[0];
      if (parts.length > 1 && parts[1].contains(',')) {
        final coords = parts[1].split(',');
        parsedLat = double.tryParse(coords[0]) ?? 0.0;
        parsedLng = double.tryParse(coords[1]) ?? 0.0;
      }
    }

    return NotificationModel(
      id: data['\$id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: _typeFromString(data['type']),
      title: data['title'] ?? 'SeedScan',
      message: data['body'] ?? '',
      plantName: data['plant_name'] ?? 'SeedScan',
      location: parsedLocation,
      latitude: parsedLat,
      longitude: parsedLng,
      timestamp: data['created_at'] != null
          ? DateTime.tryParse(data['created_at']) ?? DateTime.now()
          : DateTime.now(),
      isRead: data['is_read'] ?? false,
      linkedCommunityId: data['linked_community_id'],
      linkedPlantId: data['linked_plant_id'],
    );
  }
}

// Notification Model
class NotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final String plantName;
  final String location;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  bool isRead;
  final String? linkedCommunityId;
  final String? linkedPlantId;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.plantName,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.isRead = false,
    this.linkedCommunityId,
    this.linkedPlantId,
  });
}

// Notification Types
enum NotificationType {
  watering,
  health,
  fertilizer,
  pest,
  disease,
  pruning,
  repotting,
  success,
  reminder,
}
