import 'package:flutter/material.dart';

class NotificationController extends ChangeNotifier {
  final List<NotificationModel> _notifications = [
    NotificationModel(
      id: 'n1',
      type: NotificationType.watering,
      title: 'Watering Reminder',
      message: 'Golden Pothos needs watering',
      plantName: 'Golden Pothos',
      location: 'Central Park - Manhattan, NY',
      latitude: 40.7829,
      longitude: -73.9654,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      isRead: false,
    ),
    NotificationModel(
      id: 'n2',
      type: NotificationType.health,
      title: 'Health Check Required',
      message: 'Fiddle Leaf Fig showing yellow leaves',
      plantName: 'Fiddle Leaf Fig',
      location: 'Tower Bridge - London, UK',
      latitude: 51.5055,
      longitude: -0.0754,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
    ),
    NotificationModel(
      id: 'n3',
      type: NotificationType.fertilizer,
      title: 'Fertilizer Due',
      message: 'Mango Tree scheduled for fertilization',
      plantName: 'Mango Tree',
      location: 'Shibuya Crossing - Tokyo, Japan',
      latitude: 35.6595,
      longitude: 139.7004,
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      isRead: false,
    ),
    NotificationModel(
      id: 'n4',
      type: NotificationType.pest,
      title: 'Pest Alert',
      message: 'Possible aphid infestation detected on Rose Garden',
      plantName: 'Rose Garden',
      location: 'Sydney Opera House - Australia',
      latitude: -33.8568,
      longitude: 151.2153,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isRead: false,
    ),
    NotificationModel(
      id: 'n5',
      type: NotificationType.pruning,
      title: 'Pruning Needed',
      message: 'Neem Tree requires pruning for optimal growth',
      plantName: 'Neem Tree',
      location: 'Eiffel Tower - Paris, France',
      latitude: 48.8584,
      longitude: 2.2945,
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
    ),
    NotificationModel(
      id: 'n6',
      type: NotificationType.repotting,
      title: 'Repotting Required',
      message: 'Monstera Deliciosa has outgrown its pot',
      plantName: 'Monstera Deliciosa',
      location: 'Marina Bay - Singapore',
      latitude: 1.2864,
      longitude: 103.8547,
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      isRead: false,
    ),
    NotificationModel(
      id: 'n7',
      type: NotificationType.success,
      title: 'Growth Milestone',
      message: 'Peace Lily has grown 2 inches this month!',
      plantName: 'Peace Lily',
      location: 'Burj Khalifa - Dubai, UAE',
      latitude: 25.1972,
      longitude: 55.2744,
      timestamp: DateTime.now().subtract(const Duration(days: 4)),
      isRead: true,
    ),
    NotificationModel(
      id: 'n8',
      type: NotificationType.disease,
      title: 'Disease Detection',
      message: 'Potential fungal infection on Tomato Plant leaves',
      plantName: 'Tomato Plant',
      location: 'Christ the Redeemer - Rio, Brazil',
      latitude: -22.9519,
      longitude: -43.2105,
      timestamp: DateTime.now().subtract(const Duration(days: 5)),
      isRead: false,
    ),
  ];

  List<NotificationModel> get notifications => _notifications;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void markAllAsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
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
