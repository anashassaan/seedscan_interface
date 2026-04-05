import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ChangeNotifier;
import '../../services/push_notification_service.dart';
import '../../services/database_service.dart';

class NotificationController extends ChangeNotifier {
  final List<NotificationModel> _notifications = [];
  final DatabaseService _db = DatabaseService();
  bool _loading = false;
  String? _currentUserId;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get loading => _loading;

  // ── Initialize: load from Appwrite + subscribe to realtime ────────────────
  Future<void> initialize(String userId) async {
    if (_currentUserId == userId) return; // already initialized for this user

    // User switched: clear old in-memory data and detach previous subscription.
    await PushNotificationService().unsubscribe();
    _notifications.clear();
    notifyListeners();

    _currentUserId = userId;

    // Initialize local notifications
    await PushNotificationService().initLocalNotifications();

    // Load existing notifications from Appwrite
    await _loadFromAppwrite(userId);

    // Subscribe to real-time new notifications
    await PushNotificationService().subscribe(
      userId: userId,
      onNotification: (data) {
        final existing =
            _notifications.any((n) => n.id == (data['\$id'] ?? ''));
        if (!existing) {
          final model = _fromAppwriteData(data);
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

  Future<void> _loadFromAppwrite(String userId) async {
    _loading = true;
    notifyListeners();
    try {
      final list = await _db.listNotifications(userId);
      _notifications.clear();
      _notifications.addAll(list.map(_fromAppwriteNotificationModel).toList());
    } catch (e) {
      debugPrint('[NotificationController] _loadFromAppwrite error: $e');
    } finally {
      _loading = false;
      notifyListeners();
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
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
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
